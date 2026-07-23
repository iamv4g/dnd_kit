# 0026 Cross-Container Sortable Offsets

Date: 2026-07-23

## Status

Accepted

## Context

ADR 0025 shipped live sortable offsets for single-container scopes and listed
cross-container offsets as follow-up. A board could show where a card would
land (the preview), but not open a live gap: `SortableMultiScope` built its
preview without an offset resolver, so `SortableItemDetails.offset` was always
zero on a multi item.

A board move is not a single-list shift. It touches two lists with two index
spaces: the card is removed from its source column and inserted into a target
column. The single-list `SortableOffsetResolver` cannot express that — it has
one `itemIds` and one `fromIndex`/`toIndex`.

## Decision

1. **A dedicated multi-container resolver.** `SortableMultiOffsetResolver` and
   `SortableMultiOffsetInput` join the plug-in family, alongside the existing
   `SortableMultiMoveResolver` for move resolution. The single-list resolver is
   left unchanged.
2. **Same-container delegates to the single-list logic.** A move whose source
   and target column are the same is exactly the single-list case, so
   `SortableMultiOffsets` calls the single-list resolver for it. The list case
   has one implementation.
3. **Cross-container is two one-directional shifts.** The source column closes:
   items after the dragged card shift toward the start by the dragged card's
   extent. The target column opens: items at and after the landing index shift
   toward the end by the same extent. Each column uses its own measured gap.
4. **Opt-in with a `none` default.** `SortableMultiScope.offsetResolver`
   defaults to `SortableMultiOffsets.none`, so existing boards are unchanged.
5. **The ADR 0025 rules carry over.** Offsets are pure and output only,
   delivered to the item builder (below the measured node) so they cannot feed
   back into measurement; a displaced item needs no rect of its own, so lazy
   columns stay correct; a missing dragged extent yields no offsets; and the
   demo hides the dragged card rather than collapsing its slot, so the layout
   does not reclaim the source space twice.

## Alternatives Considered

1. Reuse `SortableOffsetResolver` and call it per column.
   Rejected: it cannot express the source column's removal (all items after the
   card shift, which is not a within-list move), so the source column would be
   wrong.
2. Fold cross-container into the single-list input with nullable container
   fields. Rejected: it muddies the single-list contract for a case it does not
   serve, and the multi resolver has independent long-term value.
3. Compute offsets in the adapter scope rather than in core. Rejected: the
   geometry is framework-neutral, so Flutter and Jaspr must share it; the scope
   only supplies the measured rects and the resolved preview move.

## Consequences

Positive:

- Boards get a live placeholder gap within and across columns from published
  geometry; the application still owns the animation.
- Flutter and Jaspr inherit one board offset policy; only applying the
  transform differs.
- Same-container behavior is provably identical to the single-list resolver,
  tested by equality.

Tradeoffs:

- More public surface: a resolver type, an input, and the `SortableMultiOffsets`
  built-ins, all pre-1.0.
- Grid columns are still treated as vertical or horizontal lists; true
  two-dimensional grid offsets remain out of scope.

## Follow-Up

- Grid offsets, if a board with grid columns needs them.
- A `DndDragOverlay` drop animation, so the floating card flies to its landing
  slot instead of disappearing.
