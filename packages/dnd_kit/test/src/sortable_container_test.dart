import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  final containers = <SortableContainer>[
    SortableContainer(
      id: const DndId('todo'),
      itemIds: const <DndId>[DndId('task-1'), DndId('task-2')],
    ),
    SortableContainer(
      id: const DndId('done'),
      itemIds: const <DndId>[DndId('task-3'), DndId('task-4')],
    ),
    SortableContainer(
      id: const DndId('empty'),
      itemIds: const <DndId>[],
    ),
  ];
  final itemRects = <DndId, DndRect>{
    const DndId('task-2'): const DndRect(left: 0, top: 30, width: 100, height: 20),
    const DndId('task-3'): const DndRect(left: 200, top: 0, width: 100, height: 20),
    const DndId('task-4'): const DndRect(left: 200, top: 30, width: 100, height: 20),
  };

  group('SortableContainer', () {
    test('stores immutable item order and supports equality', () {
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
      ];
      final container = SortableContainer(
        id: const DndId('container-1'),
        itemIds: itemIds,
      );

      itemIds.add(const DndId('item-3'));

      expect(container.id, const DndId('container-1'));
      expect(
        container.itemIds,
        const <DndId>[DndId('item-1'), DndId('item-2')],
      );
      expect(
        container,
        SortableContainer(
          id: const DndId('container-1'),
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
        ),
      );
      expect(
        () => container.itemIds.add(const DndId('item-4')),
        throwsUnsupportedError,
      );
      expect(container.indexOf(const DndId('item-2')), 1);
      expect(container.contains(const DndId('item-3')), isFalse);
    });
  });

  group('SortableMultiContainer.moveDetailsFor', () {
    test('reports cross-container moves over an item', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('task-3')),
        containers: containers,
      );

      expect(details?.activeId, const DndId('task-1'));
      expect(details?.overId, const DndId('task-3'));
      expect(details?.fromContainerId, const DndId('todo'));
      expect(details?.toContainerId, const DndId('done'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 0);
    });

    test('reports moves to the end when dropped over a container', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('done')),
        containers: containers,
      );

      expect(details?.fromContainerId, const DndId('todo'));
      expect(details?.toContainerId, const DndId('done'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 2);
    });

    test('reports same-container identifiers with from and to fields', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('task-2')),
        containers: containers,
      );

      expect(details?.fromContainerId, const DndId('todo'));
      expect(details?.toContainerId, const DndId('todo'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 1);
    });

    test('returns null for same-item and same-index no-op moves', () {
      expect(
        SortableMultiContainer.moveDetailsFor(
          _event(activeId: const DndId('task-1'), overId: const DndId('task-1')),
          containers: <SortableContainer>[
            SortableContainer(
              id: const DndId('todo'),
              itemIds: const <DndId>[DndId('task-1')],
            ),
          ],
        ),
        isNull,
      );

      expect(
        SortableMultiContainer.moveDetailsFor(
          _event(activeId: const DndId('task-1'), overId: const DndId('todo')),
          containers: <SortableContainer>[
            SortableContainer(
              id: const DndId('todo'),
              itemIds: const <DndId>[DndId('task-1')],
            ),
          ],
        ),
        isNull,
      );
    });

    test('returns null when the active item or drop target is unknown', () {
      expect(
        SortableMultiContainer.moveDetailsFor(
          _event(activeId: const DndId('missing'), overId: const DndId('task-1')),
          containers: containers,
        ),
        isNull,
      );

      expect(
        SortableMultiContainer.moveDetailsFor(
          _event(activeId: const DndId('task-1'), overId: const DndId('missing')),
          containers: containers,
        ),
        isNull,
      );
    });

    test('adapts cross-container insertion after the over item center', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(
          activeId: const DndId('task-1'),
          overId: const DndId('task-4'),
          from: const DndPoint(10, 10),
          to: const DndPoint(250, 55),
        ),
        containers: containers,
        itemRects: itemRects,
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 20),
      );

      expect(details?.fromContainerId, const DndId('todo'));
      expect(details?.toContainerId, const DndId('done'));
      expect(details?.toIndex, 2);
    });

    test('adaptive inserts before the over item when the pointer is in its upper half', () {
      // task-4 rect: top 30, height 20 → center y 40. Pointer at y 34 (upper half).
      final details = SortableMultiContainer.moveDetailsFor(
        _event(
          activeId: const DndId('task-1'),
          overId: const DndId('task-4'),
          from: const DndPoint(10, 10),
          to: const DndPoint(250, 34),
        ),
        containers: containers,
        itemRects: itemRects,
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 20),
      );

      expect(details?.toIndex, 1, reason: 'upper half of task-4 lands before it');
    });

    test('adaptive inserts after the over item when the pointer is in its lower half', () {
      // Pointer at y 46 (lower half of task-4, center 40).
      final details = SortableMultiContainer.moveDetailsFor(
        _event(
          activeId: const DndId('task-1'),
          overId: const DndId('task-4'),
          from: const DndPoint(10, 10),
          to: const DndPoint(250, 46),
        ),
        containers: containers,
        itemRects: itemRects,
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 20),
      );

      expect(details?.toIndex, 2, reason: 'lower half of task-4 lands after it');
    });

    test('adaptive insertion is independent of where the card was grabbed', () {
      // Same pointer (lower half of task-4), two very different grab offsets.
      // The old active-rect-center rule flipped with the grab; the pointer rule
      // must not.
      SortableMoveDetails? resolve(DndPoint from) {
        return SortableMultiContainer.moveDetailsFor(
          _event(
            activeId: const DndId('task-1'),
            overId: const DndId('task-4'),
            from: from,
            to: const DndPoint(250, 46),
          ),
          containers: containers,
          itemRects: itemRects,
          activeRect: const DndRect(left: 0, top: 0, width: 100, height: 20),
        );
      }

      // Grabbed near the top of the card vs near the bottom: same landing.
      expect(resolve(const DndPoint(10, 2))?.toIndex, 2);
      expect(resolve(const DndPoint(10, 18))?.toIndex, 2);
    });

    test('supports explicit insertion overrides for cross-container moves', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('task-4')),
        containers: containers,
        crossContainerInsertion: SortableMultiInsertionStrategy.beforeOverItem,
      );

      expect(details?.toIndex, 1);
    });
  });

  group('SortableMultiContainer.collisionDetector', () {
    test('prefers item hits over the containing container', () {
      final detector = SortableMultiContainer.collisionDetector(
        containers: () => containers,
      );

      final result = detector(
        DndCollisionInput(
          activeRect: const DndRect(left: 5, top: 35, width: 80, height: 20),
          pointer: const DndPoint(20, 40),
          droppableRects: <DndId, DndRect>{
            const DndId('done'): const DndRect(
              left: 0,
              top: 0,
              width: 200,
              height: 200,
            ),
            const DndId('task-3'): const DndRect(
              left: 0,
              top: 0,
              width: 100,
              height: 20,
            ),
            const DndId('task-4'): const DndRect(
              left: 0,
              top: 30,
              width: 100,
              height: 20,
            ),
          },
        ),
      );

      expect(result.firstOrNull?.id, const DndId('task-4'));
    });

    test('keeps empty-container drops reachable', () {
      final detector = SortableMultiContainer.collisionDetector(
        containers: () => containers,
      );

      final result = detector(
        DndCollisionInput(
          activeRect: const DndRect(left: 400, top: 10, width: 80, height: 20),
          pointer: const DndPoint(430, 30),
          droppableRects: <DndId, DndRect>{
            const DndId('empty'): const DndRect(
              left: 400,
              top: 0,
              width: 180,
              height: 200,
            ),
          },
        ),
      );

      expect(result.firstOrNull?.id, const DndId('empty'));
    });
  });
}

DndDragEndEvent _event({
  required DndId activeId,
  required DndId? overId,
  DndPoint from = DndPoint.zero,
  DndPoint to = DndPoint.zero,
}) {
  return DndDragEndEvent(
    session: DndDragSession(
      activeId: activeId,
      initialPointer: from,
      currentPointer: to,
    ),
    overId: overId,
  );
}
