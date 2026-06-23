// ignore_for_file: experimental_member_use

import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:test/test.dart';

void main() {
  group('SortableMultiContainer via dnd_kit_jaspr', () {
    test('is reachable from the Jaspr barrel and reports cross-container intent', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('task-3')),
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
      expect(details?.toIndex, 0);
    });

    test('reports container-end moves through the shared helper', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('done')),
        containers: <SortableContainer>[
          SortableContainer(
            id: const DndId('todo'),
            itemIds: const <DndId>[DndId('task-1')],
          ),
          SortableContainer(
            id: const DndId('done'),
            itemIds: const <DndId>[DndId('task-3'), DndId('task-4')],
          ),
        ],
      );

      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 2);
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
