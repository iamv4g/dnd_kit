import 'geometry.dart';
import 'id.dart';

/// The input source that activated a drag session.
enum DndInputKind {
  /// Input source has not been classified yet.
  unknown,

  /// Generic pointer input.
  pointer,

  /// Mouse input.
  mouse,

  /// Touch input.
  touch,

  /// Keyboard input.
  keyboard,
}

/// Why an active or pending drag was cancelled.
enum DndCancelReason {
  /// The cancellation reason is not known.
  unknown,

  /// The user cancelled the drag.
  user,

  /// The activating sensor cancelled the drag.
  sensor,

  /// Dragging became disabled before the drag completed.
  disabled,
}

/// Immutable data for an active drag session.
final class DndDragSession {
  /// Creates a drag session.
  const DndDragSession({
    required this.activeId,
    required this.initialPointer,
    required this.currentPointer,
    this.inputKind = DndInputKind.unknown,
  });

  /// Creates a new session at the initial pointer position.
  factory DndDragSession.start({
    required DndId activeId,
    required DndPoint initialPointer,
    DndInputKind inputKind = DndInputKind.unknown,
  }) {
    return DndDragSession(
      activeId: activeId,
      initialPointer: initialPointer,
      currentPointer: initialPointer,
      inputKind: inputKind,
    );
  }

  /// The stable id of the active draggable.
  final DndId activeId;

  /// The pointer position when the session started.
  final DndPoint initialPointer;

  /// The latest pointer position known by the session.
  final DndPoint currentPointer;

  /// The input source that activated this session.
  final DndInputKind inputKind;

  /// The movement from [initialPointer] to [currentPointer].
  DndPoint get delta => currentPointer.difference(initialPointer);

  /// A transform representing the current drag movement.
  DndTransform get transform => DndTransform(x: delta.x, y: delta.y);

  /// Returns a session moved to [pointer].
  DndDragSession moveTo(DndPoint pointer) {
    return DndDragSession(
      activeId: activeId,
      initialPointer: initialPointer,
      currentPointer: pointer,
      inputKind: inputKind,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DndDragSession &&
        other.activeId == activeId &&
        other.initialPointer == initialPointer &&
        other.currentPointer == currentPointer &&
        other.inputKind == inputKind;
  }

  @override
  int get hashCode => Object.hash(activeId, initialPointer, currentPointer, inputKind);

  @override
  String toString() {
    return 'DndDragSession(activeId: $activeId, initialPointer: $initialPointer, '
        'currentPointer: $currentPointer, inputKind: $inputKind)';
  }
}

/// A drag lifecycle state.
sealed class DndState {
  /// Creates a drag lifecycle state.
  const DndState();

  /// Whether this state can transition to [next].
  bool canTransitionTo(DndState next) {
    return switch ((this, next)) {
      (DndIdle(), DndPending()) => true,
      (DndPending(), DndDragging()) => true,
      (DndPending(), DndCancelled()) => true,
      (DndDragging(), DndDropping()) => true,
      (DndDragging(), DndCancelled()) => true,
      (DndDropping(), DndIdle()) => true,
      (DndCancelled(), DndIdle()) => true,
      _ => false,
    };
  }

  /// Returns [next] after validating the transition in debug mode.
  DndState transitionTo(DndState next) {
    assert(
      canTransitionTo(next),
      'Invalid dnd state transition from $runtimeType to ${next.runtimeType}.',
    );
    return next;
  }
}

/// No drag is active or pending.
final class DndIdle extends DndState {
  /// Creates the idle state.
  const DndIdle();

  @override
  bool operator ==(Object other) => other is DndIdle;

  @override
  int get hashCode => 'DndIdle'.hashCode;

  @override
  String toString() => 'DndIdle()';
}

/// A drag has been activated but has not moved into a drag session yet.
final class DndPending extends DndState {
  /// Creates the pending state.
  const DndPending({
    required this.activeId,
    required this.initialPointer,
    this.inputKind = DndInputKind.unknown,
  });

  /// The stable id of the draggable waiting to start.
  final DndId activeId;

  /// The pointer position where activation began.
  final DndPoint initialPointer;

  /// The input source that activated this pending drag.
  final DndInputKind inputKind;

  /// Creates the drag session represented by this pending state.
  DndDragSession startSession() {
    return DndDragSession.start(
      activeId: activeId,
      initialPointer: initialPointer,
      inputKind: inputKind,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DndPending &&
        other.activeId == activeId &&
        other.initialPointer == initialPointer &&
        other.inputKind == inputKind;
  }

  @override
  int get hashCode => Object.hash(activeId, initialPointer, inputKind);

  @override
  String toString() {
    return 'DndPending(activeId: $activeId, initialPointer: $initialPointer, '
        'inputKind: $inputKind)';
  }
}

/// A drag session is actively moving.
final class DndDragging extends DndState {
  /// Creates the dragging state.
  const DndDragging({required this.session});

  /// The active drag session.
  final DndDragSession session;

  @override
  bool operator ==(Object other) => other is DndDragging && other.session == session;

  @override
  int get hashCode => session.hashCode;

  @override
  String toString() => 'DndDragging(session: $session)';
}

/// A drag has completed and is waiting for drop handling to settle.
final class DndDropping extends DndState {
  /// Creates the dropping state.
  const DndDropping({required this.session});

  /// The session being dropped.
  final DndDragSession session;

  @override
  bool operator ==(Object other) => other is DndDropping && other.session == session;

  @override
  int get hashCode => session.hashCode;

  @override
  String toString() => 'DndDropping(session: $session)';
}

/// A pending or active drag has been cancelled.
final class DndCancelled extends DndState {
  /// Creates the cancelled state.
  const DndCancelled({
    this.activeId,
    this.reason = DndCancelReason.unknown,
  });

  /// The draggable that was cancelled, when known.
  final DndId? activeId;

  /// Why the drag was cancelled.
  final DndCancelReason reason;

  @override
  bool operator ==(Object other) {
    return other is DndCancelled && other.activeId == activeId && other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(activeId, reason);

  @override
  String toString() => 'DndCancelled(activeId: $activeId, reason: $reason)';
}
