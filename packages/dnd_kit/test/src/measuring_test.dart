import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('DndMeasuringRegistry', () {
    test('tracks missing, dirty, clean, and removed draggable status', () {
      final measuring = DndMeasuringRegistry();
      const id = DndId('task-1');
      const rect = DndRect(left: 10, top: 20, width: 30, height: 40);

      expect(measuring.draggableStatus(id), DndMeasurementStatus.missing);

      measuring.markDraggableDirty(id);
      expect(measuring.draggableStatus(id), DndMeasurementStatus.dirty);
      expect(measuring.draggableRect(id), isNull);

      measuring.updateDraggableRect(id, rect);
      expect(measuring.draggableStatus(id), DndMeasurementStatus.clean);
      expect(measuring.draggableRect(id), rect);

      expect(measuring.removeDraggableRect(id), rect);
      expect(measuring.draggableStatus(id), DndMeasurementStatus.removed);
      expect(measuring.draggableRect(id), isNull);
    });

    test('refreshes only dirty measurements with registered measurers', () {
      final measuring = DndMeasuringRegistry();
      const cleanId = DndId('clean');
      const dirtyId = DndId('dirty');
      var cleanMeasureCount = 0;
      var dirtyMeasureCount = 0;

      measuring.markDroppableDirty(
        cleanId,
        measure: () {
          cleanMeasureCount += 1;
          return const DndRect(left: 0, top: 0, width: 10, height: 10);
        },
      );
      measuring.markDroppableDirty(
        dirtyId,
        measure: () {
          dirtyMeasureCount += 1;
          return const DndRect(left: 20, top: 0, width: 10, height: 10);
        },
      );

      measuring.refreshDirty();
      expect(cleanMeasureCount, 1);
      expect(dirtyMeasureCount, 1);
      expect(measuring.droppableStatus(cleanId), DndMeasurementStatus.clean);
      expect(measuring.droppableStatus(dirtyId), DndMeasurementStatus.clean);

      measuring.markDroppableDirty(dirtyId);
      measuring.refreshDirty();

      expect(cleanMeasureCount, 1);
      expect(dirtyMeasureCount, 2);
      expect(
          measuring.droppableRect(dirtyId), const DndRect(left: 20, top: 0, width: 10, height: 10));
    });

    test('markAllDirty re-measures every draggable and droppable on next refresh', () {
      final measuring = DndMeasuringRegistry();
      const draggableId = DndId('drag');
      const droppableId = DndId('drop');
      var draggableMeasureCount = 0;
      var droppableMeasureCount = 0;

      measuring.markDraggableDirty(
        draggableId,
        measure: () {
          draggableMeasureCount += 1;
          return DndRect(left: draggableMeasureCount.toDouble(), top: 0, width: 10, height: 10);
        },
      );
      measuring.markDroppableDirty(
        droppableId,
        measure: () {
          droppableMeasureCount += 1;
          return DndRect(left: 0, top: droppableMeasureCount.toDouble(), width: 10, height: 10);
        },
      );

      measuring.refreshDirty();
      expect(draggableMeasureCount, 1);
      expect(droppableMeasureCount, 1);
      expect(measuring.draggableStatus(draggableId), DndMeasurementStatus.clean);
      expect(measuring.droppableStatus(droppableId), DndMeasurementStatus.clean);

      // Without markAllDirty, refresh is a no-op for clean entries.
      measuring.refreshDirty();
      expect(draggableMeasureCount, 1);
      expect(droppableMeasureCount, 1);

      // markAllDirty forces both to re-measure on the next refresh.
      measuring.markAllDirty();
      expect(measuring.draggableStatus(draggableId), DndMeasurementStatus.dirty);
      expect(measuring.droppableStatus(droppableId), DndMeasurementStatus.dirty);

      measuring.refreshDirty();
      expect(draggableMeasureCount, 2);
      expect(droppableMeasureCount, 2);
      expect(measuring.draggableRect(draggableId)?.left, 2);
      expect(measuring.droppableRect(droppableId)?.top, 2);
    });
  });
}
