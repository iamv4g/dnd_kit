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

/// Computes live per-item displacement offsets during an active sortable drag.
///
/// Returns an offset for every item that should shift out of the active
/// item's way at the current drag position; items absent from the map rest
/// at their measured position.
typedef SortableDisplacementStrategy = Map<DndId, DndPoint> Function(
  SortableDisplacementInput input,
);

/// Input passed to a [SortableDisplacementStrategy].
@immutable
final class SortableDisplacementInput {
  /// Creates sortable displacement input.
  SortableDisplacementInput({
    required this.activeId,
    required Iterable<DndId> itemIds,
    required Map<DndId, DndRect> itemRects,
    required this.fromIndex,
    this.activeRect,
    this.activeTranslatedRect,
  })  : itemIds = List<DndId>.unmodifiable(itemIds),
        itemRects = Map<DndId, DndRect>.unmodifiable(itemRects);

  /// The sortable item being moved.
  final DndId activeId;

  /// The application-owned item order.
  final List<DndId> itemIds;

  /// Measured item rectangles keyed by sortable item id.
  final Map<DndId, DndRect> itemRects;

  /// The active item's index before the move.
  final int fromIndex;

  /// The measured active rectangle before translation, when known.
  final DndRect? activeRect;

  /// The measured active rectangle after drag translation, when known.
  final DndRect? activeTranslatedRect;
}

/// Built-in sortable displacement strategies.
///
/// Displacement is the live counterpart of a [SortableStrategy]: the strategy
/// computes the reorder intent at drag end, while the displacement strategy
/// computes which sibling items should visually shift out of the way at the
/// current drag position. Both share the same insertion-index math, so the
/// preview always matches the committed move.
abstract final class SortableDisplacements {
  /// Live vertical-list displacement.
  ///
  /// Sibling items between the active item's original slot and its current
  /// insertion index shift into their neighbour's measured slot. Works with a
  /// partially-measured set the same way as [SortableStrategies.verticalList]:
  /// items without a measured neighbour rest in place.
  static Map<DndId, DndPoint> verticalList(SortableDisplacementInput input) {
    return _listDisplacement(input, vertical: true);
  }

  /// Live horizontal-list displacement.
  ///
  /// The horizontal counterpart of [verticalList].
  static Map<DndId, DndPoint> horizontalList(SortableDisplacementInput input) {
    return _listDisplacement(input, vertical: false);
  }

  static Map<DndId, DndPoint> _listDisplacement(
    SortableDisplacementInput input, {
    required bool vertical,
  }) {
    final activeRect = input.activeRect;
    final activeTranslatedRect = input.activeTranslatedRect;
    if (activeRect == null ||
        activeTranslatedRect == null ||
        input.fromIndex < 0 ||
        input.fromIndex >= input.itemIds.length) {
      return const <DndId, DndPoint>{};
    }

    final measuredItems = _collectMeasuredItems(
      itemIds: input.itemIds,
      itemRects: input.itemRects,
      activeId: input.activeId,
    );
    if (measuredItems.isEmpty) {
      return const <DndId, DndPoint>{};
    }

    final activeCenter = activeTranslatedRect.center;
    final separated = vertical
        ? _hasVerticalSeparation(measuredItems, activeCenterY: activeCenter.y)
        : _hasHorizontalSeparation(measuredItems, activeCenterX: activeCenter.x);
    if (!separated) {
      return const <DndId, DndPoint>{};
    }

    measuredItems.sort(vertical ? _compareVerticalItems : _compareHorizontalItems);
    final boundary = vertical
        ? _verticalInsertionIndex(
            activeCenterY: activeCenter.y,
            measuredItems: measuredItems,
          )
        : _horizontalInsertionIndex(
            activeCenterX: activeCenter.x,
            measuredItems: measuredItems,
          );
    final toIndex = SortableStrategies._resolveToIndex(
      measuredItems,
      boundary,
      input.fromIndex,
    );
    if (toIndex == input.fromIndex) {
      return const <DndId, DndPoint>{};
    }

    DndRect? rectAt(int index) {
      if (index == input.fromIndex) {
        return activeRect;
      }
      if (index < 0 || index >= input.itemIds.length) {
        return null;
      }

      return input.itemRects[input.itemIds[index]];
    }

    double mainStart(DndRect rect) => vertical ? rect.top : rect.left;

    final displacements = <DndId, DndPoint>{};
    void displaceInto(int index, int neighborIndex) {
      final own = rectAt(index);
      final neighbor = rectAt(neighborIndex);
      if (own == null || neighbor == null) {
        return;
      }

      final delta = mainStart(neighbor) - mainStart(own);
      displacements[input.itemIds[index]] =
          vertical ? DndPoint(0, delta) : DndPoint(delta, 0);
    }

    if (input.fromIndex < toIndex) {
      for (var index = input.fromIndex + 1; index <= toIndex; index += 1) {
        displaceInto(index, index - 1);
      }
    } else {
      for (var index = toIndex; index < input.fromIndex; index += 1) {
        displaceInto(index, index + 1);
      }
    }

    return Map<DndId, DndPoint>.unmodifiable(displacements);
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
    return _collectMeasuredItems(
      itemIds: input.itemIds,
      itemRects: input.itemRects,
      activeId: input.activeId,
    );
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

/// Builds the measured, non-active items with their full list index.
///
/// Shared by [SortableStrategies] and [SortableDisplacements] so the drag-end
/// intent and the live displacement preview see the same measured set.
List<_MeasuredSortableItem> _collectMeasuredItems({
  required List<DndId> itemIds,
  required Map<DndId, DndRect> itemRects,
  required DndId activeId,
}) {
  final measuredItems = <_MeasuredSortableItem>[];
  for (var index = 0; index < itemIds.length; index += 1) {
    final id = itemIds[index];
    if (id == activeId) {
      continue;
    }

    final rect = itemRects[id];
    if (rect == null) {
      continue;
    }

    measuredItems.add(_MeasuredSortableItem(id: id, index: index, rect: rect));
  }

  return measuredItems;
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
