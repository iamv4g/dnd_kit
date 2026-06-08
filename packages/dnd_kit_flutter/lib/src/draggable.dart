import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'measuring.dart';
import 'scope.dart';

/// Called when a draggable starts a drag session.
typedef DndDragStartCallback = void Function(DndDragStartEvent event);

/// Called when an active draggable moves.
typedef DndDragMoveCallback = void Function(DndDragMoveEvent event);

/// Called when an active draggable ends.
typedef DndDragEndCallback = void Function(DndDragEndEvent event);

/// Called when a pending or active draggable is cancelled.
typedef DndDragCancelCallback = void Function(DndDragCancelEvent event);

/// Registers a child as draggable and wires basic pointer gestures to a scope.
class DndDraggable extends StatefulWidget {
  /// Creates a draggable widget.
  const DndDraggable({
    super.key,
    required this.id,
    required this.child,
    this.disabled = false,
    this.data,
    this.hitTestBehavior,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  });

  /// The stable draggable id.
  final DndId id;

  /// The widget users can drag.
  final Widget child;

  /// Whether drag gestures should be ignored for this draggable.
  final bool disabled;

  /// Optional application-owned metadata stored in the controller registry.
  final Object? data;

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

class _DndDraggableState extends State<DndDraggable> {
  final GlobalKey _measureKey = GlobalKey();
  DndController? _controller;
  DndController? _registeredController;
  DndDraggableRegistration? _registration;
  bool _gestureStartedDrag = false;
  bool _disabledCancelScheduled = false;

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

    if (!oldWidget.disabled && widget.disabled && _isActiveWidgetDrag) {
      _scheduleDisabledCancel();
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  bool get _isActiveWidgetDrag {
    return _gestureStartedDrag && _controller?.activeId == widget.id;
  }

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

  void _handlePanStart(DragStartDetails details) {
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

    controller.beginDrag(
      DndSensorActivationEvent(
        activeId: widget.id,
        position: _pointFromOffset(details.globalPosition),
        inputKind: DndInputKind.pointer,
      ),
      activeRect: activeRect,
    );

    final event = controller.startDrag();
    if (event == null) {
      return;
    }

    _gestureStartedDrag = true;
    widget.onDragStart?.call(event);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isActiveWidgetDrag) {
      return;
    }

    final event = _controller?.moveDrag(_pointFromOffset(details.globalPosition));
    if (event != null) {
      widget.onDragMove?.call(event);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isActiveWidgetDrag) {
      return;
    }

    final event = _controller?.endDrag();
    if (event != null) {
      widget.onDragEnd?.call(event);
    }
    _resetAfterGesture();
  }

  void _handlePanCancel() {
    if (!_isActiveWidgetDrag) {
      return;
    }

    _cancelDrag(reason: DndCancelReason.sensor);
  }

  void _cancelDrag({required DndCancelReason reason}) {
    final event = _controller?.cancelDrag(reason: reason);
    if (event != null) {
      widget.onDragCancel?.call(event);
    }
    _resetAfterGesture();
  }

  void _resetAfterGesture() {
    _gestureStartedDrag = false;
    _controller?.reset();
  }

  void _scheduleDisabledCancel() {
    if (_disabledCancelScheduled) {
      return;
    }

    _disabledCancelScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disabledCancelScheduled = false;
      if (!mounted || !widget.disabled || !_isActiveWidgetDrag) {
        return;
      }

      _cancelDrag(reason: DndCancelReason.disabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _measureKey,
      behavior: widget.hitTestBehavior ?? HitTestBehavior.opaque,
      onPanStart: widget.disabled ? null : _handlePanStart,
      onPanUpdate: widget.disabled ? null : _handlePanUpdate,
      onPanEnd: widget.disabled ? null : _handlePanEnd,
      onPanCancel: widget.disabled ? null : _handlePanCancel,
      child: widget.child,
    );
  }
}

DndPoint _pointFromOffset(Offset offset) {
  return DndPoint(offset.dx, offset.dy);
}
