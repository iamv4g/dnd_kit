import 'package:meta/meta.dart';

import 'events.dart';
import 'geometry.dart';
import 'id.dart';
import 'state.dart';

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
  ///
  /// Null when these details describe a live preview rather than a committed
  /// move.
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

/// Which phase of a drag a sortable resolution is running in.
enum SortableResolutionPhase {
  /// The drag is still active and the result is where the item *would* land.
  ///
  /// Preview results drive live feedback such as a drop-target label or an
  /// offset plug-in. They are recomputed as the drag moves and are never
  /// reported through `onMove`.
  preview,

  /// The drag has ended and the result is the move that will be reported.
  commit,
}

/// The drag facts a sortable resolution needs, independent of drag phase.
///
/// The same resolution runs while a drag is moving (to publish a preview) and
/// when it ends (to commit a move). This context is what both paths are built
/// from, so the preview a UI shows and the move that is finally reported come
/// from one code path and cannot drift apart.
///
/// Measured geometry is deliberately *not* held here: rectangles already live
/// on [SortableStrategyInput] and the multi-container input, and duplicating
/// them would create two sources of truth for the same layout.
@immutable
final class SortableDragContext {
  /// Creates a drag context.
  const SortableDragContext({
    required this.session,
    required this.phase,
    this.overId,
    this.endEvent,
  });

  /// Creates a commit-phase context for a drag that has ended.
  factory SortableDragContext.commit(DndDragEndEvent event) {
    return SortableDragContext(
      session: event.session,
      phase: SortableResolutionPhase.commit,
      overId: event.overId,
      endEvent: event,
    );
  }

  /// Creates a preview-phase context for a drag that is still active.
  factory SortableDragContext.preview({
    required DndDragSession session,
    DndId? overId,
  }) {
    return SortableDragContext(
      session: session,
      phase: SortableResolutionPhase.preview,
      overId: overId,
    );
  }

  /// The active drag session.
  final DndDragSession session;

  /// Whether this resolution is a live preview or a committed move.
  final SortableResolutionPhase phase;

  /// The droppable currently under the drag, when one exists.
  final DndId? overId;

  /// The drag end event, present only in [SortableResolutionPhase.commit].
  final DndDragEndEvent? endEvent;

  /// The sortable item being moved.
  DndId get activeId => session.activeId;

  /// The current drag transform after modifiers have been applied.
  DndTransform get transform => session.transform;

  /// Whether this resolution is a live preview.
  bool get isPreview => phase == SortableResolutionPhase.preview;

  @override
  bool operator ==(Object other) {
    return other is SortableDragContext &&
        other.session == session &&
        other.phase == phase &&
        other.overId == overId &&
        other.endEvent == endEvent;
  }

  @override
  int get hashCode => Object.hash(session, phase, overId, endEvent);

  @override
  String toString() {
    return 'SortableDragContext(phase: $phase, activeId: $activeId, overId: $overId)';
  }
}

/// Computes sortable move intent for a drag.
///
/// Runs both while a drag moves (preview) and when it ends (commit); check
/// `input.context.phase` when the two must behave differently.
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
    required this.context,
    this.activeRect,
    this.activeTranslatedRect,
  })  : itemIds = List<DndId>.unmodifiable(itemIds),
        itemRects = Map<DndId, DndRect>.unmodifiable(itemRects);

  /// Creates strategy input for a drag that has ended.
  ///
  /// Convenience for the commit path; equivalent to passing
  /// `SortableDragContext.commit(event)`.
  factory SortableStrategyInput.fromDragEnd({
    required DndId activeId,
    required DndId? overId,
    required Iterable<DndId> itemIds,
    required Map<DndId, DndRect> itemRects,
    required int fromIndex,
    required DndId? fromContainerId,
    required DndId? toContainerId,
    required DndDragEndEvent event,
    DndRect? activeRect,
    DndRect? activeTranslatedRect,
  }) {
    return SortableStrategyInput(
      activeId: activeId,
      overId: overId,
      itemIds: itemIds,
      itemRects: itemRects,
      fromIndex: fromIndex,
      fromContainerId: fromContainerId,
      toContainerId: toContainerId,
      context: SortableDragContext.commit(event),
      activeRect: activeRect,
      activeTranslatedRect: activeTranslatedRect,
    );
  }

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

  /// The drag this resolution is running for, and which phase it is in.
  final SortableDragContext context;

  /// The lower-level drag end event that produced this strategy input.
  ///
  /// Null while a drag is still active, because a preview has no end event
  /// yet.
  @Deprecated(
    'Use context (SortableDragContext) instead. This getter is null during '
    'preview resolutions and will be removed in a future release.',
  )
  DndDragEndEvent? get event => context.endEvent;

  /// The measured active rectangle before translation, when known.
  final DndRect? activeRect;

  /// The measured active rectangle after drag translation, when known.
  final DndRect? activeTranslatedRect;

  /// Builds move intent that lands the active item at the drop-over target.
  ///
  /// Returns the move that places [activeId] at [overId]'s index, or at
  /// [toIndex] when given. Geometric strategies call this as their fallback
  /// when measurements cannot anchor a decision; [SortableStrategies.dropOnOver]
  /// uses it as its whole implementation, and custom strategies can build on
  /// it the same way.
  ///
  /// Returns null when there is no drop-over target, the target is the active
  /// item itself, or the active item's index is unknown.
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
      event: context.endEvent,
    );
  }
}

/// Built-in sortable strategies.
abstract final class SortableStrategies {
  /// Lands the move at the item currently under the drag.
  ///
  /// The drop commits wherever the collision result points, so the committed
  /// move always matches the `isOver` highlight. Use this when the UI shows a
  /// drop-target highlight or a placeholder gap and the drop must agree with
  /// it.
  ///
  /// The geometric strategies ([verticalList], [horizontalList], [grid])
  /// instead recompute the target from the active rect center, so they can
  /// resolve to a different index than the highlighted one — or to no move at
  /// all while the center has not yet crossed a neighbour's center.
  static SortableMoveDetails? dropOnOver(SortableStrategyInput input) {
    return input.fallbackMoveDetails();
  }

  /// Computes same-container vertical list movement from measured item centers.
  ///
  /// The target index comes from the active translated rect's **center**, not
  /// from the drop-over id: no move is reported until that center crosses a
  /// neighbour's center, so the committed move can lag a drop-target highlight
  /// driven by collision. Use [dropOnOver] when the drop must land exactly
  /// where the highlight is.
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
  /// Resolves from the active rect center rather than the drop-over id, with
  /// the same highlight-versus-drop caveat as [verticalList]. Supports a
  /// partially-measured (visible-only) set the same way.
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
  /// Resolves from the active rect center rather than the drop-over id, with
  /// the same highlight-versus-drop caveat as [verticalList]. Supports a
  /// partially-measured (visible-only) set the same way.
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
