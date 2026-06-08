import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:test/test.dart';

void main() {
  group('DndDragEvent', () {
    final session = DndDragSession.start(
      activeId: const DndId('task-1'),
      initialPointer: const DndPoint(10, 20),
      inputKind: DndInputKind.mouse,
    ).moveTo(const DndPoint(14, 17));

    test('exposes session-derived drag data', () {
      final event = DndDragMoveEvent(session: session);

      expect(event.session, session);
      expect(event.activeId, const DndId('task-1'));
      expect(event.initialPointer, const DndPoint(10, 20));
      expect(event.currentPointer, const DndPoint(14, 17));
      expect(event.delta, const DndPoint(4, -3));
      expect(event.transform, const DndTransform(x: 4, y: -3));
      expect(event.inputKind, DndInputKind.mouse);
    });

    test('compares start and move events by value and runtime type', () {
      expect(
        DndDragStartEvent(session: session),
        equals(DndDragStartEvent(session: session)),
      );
      expect(
        DndDragMoveEvent(session: session),
        equals(DndDragMoveEvent(session: session)),
      );
      expect(
        DndDragStartEvent(session: session),
        isNot(equals(DndDragMoveEvent(session: session))),
      );
      expect(
        DndDragStartEvent(session: session).hashCode,
        equals(DndDragStartEvent(session: session).hashCode),
      );
    });

    test('reports nullable over target for over and end events', () {
      final over = DndDragOverEvent(
        session: session,
        overId: const DndId('drop-1'),
      );
      final end = DndDragEndEvent(session: session);

      expect(over.overId, const DndId('drop-1'));
      expect(
        over,
        equals(
          DndDragOverEvent(
            session: session,
            overId: const DndId('drop-1'),
          ),
        ),
      );
      expect(end.overId, isNull);
      expect(end, equals(DndDragEndEvent(session: session)));
    });

    test('has readable string output', () {
      expect(
        DndDragOverEvent(
          session: session,
          overId: const DndId('drop-1'),
        ).toString(),
        'DndDragOverEvent(session: DndDragSession(activeId: DndId(task-1), '
        'initialPointer: DndPoint(10.0, 20.0), currentPointer: '
        'DndPoint(14.0, 17.0), inputKind: DndInputKind.mouse), '
        'overId: DndId(drop-1))',
      );
    });
  });

  group('DndDragCancelEvent', () {
    final session = DndDragSession.start(
      activeId: const DndId('task-1'),
      initialPointer: const DndPoint(1, 2),
      inputKind: DndInputKind.touch,
    ).moveTo(const DndPoint(4, 6));

    test('supports cancellation after a session starts', () {
      final event = DndDragCancelEvent(
        activeId: const DndId('task-1'),
        session: session,
        reason: DndCancelReason.user,
      );

      expect(event.activeId, const DndId('task-1'));
      expect(event.session, session);
      expect(event.reason, DndCancelReason.user);
      expect(event.initialPointer, const DndPoint(1, 2));
      expect(event.currentPointer, const DndPoint(4, 6));
      expect(event.delta, const DndPoint(3, 4));
      expect(event.transform, const DndTransform(x: 3, y: 4));
      expect(event.inputKind, DndInputKind.touch);
    });

    test('supports pending cancellation before a session starts', () {
      const event = DndDragCancelEvent(
        activeId: DndId('task-1'),
        reason: DndCancelReason.disabled,
      );

      expect(event.session, isNull);
      expect(event.initialPointer, isNull);
      expect(event.currentPointer, isNull);
      expect(event.delta, isNull);
      expect(event.transform, isNull);
      expect(event.inputKind, DndInputKind.unknown);
    });

    test('compares by value', () {
      expect(
        DndDragCancelEvent(
          activeId: const DndId('task-1'),
          session: session,
          reason: DndCancelReason.sensor,
        ),
        equals(
          DndDragCancelEvent(
            activeId: const DndId('task-1'),
            session: session,
            reason: DndCancelReason.sensor,
          ),
        ),
      );
    });

    test('has readable string output', () {
      expect(
        const DndDragCancelEvent(
          activeId: DndId('task-1'),
          reason: DndCancelReason.disabled,
        ).toString(),
        'DndDragCancelEvent(activeId: DndId(task-1), session: null, '
        'reason: DndCancelReason.disabled)',
      );
    });
  });
}
