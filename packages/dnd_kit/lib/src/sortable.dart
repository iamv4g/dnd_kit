import 'package:meta/meta.dart';

import 'events.dart';
import 'geometry.dart';
import 'id.dart';

/// Called when a sortable item is dropped over another sortable item.
typedef SortableMoveCallback = void Function(SortableMoveDetails details);

/// Details for an application-owned sortable reorder intent.
final class SortableMoveDetails {
  /// Creates sortable move intent details.
  const SortableMoveDetails({
    required this.activeId,
    required this.overId,
    required this.fromContainerId,
    required this.toContainerId,
    required this.fromIndex,
    required this.toIndex,
    this.event,
  });

  /// The sortable item being moved.
  final DndId activeId;

  /// The sortable item the active item was dropped over.
  final DndId overId;

  /// The source container id, when the move is associated with a container.
  final DndId? fromContainerId;

  /// The destination container id, when the move is associated with a container.
  final DndId? toContainerId;

  /// The active item's index in its source container before the move.
  final int fromIndex;

  /// The target index in the destination container.
  final int toIndex;

  /// The lower-level drag end event that produced this move intent.
  final DndDragEndEvent? event;

  @override
  bool operator ==(Object other) {
    return other is SortableMoveDetails &&
        other.activeId == activeId &&
        other.overId == overId &&
        other.fromContainerId == fromContainerId &&
        other.toContainerId == toContainerId &&
        other.fromIndex == fromIndex &&
        other.toIndex == toIndex &&
        other.event == event;
  }

  @override
  int get hashCode {
    return Object.hash(
      activeId,
      overId,
      fromContainerId,
      toContainerId,
      fromIndex,
      toIndex,
      event,
    );
  }

  @override
  String toString() {
    return 'SortableMoveDetails(activeId: $activeId, overId: $overId, '
        'fromContainerId: $fromContainerId, toContainerId: $toContainerId, '
        'fromIndex: $fromIndex, toIndex: $toIndex, '
        'event: $event)';
  }
}

/// Computes sortable move intent for a drag end.
typedef SortableStrategy = SortableMoveDetails? Function(SortableStrategyInput input);

/// Input passed to a [SortableStrategy].
@immutable
final class SortableStrategyInput {
  /// Creates sortable strategy input.
  SortableStrategyInput({
    required this.activeId,
    required this.overId,
    required Iterable<DndId> itemIds,
    required Map<DndId, DndRect> itemRects,
    required this.fromIndex,
    required this.fromContainerId,
    required this.toContainerId,
    required this.event,
    this.activeRect,
    this.activeTranslatedRect,
  })  : itemIds = List<DndId>.unmodifiable(itemIds),
        itemRects = Map<DndId, DndRect>.unmodifiable(itemRects);

  /// The sortable item being moved.
  final DndId activeId;

  /// The sortable item currently under the active drag, when one exists.
  final DndId? overId;

  /// The application-owned item order.
  final List<DndId> itemIds;

  /// Measured item rectangles keyed by sortable item id.
  final Map<DndId, DndRect> itemRects;

  /// The active item's index before the move.
  final int fromIndex;

  /// The source container id, when the move is associated with a container.
  final DndId? fromContainerId;

  /// The destination container id, when the move is associated with a container.
  final DndId? toContainerId;

  /// The lower-level drag end event that produced this strategy input.
  final DndDragEndEvent event;

  /// The measured active rectangle before translation, when known.
  final DndRect? activeRect;

  /// The measured active rectangle after drag translation, when known.
  final DndRect? activeTranslatedRect;

  /// Builds the previous drop-over move intent for fallback strategies.
  SortableMoveDetails? fallbackMoveDetails({int? toIndex}) {
    final overId = this.overId;
    if (overId == null || overId == activeId || fromIndex < 0) {
      return null;
    }

    final fallbackIndex = itemIds.indexOf(overId);
    if (fallbackIndex < 0) {
      return null;
    }

    return SortableMoveDetails(
      activeId: activeId,
      overId: overId,
      fromContainerId: fromContainerId,
      toContainerId: toContainerId,
      fromIndex: fromIndex,
      toIndex: toIndex ?? fallbackIndex,
      event: event,
    );
  }
}

/// Built-in sortable strategies.
abstract final class SortableStrategies {
  /// Computes same-container vertical list movement from measured item centers.
  ///
  /// Works with a partially-measured set: in a lazy `ListView.builder` only the
  /// visible items are measured, so off-screen items are skipped and the
  /// insertion index is mapped back into full list space.
  static SortableMoveDetails? verticalList(SortableStrategyInput input) {
    final fallback = input.fallbackMoveDetails();
    if (fallback == null) {
      return null;
    }

    final activeTranslatedRect = input.activeTranslatedRect;
    if (activeTranslatedRect == null) {
      return fallback;
    }

    if (!_overMeasured(input)) {
      return fallback;
    }

    final measuredItems = _measuredItems(input);
    if (measuredItems.isEmpty) {
      return fallback;
    }

    if (!_hasVerticalSeparation(
      measuredItems,
      activeCenterY: activeTranslatedRect.center.y,
    )) {
      return fallback;
    }

    measuredItems.sort(_compareVerticalItems);
    final boundary = _verticalInsertionIndex(
      activeCenterY: activeTranslatedRect.center.y,
      measuredItems: measuredItems,
    );
    final toIndex = _resolveToIndex(measuredItems, boundary, input.fromIndex);

    if (toIndex == input.fromIndex) {
      return null;
    }

    return input.fallbackMoveDetails(toIndex: toIndex);
  }

  /// Computes same-container horizontal list movement from measured item centers.
  ///
  /// Supports a partially-measured (visible-only) set the same way as
  /// [verticalList].
  static SortableMoveDetails? horizontalList(SortableStrategyInput input) {
    final fallback = input.fallbackMoveDetails();
    if (fallback == null) {
      return null;
    }

    final activeTranslatedRect = input.activeTranslatedRect;
    if (activeTranslatedRect == null) {
      return fallback;
    }

    if (!_overMeasured(input)) {
      return fallback;
    }

    final measuredItems = _measuredItems(input);
    if (measuredItems.isEmpty) {
      return fallback;
    }

    if (!_hasHorizontalSeparation(
      measuredItems,
      activeCenterX: activeTranslatedRect.center.x,
    )) {
      return fallback;
    }

    measuredItems.sort(_compareHorizontalItems);
    final boundary = _horizontalInsertionIndex(
      activeCenterX: activeTranslatedRect.center.x,
      measuredItems: measuredItems,
    );
    final toIndex = _resolveToIndex(measuredItems, boundary, input.fromIndex);

    if (toIndex == input.fromIndex) {
      return null;
    }

    return input.fallbackMoveDetails(toIndex: toIndex);
  }

  /// Computes same-container grid movement from measured item centers.
  ///
  /// Supports a partially-measured (visible-only) set the same way as
  /// [verticalList].
  static SortableMoveDetails? grid(SortableStrategyInput input) {
    final fallback = input.fallbackMoveDetails();
    if (fallback == null) {
      return null;
    }

    final activeTranslatedRect = input.activeTranslatedRect;
    if (activeTranslatedRect == null) {
      return fallback;
    }

    if (!_overMeasured(input)) {
      return fallback;
    }

    final measuredItems = _measuredItems(input);
    if (measuredItems.isEmpty) {
      return fallback;
    }

    final activeCenter = activeTranslatedRect.center;
    if (!_hasVerticalSeparation(measuredItems, activeCenterY: activeCenter.y) ||
        !_hasHorizontalSeparation(measuredItems, activeCenterX: activeCenter.x)) {
      return fallback;
    }

    measuredItems.sort(_compareGridItems);
    final boundary = _gridInsertionIndex(
      activeCenter: activeCenter,
      measuredItems: measuredItems,
    );
    final toIndex = _resolveToIndex(measuredItems, boundary, input.fromIndex);

    if (toIndex == input.fromIndex) {
      return null;
    }

    return input.fallbackMoveDetails(toIndex: toIndex);
  }

  /// Whether the drop-over target itself has a measured rect.
  ///
  /// In a lazy list the over target is always a built (visible) item, so this
  /// is normally true; when it is not, the geometry cannot anchor reliably and
  /// strategies fall back to the drop-over index.
  static bool _overMeasured(SortableStrategyInput input) {
    final overId = input.overId;
    return overId != null && input.itemRects[overId] != null;
  }

  /// Builds the measured, non-active items with their full list index.
  ///
  /// Unmeasured (off-screen) items are skipped instead of forcing a fallback.
  static List<_MeasuredSortableItem> _measuredItems(SortableStrategyInput input) {
    final measuredItems = <_MeasuredSortableItem>[];
    for (var index = 0; index < input.itemIds.length; index += 1) {
      final id = input.itemIds[index];
      if (id == input.activeId) {
        continue;
      }

      final rect = input.itemRects[id];
      if (rect == null) {
        continue;
      }

      measuredItems.add(_MeasuredSortableItem(id: id, index: index, rect: rect));
    }

    return measuredItems;
  }

  /// Maps an insertion [boundary] in measured-subset space to a full list index.
  ///
  /// [boundary] is the count of measured items ordered before the active center.
  /// The active is inserted before the first measured item after it (or after
  /// the last measured item), then the index is adjusted for the active item's
  /// own removal from [fromIndex].
  static int _resolveToIndex(
    List<_MeasuredSortableItem> sortedMeasured,
    int boundary,
    int fromIndex,
  ) {
    final insertBeforeIndex = boundary < sortedMeasured.length
        ? sortedMeasured[boundary].index
        : sortedMeasured.last.index + 1;

    return insertBeforeIndex - (fromIndex < insertBeforeIndex ? 1 : 0);
  }
}

final class _MeasuredSortableItem {
  const _MeasuredSortableItem({
    required this.id,
    required this.index,
    required this.rect,
  });

  final DndId id;

  /// The item's index in the full, application-owned item order.
  final int index;
  final DndRect rect;
}

bool _hasVerticalSeparation(
  List<_MeasuredSortableItem> measuredItems, {
  required double activeCenterY,
}) {
  return measuredItems.any((item) => item.rect.center.y != activeCenterY);
}

bool _hasHorizontalSeparation(
  List<_MeasuredSortableItem> measuredItems, {
  required double activeCenterX,
}) {
  return measuredItems.any((item) => item.rect.center.x != activeCenterX);
}

int _verticalInsertionIndex({
  required double activeCenterY,
  required List<_MeasuredSortableItem> measuredItems,
}) {
  var index = 0;
  for (final item in measuredItems) {
    if (activeCenterY > item.rect.center.y) {
      index += 1;
      continue;
    }

    break;
  }

  return index;
}

int _horizontalInsertionIndex({
  required double activeCenterX,
  required List<_MeasuredSortableItem> measuredItems,
}) {
  var index = 0;
  for (final item in measuredItems) {
    if (activeCenterX > item.rect.center.x) {
      index += 1;
      continue;
    }

    break;
  }

  return index;
}

int _gridInsertionIndex({
  required DndPoint activeCenter,
  required List<_MeasuredSortableItem> measuredItems,
}) {
  var index = 0;
  for (final item in measuredItems) {
    final itemCenter = item.rect.center;
    final rowComparison = activeCenter.y.compareTo(itemCenter.y);
    if (rowComparison > 0 || rowComparison == 0 && activeCenter.x > itemCenter.x) {
      index += 1;
      continue;
    }

    break;
  }

  return index;
}

int _compareVerticalItems(_MeasuredSortableItem a, _MeasuredSortableItem b) {
  final centerComparison = a.rect.center.y.compareTo(b.rect.center.y);
  if (centerComparison != 0) {
    return centerComparison;
  }

  final topComparison = a.rect.top.compareTo(b.rect.top);
  if (topComparison != 0) {
    return topComparison;
  }

  return a.id.value.compareTo(b.id.value);
}

int _compareHorizontalItems(_MeasuredSortableItem a, _MeasuredSortableItem b) {
  final centerComparison = a.rect.center.x.compareTo(b.rect.center.x);
  if (centerComparison != 0) {
    return centerComparison;
  }

  final leftComparison = a.rect.left.compareTo(b.rect.left);
  if (leftComparison != 0) {
    return leftComparison;
  }

  return a.id.value.compareTo(b.id.value);
}

int _compareGridItems(_MeasuredSortableItem a, _MeasuredSortableItem b) {
  final rowComparison = a.rect.center.y.compareTo(b.rect.center.y);
  if (rowComparison != 0) {
    return rowComparison;
  }

  final columnComparison = a.rect.center.x.compareTo(b.rect.center.x);
  if (columnComparison != 0) {
    return columnComparison;
  }

  final topComparison = a.rect.top.compareTo(b.rect.top);
  if (topComparison != 0) {
    return topComparison;
  }

  final leftComparison = a.rect.left.compareTo(b.rect.left);
  if (leftComparison != 0) {
    return leftComparison;
  }

  return a.id.value.compareTo(b.id.value);
}
