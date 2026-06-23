import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
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
        containers: <SortableContainer>[
          SortableContainer(
            id: const DndId('todo'),
            itemIds: const <DndId>[DndId('task-1'), DndId('task-2')],
          ),
          SortableContainer(
            id: const DndId('done'),
            itemIds: const <DndId>[DndId('task-3'), DndId('task-4')],
          ),
        ],
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
        containers: <SortableContainer>[
          SortableContainer(
            id: const DndId('todo'),
            itemIds: const <DndId>[DndId('task-1'), DndId('task-2')],
          ),
          SortableContainer(
            id: const DndId('done'),
            itemIds: const <DndId>[DndId('task-3')],
          ),
        ],
      );

      expect(details?.fromContainerId, const DndId('todo'));
      expect(details?.toContainerId, const DndId('done'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 1);
    });

    test('reports same-container identifiers with from and to fields', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('task-2')),
        containers: <SortableContainer>[
          SortableContainer(
            id: const DndId('todo'),
            itemIds: const <DndId>[
              DndId('task-1'),
              DndId('task-2'),
              DndId('task-3'),
            ],
          ),
        ],
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
          _event(activeId: const DndId('task-1'), overId: const DndId('missing')),
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
  });
}

DndDragEndEvent _event({
  required DndId activeId,
  required DndId? overId,
}) {
  return DndDragEndEvent(
    session: DndDragSession.start(
      activeId: activeId,
      initialPointer: DndPoint.zero,
    ),
    overId: overId,
  );
}
