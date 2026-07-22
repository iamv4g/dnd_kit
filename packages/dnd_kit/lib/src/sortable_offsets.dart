import 'package:meta/meta.dart';

import 'geometry.dart';
import 'id.dart';

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
    final distance = extent + _gapOf(input, vertical: vertical);

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
  static double _gapOf(SortableOffsetInput input, {required bool vertical}) {
    final itemIds = input.itemIds;
    for (var index = 0; index < itemIds.length - 1; index += 1) {
      final current = input.itemRects[itemIds[index]];
      final next = input.itemRects[itemIds[index + 1]];
      if (current == null || next == null) {
        continue;
      }

      final gap = vertical ? next.top - current.bottom : next.left - current.right;
      return gap.isFinite ? gap : 0;
    }

    return 0;
  }
}
