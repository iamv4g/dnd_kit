import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:universal_web/web.dart' as web;

import '../scope/controller.dart';
import '../scope/scope.dart';

const DndSensorActivationConstraint _kDefaultTouchActivationConstraint =
    DndSensorActivationConstraint(
  delay: Duration(milliseconds: 500),
  tolerance: 18,
);

/// A drag source for the Jaspr adapter.
///
/// `DndDraggable` registers a stable [id] with the enclosing [DndScope]'s
/// controller, measures its DOM element on activation, and drives the shared
/// [DndPointerSensor] from browser pointer events. It uses pointer capture and
/// element-level pointer events (wired through Jaspr's `events:` map), so it
/// needs no document-level listeners and stays safe to import in any Jaspr
/// render mode — all DOM access is guarded by `kIsWeb`.
///
/// During an active drag the element follows the pointer via a CSS transform.
/// A dedicated drag overlay arrives in a later story.
class DndDraggable extends StatefulComponent {
  /// Creates a draggable wrapping [child].
  const DndDraggable({
    required this.id,
    required this.child,
    this.data,
    this.disabled = false,
    this.constraint = DndSensorActivationConstraint.none,
    this.keyboardDragStep = 25,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
    super.key,
  }) : assert(keyboardDragStep > 0, 'Keyboard drag step must be positive.');

  /// The stable draggable id registered with the controller.
  final DndId id;

  /// The visual content of the draggable.
  final Component child;

  /// Optional application-owned data associated with the draggable.
  final Object? data;

  /// Whether dragging is disabled.
  final bool disabled;

  /// The activation constraint applied before a drag session starts.
  final DndSensorActivationConstraint constraint;

  /// Logical pixels moved for each keyboard arrow key press.
  final double keyboardDragStep;

  /// Called when a drag session starts.
  final DndDragStartCallback? onDragStart;

  /// Called when the active drag moves.
  final DndDragMoveCallback? onDragMove;

  /// Called when the active drag ends.
  final DndDragEndCallback? onDragEnd;

  /// Called when a pending or active drag is cancelled.
  final DndDragCancelCallback? onDragCancel;

  @override
  State<DndDraggable> createState() => _DndDraggableState();
}

class _DndDraggableState extends State<DndDraggable> implements DndDraggableHandleController {
  final GlobalNodeKey<web.HTMLElement> _nodeKey = GlobalNodeKey<web.HTMLElement>();

  DndController? _controller;
  DndDraggableRegistration? _registration;
  DndPointerSensor? _sensor;
  int _handleCount = 0;
  bool _handlePointerActive = false;
  bool _handleSyncScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DndScope.of(context);
    if (!identical(_controller, controller)) {
      _unregister();
      _controller = controller;
      _register();
    }
  }

  @override
  void didUpdateComponent(DndDraggable oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.id != component.id ||
        oldComponent.disabled != component.disabled ||
        oldComponent.data != component.data) {
      _unregister();
      _register();
    }
  }

  @override
  void dispose() {
    _sensor?.dispose();
    _unregister();
    super.dispose();
  }

  void _register() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final registration = DndDraggableRegistration(
      id: component.id,
      disabled: component.disabled,
      data: component.data,
    );
    _registration = registration;
    controller.registry.registerDraggable(registration, owner: this);
  }

  void _unregister() {
    final controller = _controller;
    final registration = _registration;
    if (controller != null && registration != null) {
      controller.registry.unregisterDraggable(registration.id, owner: this);
    }
    _registration = null;
  }

  DndRect? _measure() {
    if (!kIsWeb) {
      return null;
    }

    final node = _nodeKey.currentNode;
    if (node == null) {
      return null;
    }
    final rect = node.getBoundingClientRect();
    return DndRect(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    );
  }

  void _handlePointerDown(web.Event event) {
    if (component.disabled || !kIsWeb) {
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.isIdle) {
      return;
    }
    final pointer = event as web.PointerEvent;
    final startedFromHandle = _handlePointerActive;
    if (_handleCount > 0 && !startedFromHandle) {
      return;
    }

    try {
      _nodeKey.currentNode?.setPointerCapture(pointer.pointerId);
    } catch (_) {
      // Synthetic browser-test pointer events do not participate in the real
      // pointer-capture lifecycle; ignore capture failures and keep the drag
      // session logic testable.
    }
    final inputKind = _inputKindFor(pointer);

    final sensor = DndPointerSensor(
      runtime: controller.runtime,
      activeRect: _measure(),
      constraint: _effectivePointerConstraint(inputKind),
      onDragStart: component.onDragStart,
      onDragMove: (moveEvent) {
        _applyTransform(moveEvent.transform);
        component.onDragMove?.call(moveEvent);
      },
      onDragEnd: (endEvent) {
        _endGesture();
        component.onDragEnd?.call(endEvent);
      },
      onDragCancel: (cancelEvent) {
        _endGesture();
        component.onDragCancel?.call(cancelEvent);
      },
    );
    _sensor = sensor;
    sensor.start(
      DndSensorActivationEvent(
        activeId: component.id,
        position: DndPoint(pointer.clientX.toDouble(), pointer.clientY.toDouble()),
        inputKind: inputKind,
      ),
    );
  }

  void _handlePointerMove(web.Event event) {
    final pointer = event as web.PointerEvent;
    _sensor?.move(DndPoint(pointer.clientX.toDouble(), pointer.clientY.toDouble()));
  }

  void _handlePointerUp(web.Event event) {
    _sensor?.end();
    _handlePointerActive = false;
  }

  void _handlePointerCancel(web.Event event) {
    _sensor?.cancel();
    _handlePointerActive = false;
  }

  void _endGesture() {
    _applyTransform(DndTransform.identity);
    _sensor?.dispose();
    _sensor = null;
    _handlePointerActive = false;
  }

  void _applyTransform(DndTransform transform) {
    final node = _nodeKey.currentNode;
    if (node == null) {
      return;
    }
    node.style.transform =
        transform.isIdentity ? '' : 'translate(${transform.offset.x}px, ${transform.offset.y}px)';
  }

  DndInputKind _inputKindFor(web.PointerEvent event) {
    return switch (event.pointerType) {
      'mouse' => DndInputKind.mouse,
      'touch' || 'pen' => DndInputKind.touch,
      _ => DndInputKind.pointer,
    };
  }

  DndSensorActivationConstraint _effectivePointerConstraint(DndInputKind inputKind) {
    if (component.constraint != DndSensorActivationConstraint.none) {
      return component.constraint;
    }

    return switch (inputKind) {
      DndInputKind.touch => _kDefaultTouchActivationConstraint,
      _ => DndSensorActivationConstraint.none,
    };
  }

  bool get _isKeyboardDrag {
    final state = _controller?.state;
    return state is DndDragging &&
        state.session.activeId == component.id &&
        state.session.inputKind == DndInputKind.keyboard;
  }

  @override
  bool handleKeyboardEvent(web.KeyboardEvent event) {
    if (component.disabled) {
      return false;
    }

    final normalizedKey = _normalizeKeyboardKey(event.key);
    if (normalizedKey == null) {
      return false;
    }

    return switch (normalizedKey) {
      _NormalizedKey.pickupOrDrop => _toggleKeyboardDrag(),
      _NormalizedKey.cancel => _cancelKeyboardDrag(),
      _NormalizedKey.left => _moveKeyboardDrag(DndPoint(-component.keyboardDragStep, 0)),
      _NormalizedKey.right => _moveKeyboardDrag(DndPoint(component.keyboardDragStep, 0)),
      _NormalizedKey.up => _moveKeyboardDrag(DndPoint(0, -component.keyboardDragStep)),
      _NormalizedKey.down => _moveKeyboardDrag(DndPoint(0, component.keyboardDragStep)),
    };
  }

  bool _toggleKeyboardDrag() {
    if (_isKeyboardDrag) {
      final event = _controller?.endDrag();
      if (event == null) {
        return false;
      }

      _applyTransform(DndTransform.identity);
      component.onDragEnd?.call(event);
      _controller?.reset();
      return true;
    }

    return _startKeyboardDrag();
  }

  bool _startKeyboardDrag() {
    final controller = _controller;
    if (controller == null || !controller.isIdle) {
      return false;
    }

    final activeRect = _measure();
    controller.beginDrag(
      DndSensorActivationEvent(
        activeId: component.id,
        position: activeRect?.center ?? DndPoint.zero,
        inputKind: DndInputKind.keyboard,
      ),
      activeRect: activeRect,
    );

    final event = controller.startDrag();
    if (event == null) {
      controller.reset();
      return false;
    }

    component.onDragStart?.call(event);
    return true;
  }

  bool _moveKeyboardDrag(DndPoint delta) {
    final session = _controller?.activeSession;
    if (!_isKeyboardDrag || session == null) {
      return false;
    }

    final event = _controller?.moveDrag(session.currentPointer.translate(delta));
    if (event == null) {
      return false;
    }

    _applyTransform(event.transform);
    component.onDragMove?.call(event);
    return true;
  }

  bool _cancelKeyboardDrag() {
    if (!_isKeyboardDrag) {
      return false;
    }

    final event = _controller?.cancelDrag(reason: DndCancelReason.user);
    if (event == null) {
      return false;
    }

    _applyTransform(DndTransform.identity);
    component.onDragCancel?.call(event);
    _controller?.reset();
    return true;
  }

  @override
  void registerHandle() {
    _handleCount += 1;
    _scheduleHandleStateSync();
  }

  @override
  void unregisterHandle() {
    if (_handleCount == 0) {
      return;
    }

    _handleCount -= 1;
    _scheduleHandleStateSync();
  }

  @override
  void markHandlePointerActive() {
    _handlePointerActive = true;
  }

  @override
  void clearHandlePointerActive() {
    _handlePointerActive = false;
  }

  void _scheduleHandleStateSync() {
    if (_handleSyncScheduled || !mounted) {
      return;
    }

    _handleSyncScheduled = true;
    Future<void>.microtask(() {
      _handleSyncScheduled = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleHostKeyDown(web.Event event) {
    if (_handleCount > 0) {
      return;
    }

    final keyboardEvent = event as web.KeyboardEvent;
    if (handleKeyboardEvent(keyboardEvent)) {
      keyboardEvent.preventDefault();
    }
  }

  @override
  Component build(BuildContext context) {
    return DndDraggableHandleScope(
      draggable: this,
      child: div(
        key: _nodeKey,
        attributes: <String, String>{
          if (!component.disabled && _handleCount == 0) 'tabindex': '0',
          'role': 'button',
          'aria-disabled': component.disabled ? 'true' : 'false',
          'aria-roledescription': 'draggable',
        },
        events: component.disabled
            ? null
            : <String, EventCallback>{
                'pointerdown': _handlePointerDown,
                'pointermove': _handlePointerMove,
                'pointerup': _handlePointerUp,
                'pointercancel': _handlePointerCancel,
                if (_handleCount == 0) 'keydown': _handleHostKeyDown,
              },
        [component.child],
      ),
    );
  }
}

class DndDraggableHandleScope extends InheritedComponent {
  const DndDraggableHandleScope({
    required this.draggable,
    required super.child,
  });

  final DndDraggableHandleController draggable;

  static DndDraggableHandleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedComponentOfExactType<DndDraggableHandleScope>();
  }

  @override
  bool updateShouldNotify(DndDraggableHandleScope oldComponent) {
    return draggable != oldComponent.draggable;
  }
}

abstract interface class DndDraggableHandleController {
  void registerHandle();

  void unregisterHandle();

  void markHandlePointerActive();

  void clearHandlePointerActive();

  bool handleKeyboardEvent(web.KeyboardEvent event);
}

enum _NormalizedKey {
  pickupOrDrop,
  cancel,
  left,
  right,
  up,
  down,
}

_NormalizedKey? _normalizeKeyboardKey(String key) {
  return switch (key) {
    ' ' || 'Space' || 'Spacebar' || 'Enter' => _NormalizedKey.pickupOrDrop,
    'Escape' || 'Esc' => _NormalizedKey.cancel,
    'ArrowLeft' => _NormalizedKey.left,
    'ArrowRight' => _NormalizedKey.right,
    'ArrowUp' => _NormalizedKey.up,
    'ArrowDown' => _NormalizedKey.down,
    _ => null,
  };
}
