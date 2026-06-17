import 'dart:async';

import 'events.dart';
import 'geometry.dart';
import 'runtime.dart';
import 'sensor.dart';
import 'state.dart';

/// Called when a draggable starts a drag session.
typedef DndDragStartCallback = void Function(DndDragStartEvent event);

/// Called when an active draggable moves.
typedef DndDragMoveCallback = void Function(DndDragMoveEvent event);

/// Called when an active draggable ends.
typedef DndDragEndCallback = void Function(DndDragEndEvent event);

/// Called when a pending or active draggable is cancelled.
typedef DndDragCancelCallback = void Function(DndDragCancelEvent event);

/// Framework-neutral pointer sensor runtime that coordinates activation
/// constraints over a shared [DndRuntime].
///
/// Adapters feed normalized pointer input into [start], [move], [end], and
/// [cancel]; the sensor applies the activation [constraint] (distance, delay,
/// movement tolerance) before promoting a pending drag into an active session
/// on the [runtime]. The pending/timer/tolerance state machine is pure Dart and
/// shared by the Flutter and Jaspr adapters.
class DndPointerSensor implements DndSensor {
  /// Creates a pointer sensor runtime over [runtime].
  DndPointerSensor({
    required this.runtime,
    this.activeRect,
    this.constraint = DndSensorActivationConstraint.none,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  });

  /// The drag runtime this sensor drives.
  final DndRuntime runtime;

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
      activator: (event) {
        return switch (event.inputKind) {
          DndInputKind.pointer || DndInputKind.mouse || DndInputKind.touch => true,
          DndInputKind.unknown || DndInputKind.keyboard => false,
        };
      },
    );
  }

  /// Whether this sensor owns a pending or active drag.
  bool get isActive => _isPending || _isDragging;

  @override
  void start(DndSensorActivationEvent event) {
    if (!descriptor.canActivate(event)) {
      return;
    }

    if (!runtime.isIdle) {
      assert(false, 'Cannot start a pointer sensor while another drag is active.');
      return;
    }

    runtime.beginDrag(event, activeRect: activeRect);

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

    final event = runtime.moveDrag(position);
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

    final event = runtime.endDrag();
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

    final event = runtime.cancelDrag(reason: reason);
    if (event != null) {
      onDragCancel?.call(event);
    }
    _resetAfterGesture();
  }

  /// Releases timer resources without changing runtime state.
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

    final event = runtime.startDrag();
    if (event == null) {
      return;
    }

    _isPending = false;
    _isDragging = true;
    onDragStart?.call(event);

    if (currentPointer != initialPointer) {
      final moveEvent = runtime.moveDrag(currentPointer);
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
    runtime.reset();
  }

  Duration get _pendingElapsed {
    return _activationDelayElapsed ? constraint.delay : Duration.zero;
  }
}
