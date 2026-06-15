import 'collision.dart';
import 'diagnostics.dart';
import 'events.dart';
import 'geometry.dart';
import 'id.dart';
import 'measuring.dart';
import 'modifier.dart';
import 'registry.dart';
import 'sensor.dart';
import 'state.dart';

/// Framework-neutral owner of the drag lifecycle.
///
/// [DndRuntime] is the single drag engine shared by every adapter. It owns the
/// drag state machine, collision orchestration, modifier application, and
/// measurement-cache interactions, all in pure Dart with no Flutter or DOM
/// dependency.
///
/// Adapters wrap this runtime with their own change-notification mechanism:
///
/// - the Flutter adapter exposes `DndController extends ChangeNotifier` and
///   passes `notifyListeners` as [onNotify];
/// - the Jaspr adapter wraps the same runtime with a browser-friendly notifier.
///
/// Pass [onNotify] to be called whenever observable state changes, and
/// [scheduleDeferredTask] to defer the registry's duplicate-id diagnostics to a
/// post-frame/microtask boundary appropriate for the adapter. When
/// [scheduleDeferredTask] is null, duplicate diagnostics run synchronously.
class DndRuntime {
  /// Creates a drag runtime.
  DndRuntime({
    DndState initialState = const DndIdle(),
    DndCollisionDetector? collisionDetector,
    Iterable<DndModifier> modifiers = const <DndModifier>[],
    DndDiagnosticsConfig diagnosticsConfig = const DndDiagnosticsConfig(),
    void Function()? onNotify,
    DndDeferredTaskScheduler? scheduleDeferredTask,
  })  : _state = initialState,
        _onNotify = onNotify,
        registry = DndRegistry(
          diagnosticsConfig: diagnosticsConfig,
          scheduleDeferredTask: scheduleDeferredTask,
        ),
        modifiers = List<DndModifier>.unmodifiable(modifiers),
        collisionDetector = collisionDetector ??
            DndCollisionDetectors.compose(
              const <DndCollisionDetector>[
                DndCollisionDetectors.pointerWithin,
                DndCollisionDetectors.rectIntersection,
              ],
            );

  final void Function()? _onNotify;

  DndState _state;
  DndRect? _activeRect;
  DndId? _overId;

  /// Registered draggable and droppable metadata for this runtime.
  final DndRegistry registry;

  /// Adapter-owned measured rectangles for registered drag-and-drop sources.
  final DndMeasuringRegistry measuring = DndMeasuringRegistry();

  /// The detector used to rank measured droppable collision candidates.
  final DndCollisionDetector collisionDetector;

  /// The modifiers applied to active drag movement before collision detection.
  final List<DndModifier> modifiers;

  /// The current drag lifecycle state.
  DndState get state => _state;

  /// The droppable currently under the active drag, when one exists.
  DndId? get overId => _overId;

  /// The active draggable rectangle, anchored at drag start when one is known.
  DndRect? get activeRect => _activeRect;

  /// Whether no drag is active or pending.
  bool get isIdle => _state is DndIdle;

  /// Whether a drag session is currently active.
  bool get isDragging => _state is DndDragging;

  /// The active session when a drag is moving or dropping.
  DndDragSession? get activeSession {
    return switch (_state) {
      DndDragging(:final session) || DndDropping(:final session) => session,
      _ => null,
    };
  }

  /// The active draggable id when one is pending, dragging, dropping, or cancelled.
  DndId? get activeId {
    return switch (_state) {
      DndPending(:final activeId) => activeId,
      DndDragging(:final session) || DndDropping(:final session) => session.activeId,
      DndCancelled(:final activeId) => activeId,
      DndIdle() => null,
    };
  }

  /// Starts pending activation for [event].
  void beginDrag(DndSensorActivationEvent event, {DndRect? activeRect}) {
    _activeRect = activeRect ?? measuring.draggableRect(event.activeId);
    _overId = null;
    _setState(
      DndPending(
        activeId: event.activeId,
        initialPointer: event.position,
        inputKind: event.inputKind,
      ),
    );
  }

  /// Promotes a pending drag into an active session.
  DndDragStartEvent? startDrag() {
    final current = _state;
    if (current is! DndPending) {
      assert(false, 'Cannot start a drag when the runtime is not pending.');
      return null;
    }

    final next = DndDragging(session: current.startSession());
    _setState(next);
    return DndDragStartEvent(session: next.session);
  }

  /// Moves the active drag session to [position].
  DndDragMoveEvent? moveDrag(DndPoint position) {
    final current = _state;
    if (current is! DndDragging) {
      assert(false, 'Cannot move a drag when the runtime is not dragging.');
      return null;
    }

    _refreshMeasurements(current.session.activeId);
    final next = DndDragging(session: _modifiedSession(current.session, position));
    _replaceState(next);
    _updateCollision(next.session);
    return DndDragMoveEvent(session: next.session);
  }

  /// Ends the active drag session and moves into dropping state.
  DndDragEndEvent? endDrag({DndId? overId}) {
    final current = _state;
    if (current is! DndDragging) {
      assert(false, 'Cannot end a drag when the runtime is not dragging.');
      return null;
    }

    final next = DndDropping(session: current.session);
    _setState(next);
    return DndDragEndEvent(session: next.session, overId: overId ?? _overId);
  }

  /// Cancels a pending or active drag.
  DndDragCancelEvent? cancelDrag({DndCancelReason reason = DndCancelReason.user}) {
    final current = _state;
    final event = switch (current) {
      DndPending(:final activeId) => DndDragCancelEvent(
          activeId: activeId,
          reason: reason,
        ),
      DndDragging(:final session) => DndDragCancelEvent(
          activeId: session.activeId,
          session: session,
          reason: reason,
        ),
      _ => null,
    };

    if (event == null) {
      assert(false, 'Cannot cancel a drag when the runtime is idle or dropping.');
      return null;
    }

    _setState(DndCancelled(activeId: event.activeId, reason: reason));
    return event;
  }

  /// Returns a dropping or cancelled runtime to idle.
  void reset() {
    final current = _state;
    if (current is DndIdle) {
      return;
    }

    if (current is! DndDropping && current is! DndCancelled) {
      assert(false, 'Cannot reset before a drag has dropped or cancelled.');
      return;
    }

    _activeRect = null;
    _overId = null;
    _setState(const DndIdle());
  }

  void _updateCollision(DndDragSession session) {
    _refreshMeasurements(session.activeId);
    final activeRect = _activeRect;
    if (activeRect == null) {
      _setOverId(null);
      return;
    }

    final droppableRects = <DndId, DndRect>{};
    for (final entry in measuring.droppableRects.entries) {
      final registration = registry.droppable(entry.key);
      if (registration == null || registration.disabled) {
        continue;
      }

      droppableRects[entry.key] = entry.value;
    }

    if (droppableRects.isEmpty) {
      _setOverId(null);
      return;
    }

    final result = collisionDetector(
      DndCollisionInput(
        activeRect: activeRect.translate(session.transform.offset),
        droppableRects: droppableRects,
        pointer: session.currentPointer,
      ),
    );
    _setOverId(result.firstOrNull?.id);
  }

  void _refreshMeasurements(DndId activeId) {
    measuring.refreshDirty();
    final current = _state;
    if (current is DndDragging || current is DndDropping) {
      final currentActiveRect = _activeRect;
      final measuredActiveRect = measuring.draggableRect(activeId);
      if (currentActiveRect != null && measuredActiveRect != null) {
        _activeRect = DndRect(
          left: currentActiveRect.left,
          top: currentActiveRect.top,
          width: measuredActiveRect.width,
          height: measuredActiveRect.height,
        );
      }
      return;
    }

    final measuredActiveRect = measuring.draggableRect(activeId);
    if (measuredActiveRect != null) {
      _activeRect = measuredActiveRect;
    }
  }

  DndDragSession _modifiedSession(DndDragSession session, DndPoint rawPosition) {
    if (modifiers.isEmpty) {
      return session.moveTo(rawPosition);
    }

    final activeRect = _activeRect;
    if (activeRect == null) {
      return session.moveTo(rawPosition);
    }

    final rawTransform = DndTransform(
      x: rawPosition.x - session.initialPointer.x,
      y: rawPosition.y - session.initialPointer.y,
    );
    final modifiedTransform = DndModifiers.compose(modifiers)(
      DndModifierInput(
        transform: rawTransform,
        activeRect: activeRect,
        droppableRects: measuring.droppableRects,
        pointer: rawPosition,
      ),
    );

    return session.moveTo(session.initialPointer.translate(modifiedTransform.offset));
  }

  void _setOverId(DndId? next) {
    if (_overId == next) {
      return;
    }

    _overId = next;
    _notify();
  }

  void _setState(DndState next) {
    final current = _state;
    if (current == next) {
      return;
    }

    _state = current.transitionTo(next);
    _notify();
  }

  void _replaceState(DndState next) {
    if (_state == next) {
      return;
    }

    _state = next;
    _notify();
  }

  void _notify() => _onNotify?.call();
}
