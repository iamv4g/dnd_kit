# 0025 Sortable Live Preview And Offsets

Date: 2026-07-23

## Status

Accepted

## Context

ADR 0024 fixed the drag defaults a production integration reported, but
deliberately deferred the largest item on that list: the integration had to
hand-build a web-style placeholder gap, and noted it "has to re-derive the
insert direction the reducer already knows".

That is the real complaint. The engine computes where an item will land, but
only at drag end, and never tells anyone before then. Applications therefore
rebuild collision, direction, and measurement logic that already exists.

Two constraints shaped the answer:

- `docs/product/api-principles.md` states that applications own "rendering,
  **animation**, and collection mutation". A library-owned animating widget
  would contradict standing policy; reporting geometry the application applies
  does not.
- The same document requires that sortable behavior work on the measured
  (visible) item subset, and that we not rebuild the whole app per pointer
  move.

Prior art matters here too. `@dnd-kit/sortable` does not animate on the
consumer's behalf: a strategy computes a transform per item and the consumer
applies it through `style`. That division — library computes geometry,
application renders it — is the one that fits the policy above.

## Decision

1. **Sortable resolution is phase-aware.** `SortableDragContext` carries the
   session, the phase (`preview` or `commit`), the drop-over id, and the end
   event when there is one. `SortableStrategyInput` and `SortableMultiMoveInput`
   are built from it; their `event` field becomes a deprecated getter that is
   null during preview.

   The point is that **one code path serves both phases**. A preview and the
   move that follows it are the same computation, so they cannot drift — which
   is the class of bug ADR 0024 was written to fix.

2. **A live preview is always published.** `SortablePreview` reports
   `previewIndex` and `previewContainerId` for single- and multi-container
   scopes. It resolves lazily and caches per move, so a list of any size costs
   one resolution and an application that never reads it pays nothing.

   Multi-container scopes resolve with the strategy of the container the
   dragged item *came from*; container areas publish their strategies to the
   scope through an owner-aware registry.

3. **Offsets are an opt-in pure plug-in.** `SortableOffsetResolver` is the
   fourth member of the plug-in family, alongside `DndCollisionDetector`,
   `DndModifier`, and `SortableStrategy`. The symmetry is deliberate: a
   modifier transforms the **active** item's transform, a resolver transforms
   the **other** items'. `SortableOffsets.none` is the default, so no existing
   UI changes.

4. **Offsets are output, never input.** They are delivered to the item builder,
   whose output sits below the measured node on both adapters — a Flutter
   `DndMeasuredBox` wraps it, and in Jaspr it is a child of the measured
   element. Applying an offset there cannot change a measured rectangle, so the
   shift → measure → collide → shift loop cannot form. This is a structural
   property, not a discipline, and both adapters have a test pinning it.

5. **Displaced items shift by the dragged item's extent plus the list gap.**
   Shifting each item into its neighbour's slot is only correct for uniform
   sizes; the dragged-extent rule reproduces the true post-move layout for
   variable heights too.

6. **The library never animates.** It reports a `DndPoint` per item.
   Applications choose `AnimatedSlide`, a `Transform`, a CSS transition, or
   nothing at all.

## Alternatives Considered

1. Ship an animated sortable widget that shifts neighbours itself.
   Rejected: it contradicts the standing "applications own animation" rule, and
   it would require the library to understand arbitrary layouts (slivers, wrap
   grids, lazy lists) to place widgets correctly.
2. Put offsets in a separate package, mirroring `@dnd-kit/sortable`.
   Rejected: sortable is already bundled into `dnd_kit` plus the adapters here,
   so a package boundary only for offset policy adds versioning cost without a
   structural benefit.
3. Make shifting the default for `SortableScope` now.
   Deferred to 1.0. The mechanism has not soaked, and turning it on would
   change every existing consumer's visuals inside a release already carrying
   behavior changes.
4. Add a separate preview resolver and leave `SortableStrategy` untouched.
   Rejected: it duplicates the resolution logic, which is exactly how a preview
   and a commit start disagreeing.
5. Compute preview eagerly on every controller notification.
   Rejected: it charges every consumer for a feature they may not read. Lazy
   resolution with a per-move cache gives the same observable behavior.

## Consequences

Positive:

- Applications can render a placeholder gap, a drop-target label, or shifted
  neighbours from published geometry instead of re-deriving intent.
- Preview and commit are provably the same computation, tested through an
  invariant that the preview at release equals the committed move.
- The offset contract is framework-neutral, so Flutter and Jaspr inherit one
  policy; only the act of applying a transform differs.

Tradeoffs:

- Public surface grows: a context type, a preview type, a plug-in type, and new
  fields on scope and item details, all pre-1.0.
- `SortableStrategyInput.event` and `SortableMultiMoveInput.event` are
  deprecated for one release. Custom strategies reading `event` keep working
  but must move to `context`.
- `SortableMultiContainerArea` became stateful to manage strategy registration.
  Its public constructor is unchanged.
- Offsets ship for single-container scopes only; multi-container scopes publish
  preview but do not shift.

## Follow-Up

- Cross-container offsets (source column closes, target column opens).
- Grid offsets, which have materially different visual expectations than lists.
- A drop animation for `DndDragOverlay`, so the preview flies to its landing
  slot instead of disappearing.
- Revisit ADR 0024's exclusion of the active item from collision candidates
  once shifting is common: that decision was made partly because nothing moved,
  and shifting changes the premise.
