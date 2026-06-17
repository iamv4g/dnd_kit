import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('DndDragSession', () {
    test('starts at the initial pointer', () {
      final session = DndDragSession.start(
        activeId: const DndId('task-1'),
        initialPointer: const DndPoint(10, 20),
        inputKind: DndInputKind.mouse,
      );

      expect(session.activeId, const DndId('task-1'));
      expect(session.initialPointer, const DndPoint(10, 20));
      expect(session.currentPointer, const DndPoint(10, 20));
      expect(session.inputKind, DndInputKind.mouse);
      expect(session.delta, DndPoint.zero);
      expect(session.transform, DndTransform.identity);
    });

    test('moves by deriving delta from the initial pointer', () {
      final session = DndDragSession.start(
        activeId: const DndId('task-1'),
        initialPointer: const DndPoint(10, 20),
      ).moveTo(const DndPoint(14, 17));

      expect(session.currentPointer, const DndPoint(14, 17));
      expect(session.delta, const DndPoint(4, -3));
      expect(session.transform, const DndTransform(x: 4, y: -3));
    });

    test('compares by value', () {
      const session = DndDragSession(
        activeId: DndId('task-1'),
        initialPointer: DndPoint(1, 2),
        currentPointer: DndPoint(3, 4),
        inputKind: DndInputKind.touch,
      );

      expect(
        session,
        equals(
          const DndDragSession(
            activeId: DndId('task-1'),
            initialPointer: DndPoint(1, 2),
            currentPointer: DndPoint(3, 4),
            inputKind: DndInputKind.touch,
          ),
        ),
      );
      expect(session.hashCode, equals(session.hashCode));
      expect(
        session.toString(),
        'DndDragSession(activeId: DndId(task-1), initialPointer: DndPoint(1.0, 2.0), '
        'currentPointer: DndPoint(3.0, 4.0), inputKind: DndInputKind.touch)',
      );
    });
  });

  group('DndState', () {
    test('creates a session from pending state', () {
      const pending = DndPending(
        activeId: DndId('task-1'),
        initialPointer: DndPoint(5, 6),
        inputKind: DndInputKind.keyboard,
      );

      expect(
        pending.startSession(),
        DndDragSession.start(
          activeId: const DndId('task-1'),
          initialPointer: const DndPoint(5, 6),
          inputKind: DndInputKind.keyboard,
        ),
      );
    });

    test('allows valid lifecycle transitions', () {
      const idle = DndIdle();
      const pending = DndPending(activeId: DndId('task-1'), initialPointer: DndPoint.zero);
      final dragging = DndDragging(session: pending.startSession());
      final dropping = DndDropping(session: dragging.session);
      const cancelled = DndCancelled(activeId: DndId('task-1'), reason: DndCancelReason.user);

      expect(idle.canTransitionTo(pending), isTrue);
      expect(pending.canTransitionTo(dragging), isTrue);
      expect(pending.canTransitionTo(cancelled), isTrue);
      expect(dragging.canTransitionTo(dropping), isTrue);
      expect(dragging.canTransitionTo(cancelled), isTrue);
      expect(dropping.canTransitionTo(idle), isTrue);
      expect(cancelled.canTransitionTo(idle), isTrue);

      expect(idle.transitionTo(pending), same(pending));
      expect(pending.transitionTo(dragging), same(dragging));
      expect(dragging.transitionTo(dropping), same(dropping));
    });

    test('rejects invalid lifecycle transitions in debug mode', () {
      const idle = DndIdle();
      const pending = DndPending(activeId: DndId('task-1'), initialPointer: DndPoint.zero);
      final dragging = DndDragging(session: pending.startSession());
      final dropping = DndDropping(session: dragging.session);
      const cancelled = DndCancelled(activeId: DndId('task-1'));

      expect(idle.canTransitionTo(dragging), isFalse);
      expect(pending.canTransitionTo(idle), isFalse);
      expect(dragging.canTransitionTo(idle), isFalse);
      expect(dropping.canTransitionTo(cancelled), isFalse);
      expect(cancelled.canTransitionTo(dragging), isFalse);

      expect(() => idle.transitionTo(dragging), throwsA(isA<AssertionError>()));
      expect(() => dragging.transitionTo(idle), throwsA(isA<AssertionError>()));
    });

    test('compares states by value', () {
      const pending = DndPending(
        activeId: DndId('task-1'),
        initialPointer: DndPoint(1, 2),
        inputKind: DndInputKind.pointer,
      );
      final session = pending.startSession().moveTo(const DndPoint(4, 6));

      expect(const DndIdle(), equals(const DndIdle()));
      expect(pending, equals(pending));
      expect(DndDragging(session: session), equals(DndDragging(session: session)));
      expect(DndDropping(session: session), equals(DndDropping(session: session)));
      expect(
        const DndCancelled(activeId: DndId('task-1'), reason: DndCancelReason.disabled),
        equals(const DndCancelled(activeId: DndId('task-1'), reason: DndCancelReason.disabled)),
      );
    });
  });
}
