import 'package:dnd_kit_core/dnd_kit_core.dart';

/// Called when a sortable item is dropped over another sortable item.
typedef SortableMoveCallback = void Function(SortableMoveDetails details);

/// Details for an application-owned sortable reorder intent.
final class SortableMoveDetails {
  /// Creates sortable move intent details.
  const SortableMoveDetails({
    required this.activeId,
    required this.overId,
    required this.oldIndex,
    required this.newIndex,
    this.containerId,
    this.event,
  });

  /// The sortable item being moved.
  final DndId activeId;

  /// The sortable item the active item was dropped over.
  final DndId overId;

  /// The active item's index in the scope's item order before the move.
  final int oldIndex;

  /// The target index in the scope's item order.
  final int newIndex;

  /// Optional sortable container id for future multi-container APIs.
  final DndId? containerId;

  /// The lower-level drag end event that produced this move intent.
  final DndDragEndEvent? event;

  @override
  bool operator ==(Object other) {
    return other is SortableMoveDetails &&
        other.activeId == activeId &&
        other.overId == overId &&
        other.oldIndex == oldIndex &&
        other.newIndex == newIndex &&
        other.containerId == containerId &&
        other.event == event;
  }

  @override
  int get hashCode {
    return Object.hash(
      activeId,
      overId,
      oldIndex,
      newIndex,
      containerId,
      event,
    );
  }

  @override
  String toString() {
    return 'SortableMoveDetails(activeId: $activeId, overId: $overId, '
        'oldIndex: $oldIndex, newIndex: $newIndex, containerId: $containerId, '
        'event: $event)';
  }
}
