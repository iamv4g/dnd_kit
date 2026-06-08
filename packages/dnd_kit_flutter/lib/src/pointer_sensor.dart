import 'dart:async';

import 'package:dnd_kit_core/dnd_kit_core.dart';

import 'controller.dart';

/// Called when a draggable starts a drag session.
typedef DndDragStartCallback = void Function(DndDragStartEvent event);

/// Called when an active draggable moves.
typedef DndDragMoveCallback = void Function(DndDragMoveEvent event);

/// Called when an active draggable ends.
typedef DndDragEndCallback = void Function(DndDragEndEvent event);

/// Called when a pending or active draggable is cancelled.
typedef DndDragCancelCallback = void Function(DndDragCancelEvent event);

/// Flutter pointer sensor runtime that coordinates activation constraints.
class DndPointerSensor implements DndSensor {
  /// Creates a pointer sensor runtime.
  DndPointerSensor({
    required this.controller,
    this.activeRect,
    this.constraint = DndSensorActivationConstraint.none,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  });

  /// The controller this sensor drives.
  final DndController controller;

  /// The measured active draggable rectangle at activation time.
  final DndRect? activeRect;

  /// The activation constraint this sensor applies before starting a drag.
  final DndSensorActivationConstraint constraint;

  /// Callback for a started drag session.
  final DndDragStartCallback? onDragStart;

  /// Callback for active drag movement.
  final DndDragMoveCallback? onDragMove;

  /// Callback for a completed drag.
  final DndDragEndCallback? onDragEnd;

  /// Callback for a cancelled drag.
  final DndDragCancelCallback? onDragCancel;

  Timer? _activationTimer;
  DndPoint? _pendingInitialPointer;
  DndPoint? _latestPendingPointer;
  bool _activationDelayElapsed = false;
  bool _isPending = false;
  bool _isDragging = false;

  @override
  DndSensorDescriptor get descriptor {
    return DndSensorDescriptor(
      kind: DndSensorKind.pointer,
      inputKind: DndInputKind.pointer,
      constraint: constraint,
      activator: (event) => event.inputKind == DndInputKind.pointer,
    );
  }

  /// Whether this sensor owns a pending or active drag.
  bool get isActive => _isPending || _isDragging;

  @override
  void start(DndSensorActivationEvent event) {
    if (!descriptor.canActivate(event)) {
      return;
    }

    if (!controller.isIdle) {
      assert(false, 'Cannot start a pointer sensor while another drag is active.');
      return;
    }

    controller.beginDrag(event, activeRect: activeRect);

    _isPending = true;
    _pendingInitialPointer = event.position;
    _latestPendingPointer = event.position;
    _activationDelayElapsed = constraint.delay == Duration.zero;
    _scheduleActivationTimer();
    _tryStartDrag(event.position);
  }

  @override
  void move(DndPoint position) {
    if (_isPending) {
      _latestPendingPointer = position;

      final initialPointer = _pendingInitialPointer;
      if (initialPointer == null) {
        return;
      }

      if (!constraint.allowsPendingMovement(
        initialPointer: initialPointer,
        currentPointer: position,
        elapsed: _pendingElapsed,
      )) {
        cancel(reason: DndCancelReason.sensor);
        return;
      }

      _tryStartDrag(position);
      return;
    }

    if (!_isDragging) {
      return;
    }

    final event = controller.moveDrag(position);
    if (event != null) {
      onDragMove?.call(event);
    }
  }

  @override
  void end() {
    if (_isPending) {
      cancel(reason: DndCancelReason.sensor);
      return;
    }

    if (!_isDragging) {
      return;
    }

    final event = controller.endDrag();
    if (event != null) {
      onDragEnd?.call(event);
    }
    _resetAfterGesture();
  }

  @override
  void cancel({DndCancelReason reason = DndCancelReason.sensor}) {
    if (!isActive) {
      return;
    }

    final event = controller.cancelDrag(reason: reason);
    if (event != null) {
      onDragCancel?.call(event);
    }
    _resetAfterGesture();
  }

  /// Releases timer resources without changing controller state.
  void dispose() {
    _activationTimer?.cancel();
    _activationTimer = null;
  }

  void _scheduleActivationTimer() {
    _activationTimer?.cancel();

    final delay = constraint.delay;
    if (delay == Duration.zero) {
      return;
    }

    _activationTimer = Timer(delay, () {
      final currentPointer = _latestPendingPointer;
      if (currentPointer == null) {
        return;
      }

      _activationDelayElapsed = true;
      _tryStartDrag(currentPointer);
    });
  }

  void _tryStartDrag(DndPoint currentPointer) {
    if (!_isPending) {
      return;
    }

    final initialPointer = _pendingInitialPointer;
    if (initialPointer == null) {
      return;
    }

    if (!constraint.isSatisfied(
      initialPointer: initialPointer,
      currentPointer: currentPointer,
      elapsed: _pendingElapsed,
    )) {
      return;
    }

    _activationTimer?.cancel();
    _activationTimer = null;

    final event = controller.startDrag();
    if (event == null) {
      return;
    }

    _isPending = false;
    _isDragging = true;
    onDragStart?.call(event);

    if (currentPointer != initialPointer) {
      final moveEvent = controller.moveDrag(currentPointer);
      if (moveEvent != null) {
        onDragMove?.call(moveEvent);
      }
    }
  }

  void _resetAfterGesture() {
    _activationTimer?.cancel();
    _activationTimer = null;
    _isPending = false;
    _isDragging = false;
    _pendingInitialPointer = null;
    _latestPendingPointer = null;
    _activationDelayElapsed = false;
    controller.reset();
  }

  Duration get _pendingElapsed {
    return _activationDelayElapsed ? constraint.delay : Duration.zero;
  }
}
