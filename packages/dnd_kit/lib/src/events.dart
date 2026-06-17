import 'geometry.dart';
import 'id.dart';
import 'state.dart';

/// Base type for drag lifecycle events.
sealed class DndDragEvent {
  /// Creates a drag lifecycle event.
  const DndDragEvent({required this.session});

  /// The drag session represented by this event.
  final DndDragSession session;

  /// The stable id of the active draggable.
  DndId get activeId => session.activeId;

  /// The pointer position when the session started.
  DndPoint get initialPointer => session.initialPointer;

  /// The latest pointer position known by this event.
  DndPoint get currentPointer => session.currentPointer;

  /// The movement from [initialPointer] to [currentPointer].
  DndPoint get delta => session.delta;

  /// A transform representing the current drag movement.
  DndTransform get transform => session.transform;

  /// The input source that activated this drag.
  DndInputKind get inputKind => session.inputKind;
}

/// Event emitted when a drag session starts.
final class DndDragStartEvent extends DndDragEvent {
  /// Creates a drag start event.
  const DndDragStartEvent({required super.session});

  @override
  bool operator ==(Object other) => other is DndDragStartEvent && other.session == session;

  @override
  int get hashCode => Object.hash(DndDragStartEvent, session);

  @override
  String toString() => 'DndDragStartEvent(session: $session)';
}

/// Event emitted when the active drag moves.
final class DndDragMoveEvent extends DndDragEvent {
  /// Creates a drag move event.
  const DndDragMoveEvent({required super.session});

  @override
  bool operator ==(Object other) => other is DndDragMoveEvent && other.session == session;

  @override
  int get hashCode => Object.hash(DndDragMoveEvent, session);

  @override
  String toString() => 'DndDragMoveEvent(session: $session)';
}

/// Event emitted when the active drag is evaluated over a droppable target.
final class DndDragOverEvent extends DndDragEvent {
  /// Creates a drag over event.
  const DndDragOverEvent({
    required super.session,
    this.overId,
  });

  /// The droppable currently under the active drag, when one exists.
  final DndId? overId;

  @override
  bool operator ==(Object other) {
    return other is DndDragOverEvent && other.session == session && other.overId == overId;
  }

  @override
  int get hashCode => Object.hash(DndDragOverEvent, session, overId);

  @override
  String toString() => 'DndDragOverEvent(session: $session, overId: $overId)';
}

/// Event emitted when the active drag ends.
final class DndDragEndEvent extends DndDragEvent {
  /// Creates a drag end event.
  const DndDragEndEvent({
    required super.session,
    this.overId,
  });

  /// The droppable the active drag ended over, when one exists.
  final DndId? overId;

  @override
  bool operator ==(Object other) {
    return other is DndDragEndEvent && other.session == session && other.overId == overId;
  }

  @override
  int get hashCode => Object.hash(DndDragEndEvent, session, overId);

  @override
  String toString() => 'DndDragEndEvent(session: $session, overId: $overId)';
}

/// Event emitted when a pending or active drag is cancelled.
final class DndDragCancelEvent {
  /// Creates a drag cancel event.
  const DndDragCancelEvent({
    required this.activeId,
    this.session,
    this.reason = DndCancelReason.unknown,
  });

  /// The stable id of the cancelled draggable.
  final DndId activeId;

  /// The drag session at cancellation time, when one had started.
  final DndDragSession? session;

  /// Why the drag was cancelled.
  final DndCancelReason reason;

  /// The pointer position when the session started, when available.
  DndPoint? get initialPointer => session?.initialPointer;

  /// The latest pointer position known by this event, when available.
  DndPoint? get currentPointer => session?.currentPointer;

  /// The movement from initial to current pointer, when available.
  DndPoint? get delta => session?.delta;

  /// A transform representing the drag movement, when available.
  DndTransform? get transform => session?.transform;

  /// The input source that activated the drag, when available.
  DndInputKind get inputKind => session?.inputKind ?? DndInputKind.unknown;

  @override
  bool operator ==(Object other) {
    return other is DndDragCancelEvent &&
        other.activeId == activeId &&
        other.session == session &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(activeId, session, reason);

  @override
  String toString() {
    return 'DndDragCancelEvent(activeId: $activeId, session: $session, '
        'reason: $reason)';
  }
}
