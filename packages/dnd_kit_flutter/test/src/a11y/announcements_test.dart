import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndAnnouncements', () {
    const announcements = DndAnnouncements();
    const active = DndId('task-1');
    const over = DndId('column-1');

    test('provides a default drag-start announcement', () {
      expect(announcements.onDragStart(active), 'Picked up draggable item task-1.');
    });

    test('provides default drag-over announcements', () {
      expect(
        announcements.onDragOver(active, over),
        'Draggable item task-1 moved over droppable column-1.',
      );
      expect(
        announcements.onDragOver(active, null),
        'Draggable item task-1 is no longer over a drop target.',
      );
    });

    test('provides default drop announcements', () {
      expect(
        announcements.onDragEnd(active, over),
        'Draggable item task-1 was dropped over droppable column-1.',
      );
      expect(
        announcements.onDragEnd(active, null),
        'Draggable item task-1 was dropped.',
      );
    });

    test('provides a default cancel announcement', () {
      expect(
        announcements.onDragCancel(active),
        'Dragging draggable item task-1 was cancelled.',
      );
    });
  });
}
