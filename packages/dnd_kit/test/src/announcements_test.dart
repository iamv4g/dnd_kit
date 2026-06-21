import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('DndAnnouncements', () {
    const announcements = DndAnnouncements();
    const active = DndId('task-1');
    const over = DndId('column-2');

    test('announces drag start', () {
      expect(announcements.onDragStart(active), 'Picked up draggable item task-1.');
    });

    test('announces drag-over target and leaving a target', () {
      expect(
        announcements.onDragOver(active, over),
        'Draggable item task-1 moved over droppable column-2.',
      );
      expect(
        announcements.onDragOver(active, null),
        'Draggable item task-1 is no longer over a drop target.',
      );
    });

    test('announces drop with and without a target', () {
      expect(
        announcements.onDragEnd(active, over),
        'Draggable item task-1 was dropped over droppable column-2.',
      );
      expect(announcements.onDragEnd(active, null), 'Draggable item task-1 was dropped.');
    });

    test('announces cancel', () {
      expect(
        announcements.onDragCancel(active),
        'Dragging draggable item task-1 was cancelled.',
      );
    });

    test('honors custom builders', () {
      final custom = DndAnnouncements(
        onDragStart: (active) => 'lift ${active.value}',
      );
      expect(custom.onDragStart(active), 'lift task-1');
      expect(custom.onDragCancel(active), 'Dragging draggable item task-1 was cancelled.');
    });
  });
}
