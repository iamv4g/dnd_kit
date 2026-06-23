// ignore_for_file: experimental_member_use

import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:dnd_kit_flutter/src/sortable/sortable_container.dart' as compat;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sortable multi-container compatibility', () {
    test('barrel import still exposes the shared helper contract', () {
      final details = SortableMultiContainer.moveDetailsFor(
        _event(activeId: const DndId('task-1'), overId: const DndId('done')),
        containers: <SortableContainer>[
          SortableContainer(
            id: const DndId('todo'),
            itemIds: const <DndId>[DndId('task-1')],
          ),
          SortableContainer(
            id: const DndId('done'),
            itemIds: const <DndId>[DndId('task-2')],
          ),
        ],
      );

      expect(details?.fromContainerId, const DndId('todo'));
      expect(details?.toContainerId, const DndId('done'));
      expect(details?.toIndex, 1);
    });

    test('source shim re-exports the shared helper symbols', () {
      final container = compat.SortableContainer(
        id: const DndId('todo'),
        itemIds: const <DndId>[DndId('task-1')],
      );

      expect(container.id, const DndId('todo'));
      expect(container.itemIds, const <DndId>[DndId('task-1')]);
      expect(
        compat.SortableMultiContainer.moveDetailsFor(
          _event(activeId: const DndId('task-1'), overId: const DndId('done')),
          containers: <compat.SortableContainer>[
            container,
            compat.SortableContainer(
              id: const DndId('done'),
              itemIds: const <DndId>[],
            ),
          ],
        )?.toIndex,
        0,
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
