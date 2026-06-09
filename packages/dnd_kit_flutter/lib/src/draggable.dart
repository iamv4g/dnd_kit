import 'dart:async' show unawaited;

import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'controller.dart';
import 'long_press_activation.dart';
import 'measuring.dart';
import 'pointer_sensor.dart';
import 'scope.dart';

/// Registers a child as draggable and wires basic pointer gestures to a scope.
class DndDraggable extends StatefulWidget {
  /// Creates a draggable widget.
  const DndDraggable({
    super.key,
    required this.id,
    required this.child,
    this.disabled = false,
    this.data,
    this.activationConstraint = DndSensorActivationConstraint.none,
    this.longPressActivation,
    this.keyboardDragStep = 25,
    this.hitTestBehavior,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  })  : assert(
          longPressActivation == null || activationConstraint == DndSensorActivationConstraint.none,
          'Use either activationConstraint or longPressActivation, not both.',
        ),
        assert(keyboardDragStep > 0, 'Keyboard drag step must be positive.');

  /// The stable draggable id.
  final DndId id;

  /// The widget users can drag.
  final Widget child;

  /// Whether drag gestures should be ignored for this draggable.
  final bool disabled;

  /// Optional application-owned metadata stored in the controller registry.
  final Object? data;

  /// The pointer activation constraint required before a drag starts.
  final DndSensorActivationConstraint activationConstraint;

  /// Optional long-press activation behavior for pointer drags.
  final DndLongPressActivation? longPressActivation;

  /// Logical pixels moved for each keyboard arrow key press.
  final double keyboardDragStep;

  /// How this draggable participates in hit testing.
  final HitTestBehavior? hitTestBehavior;

  /// Callback for a started drag session.
  final DndDragStartCallback? onDragStart;

  /// Callback for active drag movement.
  final DndDragMoveCallback? onDragMove;

  /// Callback for a completed drag.
  final DndDragEndCallback? onDragEnd;

  /// Callback for a cancelled drag.
  final DndDragCancelCallback? onDragCancel;

  @override
  State<DndDraggable> createState() => _DndDraggableState();
}

class _DndDraggableState extends State<DndDraggable> implements DndDraggableHandleController {
  final GlobalKey _measureKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'DndDraggable');
  DndController? _controller;
  DndController? _registeredController;
  DndDraggableRegistration? _registration;
  DndPointerSensor? _pointerSensor;
  bool _disabledCancelScheduled = false;
  bool _handlePointerActive = false;
  int _handleCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DndScope.of(context);
    _syncRegistration();
  }

  @override
  void didUpdateWidget(DndDraggable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRegistration();

    if (!oldWidget.disabled && widget.disabled && (_isWidgetGestureDrag || _isKeyboardDrag)) {
      _scheduleDisabledCancel();
    }
  }

  @override
  void dispose() {
    _pointerSensor?.dispose();
    _unregister();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isWidgetGestureDrag {
    return _pointerSensor?.isActive == true && _controller?.activeId == widget.id;
  }

  bool get _isKeyboardDrag {
    final state = _controller?.state;
    return state is DndDragging &&
        state.session.activeId == widget.id &&
        state.session.inputKind == DndInputKind.keyboard;
  }

  bool get _usesLongPressActivation => widget.longPressActivation != null;

  DndDraggableRegistration get _currentRegistration {
    return DndDraggableRegistration(
      id: widget.id,
      disabled: widget.disabled,
      data: widget.data,
    );
  }

  void _syncRegistration() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final next = _currentRegistration;
    if (_registeredController != controller || _registration?.id != next.id) {
      _unregister();
      controller.registry.registerDraggable(next);
      _registeredController = controller;
      _registration = next;
      return;
    }

    if (_registration != next) {
      controller.registry.updateDraggable(next);
      _registration = next;
    }
  }

  void _unregister() {
    final controller = _registeredController;
    final registration = _registration;
    if (controller != null && registration != null) {
      controller.registry.unregisterDraggable(registration.id);
      controller.measuring.removeDraggableRect(registration.id);
    }

    _registeredController = null;
    _registration = null;
  }

  @internal
  @override
  void registerHandle() {
    _handleCount += 1;
  }

  @internal
  @override
  void unregisterHandle() {
    assert(_handleCount > 0, 'Cannot unregister a drag handle before registration.');
    if (_handleCount == 0) {
      return;
    }

    _handleCount -= 1;
  }

  @internal
  @override
  void markHandlePointerActive() {
    _handlePointerActive = true;
  }

  @internal
  @override
  void clearHandlePointerActive() {
    _handlePointerActive = false;
  }

  void _handlePanStart(DragStartDetails details, {required bool fromHandle}) {
    if (_usesLongPressActivation) {
      return;
    }

    _startPointerSensor(
      _pointFromOffset(details.globalPosition),
      inputKind: _inputKindFromPointerKind(details.kind),
      fromHandle: fromHandle,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _startPointerSensor(
      _pointFromOffset(event.position),
      inputKind: _inputKindFromPointerKind(event.kind),
      fromHandle: false,
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _pointerSensor?.move(_pointFromOffset(event.position));
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _pointerSensor?.end();
    _pointerSensor = null;
    _handlePointerActive = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_usesLongPressActivation) {
      return;
    }

    _cancelDrag(reason: DndCancelReason.sensor);
  }

  void _startPointerSensor(
    DndPoint initialPointer, {
    required DndInputKind inputKind,
    required bool fromHandle,
  }) {
    final startedFromHandle = fromHandle || _handlePointerActive;
    if (_handleCount > 0 && !startedFromHandle) {
      return;
    }

    if (widget.disabled) {
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.isIdle) {
      assert(false, 'Cannot start a draggable while another drag is active.');
      return;
    }

    final activeRect =
        _measureKey.currentContext == null ? null : measureDndRect(_measureKey.currentContext!);
    if (activeRect != null) {
      controller.measuring.updateDraggableRect(widget.id, activeRect);
    }

    final sensor = DndPointerSensor(
      controller: controller,
      activeRect: activeRect,
      constraint: _effectiveActivationConstraint,
      onDragStart: _handleDragStart,
      onDragMove: widget.onDragMove,
      onDragEnd: widget.onDragEnd,
      onDragCancel: widget.onDragCancel,
    );
    _pointerSensor = sensor;
    sensor.start(
      DndSensorActivationEvent(
        activeId: widget.id,
        position: initialPointer,
        inputKind: inputKind,
      ),
    );
  }

  DndInputKind _inputKindFromPointerKind(PointerDeviceKind? kind) {
    return switch (kind) {
      PointerDeviceKind.mouse => DndInputKind.mouse,
      PointerDeviceKind.touch => DndInputKind.touch,
      _ => DndInputKind.pointer,
    };
  }

  DndSensorActivationConstraint get _effectiveActivationConstraint {
    final longPressActivation = widget.longPressActivation;
    if (longPressActivation == null) {
      return widget.activationConstraint;
    }

    return DndSensorActivationConstraint(
      delay: longPressActivation.delay,
      tolerance: longPressActivation.tolerance,
    );
  }

  void _handleDragStart(DndDragStartEvent event) {
    if (widget.longPressActivation?.hapticFeedback == true) {
      unawaited(HapticFeedback.selectionClick());
    }

    widget.onDragStart?.call(event);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final currentPointer = _pointFromOffset(details.globalPosition);
    _pointerSensor?.move(currentPointer);
  }

  void _handlePanEnd(DragEndDetails details) {
    _pointerSensor?.end();
    _pointerSensor = null;
    _handlePointerActive = false;
  }

  void _handlePanCancel() {
    if (!_isWidgetGestureDrag) {
      return;
    }

    _cancelDrag(reason: DndCancelReason.sensor);
    _handlePointerActive = false;
  }

  void _cancelDrag({required DndCancelReason reason}) {
    _pointerSensor?.cancel(reason: reason);
    _pointerSensor = null;
    _handlePointerActive = false;

    if (_isKeyboardDrag) {
      final event = _controller?.cancelDrag(reason: reason);
      if (event != null) {
        widget.onDragCancel?.call(event);
        _controller?.reset();
      }
    }
  }

  void _scheduleDisabledCancel() {
    if (_disabledCancelScheduled) {
      return;
    }

    _disabledCancelScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disabledCancelScheduled = false;
      if (!mounted || !widget.disabled || (!_isWidgetGestureDrag && !_isKeyboardDrag)) {
        return;
      }

      _cancelDrag(reason: DndCancelReason.disabled);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (widget.disabled) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      return _toggleKeyboardDrag();
    }

    if (key == LogicalKeyboardKey.escape) {
      return _cancelKeyboardDrag();
    }

    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => DndPoint(-widget.keyboardDragStep, 0),
      LogicalKeyboardKey.arrowRight => DndPoint(widget.keyboardDragStep, 0),
      LogicalKeyboardKey.arrowUp => DndPoint(0, -widget.keyboardDragStep),
      LogicalKeyboardKey.arrowDown => DndPoint(0, widget.keyboardDragStep),
      _ => null,
    };

    if (delta == null) {
      return KeyEventResult.ignored;
    }

    return _moveKeyboardDrag(delta);
  }

  KeyEventResult _toggleKeyboardDrag() {
    if (_isKeyboardDrag) {
      final event = _controller?.endDrag();
      if (event != null) {
        widget.onDragEnd?.call(event);
        _controller?.reset();
      }
      return KeyEventResult.handled;
    }

    if (_startKeyboardDrag()) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _startKeyboardDrag() {
    final controller = _controller;
    if (controller == null || !controller.isIdle) {
      return false;
    }

    final activeRect =
        _measureKey.currentContext == null ? null : measureDndRect(_measureKey.currentContext!);
    if (activeRect != null) {
      controller.measuring.updateDraggableRect(widget.id, activeRect);
    }

    final initialPointer = activeRect?.center ?? DndPoint.zero;
    controller.beginDrag(
      DndSensorActivationEvent(
        activeId: widget.id,
        position: initialPointer,
        inputKind: DndInputKind.keyboard,
      ),
      activeRect: activeRect,
    );

    final event = controller.startDrag();
    if (event == null) {
      return false;
    }

    widget.onDragStart?.call(event);
    return true;
  }

  KeyEventResult _moveKeyboardDrag(DndPoint delta) {
    final session = _controller?.activeSession;
    if (!_isKeyboardDrag || session == null) {
      return KeyEventResult.ignored;
    }

    final event = _controller?.moveDrag(session.currentPointer.translate(delta));
    if (event != null) {
      widget.onDragMove?.call(event);
    }

    return KeyEventResult.handled;
  }

  KeyEventResult _cancelKeyboardDrag() {
    if (!_isKeyboardDrag) {
      return KeyEventResult.ignored;
    }

    final event = _controller?.cancelDrag(reason: DndCancelReason.user);
    if (event != null) {
      widget.onDragCancel?.call(event);
      _controller?.reset();
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return DndDraggableHandleScope(
      draggable: this,
      child: Semantics(
        enabled: !widget.disabled,
        focusable: !widget.disabled,
        hint: 'Press Space or Enter to pick up, arrow keys to move, Escape to cancel.',
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        child: Focus(
          focusNode: _focusNode,
          canRequestFocus: !widget.disabled,
          onKeyEvent: _handleKeyEvent,
          child: Listener(
            behavior: widget.hitTestBehavior ?? HitTestBehavior.opaque,
            onPointerDown: widget.disabled ? null : _handlePointerDown,
            onPointerMove: widget.disabled ? null : _handlePointerMove,
            onPointerUp: widget.disabled ? null : _handlePointerUp,
            onPointerCancel: widget.disabled ? null : _handlePointerCancel,
            child: GestureDetector(
              key: _measureKey,
              behavior: widget.hitTestBehavior ?? HitTestBehavior.opaque,
              onPanStart: widget.disabled || _usesLongPressActivation
                  ? null
                  : (details) {
                      _handlePanStart(details, fromHandle: false);
                    },
              onPanUpdate: widget.disabled || _usesLongPressActivation ? null : _handlePanUpdate,
              onPanEnd: widget.disabled || _usesLongPressActivation ? null : _handlePanEnd,
              onPanCancel: widget.disabled || _usesLongPressActivation ? null : _handlePanCancel,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

@internal
class DndDraggableHandleScope extends InheritedWidget {
  const DndDraggableHandleScope({
    super.key,
    required this.draggable,
    required super.child,
  });

  final DndDraggableHandleController draggable;

  static DndDraggableHandleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DndDraggableHandleScope>();
  }

  @override
  bool updateShouldNotify(DndDraggableHandleScope oldWidget) {
    return draggable != oldWidget.draggable;
  }
}

@internal
abstract interface class DndDraggableHandleController {
  void registerHandle();

  void unregisterHandle();

  void markHandlePointerActive();

  void clearHandlePointerActive();
}

DndPoint _pointFromOffset(Offset offset) {
  return DndPoint(offset.dx, offset.dy);
}
