import 'package:meta/meta.dart';

import 'geometry.dart';
import 'id.dart';
import 'sortable_container.dart';

/// Computes how far each non-active sortable item should move while a drag is
/// in progress.
///
/// This is the fourth member of the plug-in family, alongside
/// `DndCollisionDetector`, `DndModifier`, and `SortableStrategy`. The symmetry
/// with modifiers is deliberate: a `DndModifier` transforms the **active**
/// item's transform, while a resolver here transforms the **other** items'.
///
/// Resolvers are pure: they read the input and return offsets. They never
/// measure anything and never mutate state.
///
/// The returned offsets are output only. Feeding them back into measurement or
/// collision would create a shift → measure → collide → shift loop; the
/// adapters avoid this by handing the offset to the item builder, which sits
/// below the measured node, so applying it cannot change a measured rectangle.
typedef SortableOffsetResolver = Map<DndId, DndPoint> Function(SortableOffsetInput input);

/// Input passed to a [SortableOffsetResolver].
@immutable
final class SortableOffsetInput {
  /// Creates offset resolver input.
  SortableOffsetInput({
    required this.activeId,
    required Iterable<DndId> itemIds,
    required Map<DndId, DndRect> itemRects,
    required this.fromIndex,
    required this.toIndex,
  })  : itemIds = List<DndId>.unmodifiable(itemIds),
        itemRects = Map<DndId, DndRect>.unmodifiable(itemRects);

  /// The item being dragged.
  final DndId activeId;

  /// The application-owned item order, before the move.
  final List<DndId> itemIds;

  /// Measured item rectangles keyed by item id.
  ///
  /// A lazy list only measures visible items, so this may be partial.
  final Map<DndId, DndRect> itemRects;

  /// The active item's index before the move.
  final int fromIndex;

  /// The index the active item would land at, in remove-then-insert space.
  ///
  /// This is [SortableMoveDetails.toIndex] from the live preview, so it means
  /// the same thing the committed move will: the index to insert at *after*
  /// the active item has been removed from [itemIds].
  final int toIndex;

  /// The measured rectangle of the item being dragged, when known.
  DndRect? get activeRect => itemRects[activeId];
}

/// Built-in sortable offset resolvers.
abstract final class SortableOffsets {
  /// Moves nothing. The default, and the behavior before offsets existed.
  static Map<DndId, DndPoint> none(SortableOffsetInput input) => const <DndId, DndPoint>{};

  /// Shifts the items a vertical-list move displaces, along the y axis.
  ///
  /// Every displaced item moves by the dragged item's height plus the list's
  /// gap, which is what opens a gap the size of the dragged item exactly where
  /// it will land.
  static Map<DndId, DndPoint> verticalList(SortableOffsetInput input) {
    return _resolve(input, vertical: true);
  }

  /// Shifts the items a horizontal-list move displaces, along the x axis.
  ///
  /// The horizontal mirror of [verticalList].
  static Map<DndId, DndPoint> horizontalList(SortableOffsetInput input) {
    return _resolve(input, vertical: false);
  }

  static Map<DndId, DndPoint> _resolve(SortableOffsetInput input, {required bool vertical}) {
    final fromIndex = input.fromIndex;
    final toIndex = input.toIndex;
    if (fromIndex == toIndex || fromIndex < 0 || toIndex < 0) {
      return const <DndId, DndPoint>{};
    }

    // The dragged item's extent sets how far everything else moves, so without
    // it there is nothing to compute — guessing would misplace every item.
    final activeRect = input.activeRect;
    if (activeRect == null) {
      return const <DndId, DndPoint>{};
    }

    final itemIds = input.itemIds;
    final lastIndex = itemIds.length - 1;
    if (fromIndex > lastIndex || toIndex > lastIndex) {
      return const <DndId, DndPoint>{};
    }

    final extent = vertical ? activeRect.height : activeRect.width;
    final distance = extent + _gapOf(itemIds, input.itemRects, vertical: vertical);

    // Moving down displaces the items between the old and new slot upward;
    // moving up displaces them downward.
    final movingForward = toIndex > fromIndex;
    final first = movingForward ? fromIndex + 1 : toIndex;
    final last = movingForward ? toIndex : fromIndex - 1;
    final shift = movingForward ? -distance : distance;

    final offsets = <DndId, DndPoint>{};
    for (var index = first; index <= last; index += 1) {
      final id = itemIds[index];
      if (id == input.activeId) {
        continue;
      }

      // A displaced item moves by the dragged item's extent regardless of its
      // own size, so an unmeasured (off-screen) item still gets a correct
      // offset for the moment it scrolls into view.
      offsets[id] = vertical ? DndPoint(0, shift) : DndPoint(shift, 0);
    }

    return Map<DndId, DndPoint>.unmodifiable(offsets);
  }

  /// The spacing between two consecutive items, or zero when it cannot be read.
  ///
  /// Taken from the first consecutive pair that is measured, so a lazy list
  /// with only part of its items built still produces a usable value.
  static double _gapOf(
    List<DndId> itemIds,
    Map<DndId, DndRect> itemRects, {
    required bool vertical,
  }) {
    for (var index = 0; index < itemIds.length - 1; index += 1) {
      final current = itemRects[itemIds[index]];
      final next = itemRects[itemIds[index + 1]];
      if (current == null || next == null) {
        continue;
      }

      final gap = vertical ? next.top - current.bottom : next.left - current.right;
      return gap.isFinite ? gap : 0;
    }

    return 0;
  }
}

/// Reports how far each item a multi-container move displaces should shift.
///
/// The board counterpart of [SortableOffsetResolver]. A same-container move
/// behaves exactly like the single-list case; a cross-container move closes the
/// slot the dragged item leaves in its source column and opens one where it
/// will land in the target column.
///
/// Like the single-list resolver, this is pure and its result is output only:
/// deliver it to the item builder, which sits below the measured node, so it
/// cannot feed back into measurement.
typedef SortableMultiOffsetResolver = Map<DndId, DndPoint> Function(
  SortableMultiOffsetInput input,
);

/// Input passed to a [SortableMultiOffsetResolver].
@immutable
final class SortableMultiOffsetInput {
  /// Creates multi-container offset resolver input.
  SortableMultiOffsetInput({
    required this.activeId,
    required Iterable<SortableContainer> containers,
    required Map<DndId, DndRect> itemRects,
    required this.fromContainerId,
    required this.fromIndex,
    required this.toContainerId,
    required this.toIndex,
    this.activeRect,
  })  : containers = List<SortableContainer>.unmodifiable(containers),
        itemRects = Map<DndId, DndRect>.unmodifiable(itemRects);

  /// The item being dragged.
  final DndId activeId;

  /// The application-owned container order and membership, before the move.
  final List<SortableContainer> containers;

  /// Measured item rectangles keyed by item id. May be partial for lazy lists.
  final Map<DndId, DndRect> itemRects;

  /// The container the dragged item started in.
  final DndId? fromContainerId;

  /// The dragged item's index in its source container.
  final int fromIndex;

  /// The container the item would land in.
  final DndId? toContainerId;

  /// The index the item would land at in the target container.
  final int toIndex;

  /// The dragged item's extent, when known separately from [itemRects].
  ///
  /// Falls back to `itemRects[activeId]`.
  final DndRect? activeRect;

  /// The dragged item's measured rectangle, or null when unknown.
  DndRect? get resolvedActiveRect => activeRect ?? itemRects[activeId];

  /// Returns the container with [id], or null when absent.
  SortableContainer? containerById(DndId? id) {
    if (id == null) {
      return null;
    }
    for (final container in containers) {
      if (container.id == id) {
        return container;
      }
    }
    return null;
  }
}

/// Built-in multi-container offset resolvers.
abstract final class SortableMultiOffsets {
  /// Moves nothing. The default, and the behavior before offsets existed.
  static Map<DndId, DndPoint> none(SortableMultiOffsetInput input) => const <DndId, DndPoint>{};

  /// Shifts items for columns laid out as vertical lists, along the y axis.
  static Map<DndId, DndPoint> verticalLists(SortableMultiOffsetInput input) {
    return _resolve(input, vertical: true);
  }

  /// Shifts items for columns laid out as horizontal lists, along the x axis.
  static Map<DndId, DndPoint> horizontalLists(SortableMultiOffsetInput input) {
    return _resolve(input, vertical: false);
  }

  static Map<DndId, DndPoint> _resolve(
    SortableMultiOffsetInput input, {
    required bool vertical,
  }) {
    final fromContainer = input.containerById(input.fromContainerId);
    final toContainer = input.containerById(input.toContainerId);
    if (fromContainer == null || toContainer == null) {
      return const <DndId, DndPoint>{};
    }

    // Same container is the single-list case; keep one implementation for it.
    if (fromContainer.id == toContainer.id) {
      return SortableOffsets._resolve(
        SortableOffsetInput(
          activeId: input.activeId,
          itemIds: fromContainer.itemIds,
          itemRects: input.itemRects,
          fromIndex: input.fromIndex,
          toIndex: input.toIndex,
        ),
        vertical: vertical,
      );
    }

    // The dragged item's extent sets how far everything moves; without it there
    // is nothing to compute.
    final activeRect = input.resolvedActiveRect;
    if (activeRect == null) {
      return const <DndId, DndPoint>{};
    }
    final extent = vertical ? activeRect.height : activeRect.width;

    final offsets = <DndId, DndPoint>{};

    // Source column: items after the dragged item close the vacated slot.
    final sourceShift = -(extent +
        SortableOffsets._gapOf(fromContainer.itemIds, input.itemRects, vertical: vertical));
    for (var index = input.fromIndex + 1; index < fromContainer.itemIds.length; index += 1) {
      final id = fromContainer.itemIds[index];
      if (id == input.activeId) {
        continue;
      }
      offsets[id] = vertical ? DndPoint(0, sourceShift) : DndPoint(sourceShift, 0);
    }

    // Target column: items at and after the landing index open the new slot.
    final targetShift =
        extent + SortableOffsets._gapOf(toContainer.itemIds, input.itemRects, vertical: vertical);
    for (var index = input.toIndex; index < toContainer.itemIds.length; index += 1) {
      final id = toContainer.itemIds[index];
      if (id == input.activeId) {
        continue;
      }
      offsets[id] = vertical ? DndPoint(0, targetShift) : DndPoint(targetShift, 0);
    }

    return Map<DndId, DndPoint>.unmodifiable(offsets);
  }
}
