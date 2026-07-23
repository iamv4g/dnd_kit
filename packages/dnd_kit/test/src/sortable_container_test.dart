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

    test('resolves the gap between two cards to the nearest card', () {
      final detector = SortableMultiContainer.collisionDetector(
        containers: () => containers,
      );

      // task-3 at y 0-20, task-4 at y 30-50; pointer at y 26 sits in the gap
      // between them, inside the 'done' column but over no card. It is nearer
      // task-4 (center 40) than task-3 (center 10).
      final result = detector(
        DndCollisionInput(
          activeRect: const DndRect(left: 5, top: 20, width: 80, height: 20),
          pointer: const DndPoint(20, 26),
          droppableRects: <DndId, DndRect>{
            const DndId('done'): const DndRect(left: 0, top: 0, width: 200, height: 200),
            const DndId('task-3'): const DndRect(left: 0, top: 0, width: 100, height: 20),
            const DndId('task-4'): const DndRect(left: 0, top: 30, width: 100, height: 20),
          },
        ),
      );

      expect(
        result.firstOrNull?.id,
        const DndId('task-4'),
        reason: 'the inter-card gap resolves to the nearest card, not the column',
      );
    });

    test('resolves trailing space below the last card to the last card', () {
      final detector = SortableMultiContainer.collisionDetector(
        containers: () => containers,
      );

      // Pointer well below both cards but still inside the tall 'done' column.
      final result = detector(
        DndCollisionInput(
          activeRect: const DndRect(left: 5, top: 100, width: 80, height: 20),
          pointer: const DndPoint(20, 150),
          droppableRects: <DndId, DndRect>{
            const DndId('done'): const DndRect(left: 0, top: 0, width: 200, height: 200),
            const DndId('task-3'): const DndRect(left: 0, top: 0, width: 100, height: 20),
            const DndId('task-4'): const DndRect(left: 0, top: 30, width: 100, height: 20),
          },
        ),
      );

      expect(result.firstOrNull?.id, const DndId('task-4'));
    });
  });

  group('SortableMultiContainer.resolveMove (preview)', () {
    // task-1's original slot is (0,0,100,20). The active item is excluded from
    // the droppable set, so a pointer still resting in that slot resolves over
    // the neighbour task-2 — but nothing should move until the pointer leaves.
    SortableMultiMoveInput previewOver(DndPoint pointer) {
      return SortableMultiMoveInput(
        context: SortableDragContext.preview(
          session: DndDragSession(
            activeId: const DndId('task-1'),
            initialPointer: const DndPoint(10, 10),
            currentPointer: pointer,
          ),
          overId: const DndId('task-2'),
        ),
        containers: containers,
        itemRects: itemRects,
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 20),
        strategy: SortableStrategies.dropOnOver,
      );
    }

    test('reports no move while the pointer is still inside the active slot', () {
      expect(
        SortableMultiContainer.resolveMove(previewOver(const DndPoint(10, 12))),
        isNull,
        reason: 'picking an item up must not shift its neighbours',
      );
    });

    test('reports the move once the pointer leaves the active slot', () {
      final details = SortableMultiContainer.resolveMove(previewOver(const DndPoint(10, 40)));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 1);
    });

    test('a drop still inside the active slot is a no-op', () {
      // Press-hold to drag, release without moving: the drop point is still in
      // task-1's own slot, so committing must not swap it with the neighbour.
      final input = SortableMultiMoveInput(
        context: SortableDragContext.commit(
          DndDragEndEvent(
            session: DndDragSession(
              activeId: const DndId('task-1'),
              initialPointer: const DndPoint(10, 10),
              currentPointer: const DndPoint(10, 12),
            ),
            overId: const DndId('task-2'),
          ),
        ),
        containers: containers,
        itemRects: itemRects,
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 20),
        strategy: SortableStrategies.dropOnOver,
      );
      expect(SortableMultiContainer.resolveMove(input), isNull);
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
