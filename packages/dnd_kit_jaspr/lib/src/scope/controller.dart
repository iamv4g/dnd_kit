import 'dart:async';

import 'package:dnd_kit/dnd_kit.dart';
import 'package:jaspr/jaspr.dart';

/// Coordinates Jaspr adapter drag state while keeping user data external.
///
/// This is the Jaspr counterpart of the Flutter `DndController`: a thin wrapper
/// over the framework-neutral [DndRuntime] in `dnd_kit`. It exposes the
/// runtime as a Jaspr [ChangeNotifier]. When used under [DndScope], duplicate-id
/// diagnostics are deferred to the Jaspr post-frame boundary so owner-aware
/// registration settles at a frame boundary appropriate for Jaspr component
/// reconciliation; without a scope the controller falls back to a microtask.
/// All drag lifecycle, collision,
/// modifier, and measuring behavior lives in the shared runtime so the Flutter
/// and Jaspr adapters share one drag engine.
class DndController extends ChangeNotifier {
  /// Creates a drag controller.
  DndController({
    DndState initialState = const DndIdle(),
    DndCollisionDetector? collisionDetector,
    Iterable<DndModifier> modifiers = const <DndModifier>[],
    DndDiagnosticsConfig diagnosticsConfig = const DndDiagnosticsConfig(),
  }) {
    _runtime = DndRuntime(
      initialState: initialState,
      collisionDetector: collisionDetector,
      modifiers: modifiers,
      diagnosticsConfig: diagnosticsConfig,
      onNotify: notifyListeners,
      scheduleDeferredTask: scheduleMicrotask,
    );
  }

  late final DndRuntime _runtime;

  /// The shared framework-neutral runtime this controller wraps.
  ///
  /// Adapter sensors (such as `DndPointerSensor`) are driven against the
  /// runtime directly.
  DndRuntime get runtime => _runtime;

  /// Registered draggable and droppable metadata for this controller.
  DndRegistry get registry => _runtime.registry;

  /// Adapter-owned measured rectangles for registered drag-and-drop components.
  DndMeasuringRegistry get measuring => _runtime.measuring;

  /// The detector used to rank measured droppable collision candidates.
  DndCollisionDetector get collisionDetector => _runtime.collisionDetector;

  /// The modifiers applied to active drag movement before collision detection.
  List<DndModifier> get modifiers => _runtime.modifiers;

  /// The current drag lifecycle state.
  DndState get state => _runtime.state;

  /// The droppable currently under the active drag, when one exists.
  DndId? get overId => _runtime.overId;

  /// The active draggable rectangle, anchored at drag start when one is known.
  DndRect? get activeRect => _runtime.activeRect;

  /// Whether no drag is active or pending.
  bool get isIdle => _runtime.isIdle;

  /// Whether a drag session is currently active.
  bool get isDragging => _runtime.isDragging;

  /// The active session when a drag is moving or dropping.
  DndDragSession? get activeSession => _runtime.activeSession;

  /// The active draggable id when one is pending, dragging, dropping, or cancelled.
  DndId? get activeId => _runtime.activeId;

  /// Starts pending activation for [event].
  void beginDrag(DndSensorActivationEvent event, {DndRect? activeRect}) {
    _runtime.beginDrag(event, activeRect: activeRect);
  }

  /// Promotes a pending drag into an active session.
  DndDragStartEvent? startDrag() => _runtime.startDrag();

  /// Moves the active drag session to [position].
  DndDragMoveEvent? moveDrag(DndPoint position) => _runtime.moveDrag(position);

  /// Ends the active drag session and moves into dropping state.
  DndDragEndEvent? endDrag({DndId? overId}) => _runtime.endDrag(overId: overId);

  /// Cancels a pending or active drag.
  DndDragCancelEvent? cancelDrag({DndCancelReason reason = DndCancelReason.user}) {
    return _runtime.cancelDrag(reason: reason);
  }

  /// Returns a dropping or cancelled controller to idle.
  void reset() => _runtime.reset();
}
