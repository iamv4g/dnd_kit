# 0024 Drag Defaults Match What Users See

Date: 2026-07-22

## Status

Accepted

## Context

A production integration built a nested, web-parity sortable UI on 0.5.0 and
reported that four defaults were wrong often enough to require app-side
workarounds. Each was reproduced in the library source:

1. **The dragged item was its own drop target.** `DndRuntime` passed every
   measured droppable to the collision detector, including the active item —
   sortable items register the same id as draggable and droppable. While the
   pointer was still inside the source slot, the active item won its own
   collision, `overId` equalled `activeId`, and every move resolver treats that
   as "no move". Drops silently did nothing until the user overshot the target.
2. **Measurements went stale on scroll.** Rects are measured on layout, but
   scrolling a viewport repaints without relayout. Nothing invalidated the
   cache at drag start, so every target in a scrolled list was off by the
   scroll offset. The library's own auto-scroll had the same defect: it called
   `ScrollPosition.jumpTo` on each tick without invalidating anything, even
   though `DndMeasuringRegistry.markAllDirty` was written for that caller.
3. **The highlight and the drop disagreed.** `isOver` follows the collision
   result while the committed move follows the sortable strategy, and the
   built-in strategies resolve from the dragged rect's center. The two signals
   routinely pointed at different items, and no built-in strategy existed to
   make them agree.
4. **The drag preview died with the source.** Both adapters sized the overlay
   from the live active rect, whose size tracks the source widget. Collapsing
   the source slot — the standard way to open a placeholder gap — collapsed the
   preview to nothing.

These are defaults, not missing features: the escape hatches existed, but every
integration has to rediscover them by reading the source.

## Decision

1. **The active draggable is never a collision candidate.** `DndRuntime`
   excludes the active id from `droppableRects` before invoking the detector.
   `DndCollisionInput.activeId` stays available for kind-scoping in nested
   scopes, but no detector has to filter the active item itself.
2. **Drag start invalidates all measurements.** `beginDrag` calls
   `markAllDirty`, and refreshes immediately when it must resolve the active
   rect itself. Scroll position at drag start can no longer corrupt collision.
3. **Auto-scroll invalidates and re-resolves on every tick.**
   `DndAutoScrollController` exposes an `onScrolled` callback; the Flutter
   `DndAutoScroll` widget wires it to `markAllDirty` plus a `moveDrag` at the
   unchanged pointer, because auto-scroll moves content under a stationary
   pointer and `overId` must follow.
4. **`SortableStrategies.dropOnOver` ships as a built-in strategy.** It commits
   the move at the drop-over target, so the drop always matches the `isOver`
   highlight. The geometric strategies keep their center-crossing behavior and
   now document it.
5. **The drag preview is sized from the drag-start rect.** `DndRuntime` exposes
   `initialActiveRect`, fixed for the session; both adapter overlays lay out
   from it and pass both rects to the builder.

The collision/highlight contract itself is unchanged: `isOver` still reports
the collision result rather than the strategy's decision. Applications choose
agreement by selecting `dropOnOver`.

## Alternatives Considered

1. Document the active-item footgun instead of changing the default.
   Rejected: an item can never be a valid drop target for itself, so the old
   behavior has no correct use, and every custom detector would keep paying for
   it.
2. Observe ancestor `Scrollable`s and re-measure on every scroll notification.
   Rejected for this slice: drag-start plus auto-scroll invalidation covers the
   reported failures at a fraction of the cost. Revisit if mid-drag manual
   scrolling is reported.
3. Drive `isOver` from the strategy so the highlight can never diverge.
   Rejected for now: the strategy only produces a decision at drag end, so this
   would require a live-preview contract across the runtime and both adapters.
   `dropOnOver` gives applications the same guarantee today.
4. Let the overlay builder opt out of the tight `Positioned` and size itself.
   Rejected: it pushes a layout workaround onto every consumer, when a stable
   drag-start rect is what a drag preview always wanted.

## Consequences

Positive:

- The reported drop no-ops, scroll offset errors, and disappearing previews are
  fixed at the default, so the common "sortable list inside a scroll view with
  a placeholder" case works without custom code.
- The fixes to collision, measuring, strategies, and `initialActiveRect` live in
  `dnd_kit`, so Flutter and Jaspr inherit them together.

Tradeoffs:

- Behavior changes for existing consumers: `overId` can no longer be the active
  id, custom detectors no longer receive it as a candidate, and overlays no
  longer track a live source resize. Applications that relied on any of these
  must adjust.
- `DndDragOverlayDetails` gains a required `initialActiveRect`, which breaks
  manual construction of that details object.
- `markAllDirty` on every auto-scroll tick re-measures the whole registry each
  frame while auto-scrolling; if this shows up on large boards, narrow it to
  droppables or throttle it.

## Follow-Up

- Consider an opt-in animated sortable that shifts neighbours and renders a
  placeholder, or at minimum expose the preview insert index, so applications
  stop rebuilding collision, direction, and measurement logic by hand.
- Consider a programmatic drag API on the controller so interaction behavior is
  testable without driving gesture plumbing.
