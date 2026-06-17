import 'package:dnd_kit/dnd_kit.dart';
import 'package:meta/meta.dart';

/// Experimental sortable container metadata for multi-container sorting.
///
/// Applications own the actual container and item collections. This model only
/// describes the current order so dnd_kit can report move intent.
@experimental
@immutable
final class SortableContainer {
  /// Creates experimental sortable container metadata.
  SortableContainer({
    required this.id,
    required Iterable<DndId> itemIds,
  }) : itemIds = List<DndId>.unmodifiable(itemIds);

  /// The stable container id.
  final DndId id;

  /// The application-owned item order inside this container.
  final List<DndId> itemIds;

  /// Returns the current index for [itemId], or -1 when absent.
  int indexOf(DndId itemId) => itemIds.indexOf(itemId);

  /// Whether this container contains [itemId].
  bool contains(DndId itemId) => indexOf(itemId) >= 0;

  @override
  bool operator ==(Object other) {
    return other is SortableContainer && other.id == id && _listEquals(other.itemIds, itemIds);
  }

  @override
  int get hashCode => Object.hash(id, Object.hashAll(itemIds));

  @override
  String toString() {
    return 'SortableContainer(id: $id, itemIds: $itemIds)';
  }
}

/// Experimental helpers for computing multi-container sortable move intent.
@experimental
abstract final class SortableMultiContainer {
  /// Builds move intent details for a drag ending over an item or container.
  ///
  /// If the event's `overId` is a container id, the move targets the end of
  /// that container. If `overId` is an item id, the move targets that item's
  /// index in its container.
  static SortableMoveDetails? moveDetailsFor(
    DndDragEndEvent event, {
    required Iterable<SortableContainer> containers,
  }) {
    final overId = event.overId;
    if (overId == null || overId == event.activeId) {
      return null;
    }

    final containerList = List<SortableContainer>.unmodifiable(containers);
    final fromContainer = _containerContaining(
      containerList,
      event.activeId,
    );
    final target = _targetFor(containerList, overId);
    if (fromContainer == null || target == null) {
      return null;
    }

    final fromIndex = fromContainer.indexOf(event.activeId);
    if (fromIndex < 0) {
      return null;
    }

    final toContainer = target.container;
    var toIndex = target.index;
    if (fromContainer.id == toContainer.id && target.overContainer) {
      toIndex = (toIndex - 1).clamp(0, toContainer.itemIds.length).toInt();
    }

    if (fromContainer.id == toContainer.id && fromIndex == toIndex) {
      return null;
    }

    return SortableMoveDetails(
      activeId: event.activeId,
      overId: overId,
      fromContainerId: fromContainer.id,
      toContainerId: toContainer.id,
      fromIndex: fromIndex,
      toIndex: toIndex,
      event: event,
    );
  }

  static SortableContainer? _containerContaining(
    List<SortableContainer> containers,
    DndId itemId,
  ) {
    for (final container in containers) {
      if (container.contains(itemId)) {
        return container;
      }
    }
    return null;
  }

  static _SortableTarget? _targetFor(
    List<SortableContainer> containers,
    DndId overId,
  ) {
    for (final container in containers) {
      if (container.id == overId) {
        return _SortableTarget(
          container: container,
          index: container.itemIds.length,
          overContainer: true,
        );
      }

      final itemIndex = container.indexOf(overId);
      if (itemIndex >= 0) {
        return _SortableTarget(
          container: container,
          index: itemIndex,
          overContainer: false,
        );
      }
    }
    return null;
  }
}

bool _listEquals(List<DndId> a, List<DndId> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

final class _SortableTarget {
  const _SortableTarget({
    required this.container,
    required this.index,
    required this.overContainer,
  });

  final SortableContainer container;
  final int index;
  final bool overContainer;
}
