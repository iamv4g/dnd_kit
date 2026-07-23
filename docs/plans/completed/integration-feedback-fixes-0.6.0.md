# Execution Plan: Integration Feedback Fixes (0.6.0)

Date: 2026-07-22

## Status

Completed

## Outcome

`dnd_kit` / `dnd_kit_flutter` 0.6.0 resolves the verified correctness and UX
defects reported in `INTEGRATION_FEEDBACK.md` (real-world integration from
`plan_tour_flutter` against 0.5.0):

1. The active draggable is never a collision candidate, so releasing over a
   valid target commits the move without overshooting.
2. Droppable rectangles are correct after any ancestor scroll: they are
   re-measured at drag start, and the built-in auto-scroll invalidates
   measurements on every scroll tick.
3. A built-in `SortableStrategies.dropOnOver` strategy lands the drop exactly
   where the `isOver` highlight is, and the highlight/drop relationship is
   documented.
4. The `DndDragOverlay` ghost keeps its drag-start size when the source slot
   collapses (placeholder-gap pattern), instead of being clipped to zero.
5. Documentation covers the four recipes the feedback asked for: sortable
   inside a scroll view, nested/parallel scopes sharing one controller,
   web-style placeholder gap, and drop-where-highlighted (including the
   already-existing `SortableMultiContainerArea.strategy` parameter).

## Context

- Feedback source: `INTEGRATION_FEEDBACK.md` (repo root, untracked on `main`).
- Every claim was verified against the published 0.5.0 source, which is
  byte-identical to this repo state. Verification results:
  - 3.1 confirmed — `DndRuntime._updateCollision`
    (`packages/dnd_kit/lib/src/runtime.dart:208`) includes the active item's
    own droppable; `overId == activeId` then resolves to a silent null move in
    `SortableMultiContainer.resolveMove`, `SortableScopeData.moveDetailsFor`,
    and `SortableStrategyInput.fallbackMoveDetails`.
  - 3.2 confirmed — `isOver` follows `controller.overId` while the committed
    move follows the strategy's center-crossing rule
    (`packages/dnd_kit/lib/src/sortable.dart:187`); no drop-at-over strategy
    exists.
  - 3.3 confirmed and worse than reported — measurements only go dirty on
    `performLayout` (`DndMeasuredBox.onLayout`); ancestor scroll does not
    relayout children; `beginDrag` never marks dirty; additionally the
    library's own `DndAutoScrollController._tick` calls `position.jumpTo`
    (`packages/dnd_kit_flutter/lib/src/widgets/auto_scroll.dart:106`) without
    calling `markAllDirty`, despite the `markAllDirty` docstring naming
    auto-scroll as its intended caller.
  - 3.4 confirmed — `DndDragOverlay` sizes `Positioned` to the live
    `activeRect` (`packages/dnd_kit_flutter/lib/src/widgets/drag_overlay.dart:83`)
    while `DndRuntime._refreshMeasurements` live-updates that rect's
    width/height during drag (`runtime.dart:238`).
  - 3.7 refuted — `SortableMultiContainerArea.strategy` already exists in
    0.5.0 (`sortable_multi_scope.dart:232`) and flows into `moveDetailsFor`;
    this is a documentation gap, not an API gap.
  - 3.9 refuted — only one public `SortableContainer` type exists; the Flutter
    file is a re-export shim. No rename needed.
- Architecture authority: `docs/ARCHITECTURE.md`, ADRs 0021/0022 (shared
  multi-container engine). Fixes must land in the framework-neutral core where
  possible so the Jaspr adapter inherits them.

## Scope

In scope (0.6.0):

- Core: exclude the active id from collision candidates before invoking the
  detector.
- Core: mark all measurements dirty at drag start (`beginDrag`).
- Flutter: invalidate measurements on each auto-scroll tick.
- Core: add `SortableStrategies.dropOnOver`.
- Flutter: preserve the drag-start ghost size in `DndDragOverlay`; expose both
  the drag-start rect and the live rect to the overlay builder.
- Docs: the four recipes plus API docs for `fallbackMoveDetails`,
  `DndCollisionDetectors`, `measuring.markAllDirty/refreshDirty`, and
  `SortableMultiContainerArea.strategy`.
- Version bump to 0.6.0 with CHANGELOG entries; ADR for the collision-candidate
  default change.

Out of scope (tracked, not in 0.6.0):

- Opt-in animated sortable / placeholder API and preview-insert-index exposure
  (feedback 3.5) — needs its own design pass.
- Making `isOver` reflect the strategy decision (feedback 3.2 "ideally") —
  architectural change to the collision/highlight contract; `dropOnOver` plus
  docs covers the practical need for 0.6.0.
- Programmatic drag test harness (`controller.simulateDrag`) — nice-to-have.
- `SortableContainer` rename (feedback 3.9) — refuted, no action.
- Scroll-listener-driven re-measure (observing ancestor `Scrollable`s) — drag
  start + auto-scroll invalidation covers the reported failures; revisit if a
  mid-drag manual-scroll report arrives.

## Approach

Ordered, independently verifiable groups; core changes first so both adapters
inherit them.

### Group 1 — Collision correctness (feedback 3.1)

In `DndRuntime._updateCollision`, skip `entry.key == session.activeId` when
building `droppableRects`. Keep `activeId` on `DndCollisionInput` (still needed
for kind-scoping). Document on `DndCollisionInput.droppableRects` that the
active id is pre-filtered.

Proof: core runtime test — a sortable-style setup where the active item's own
droppable overlaps the pointer must never produce `overId == activeId`;
regression test that a neighbouring target wins immediately.

### Group 2 — Measurement freshness (feedback 3.3)

1. `DndRuntime.beginDrag`: call `measuring.markAllDirty()` before resolving the
   active rect so the first `refreshDirty` (already invoked from
   `moveDrag`/`_refreshMeasurements`) re-measures everything. Ensure
   `beginDrag` itself refreshes before reading `draggableRect`.
2. `DndAutoScrollController._tick` (Flutter): after `position.jumpTo`, call
   `markAllDirty()` on the scope controller's measuring registry. Requires
   giving the auto-scroll controller access to the `DndController` (or a
   `VoidCallback onScrolled`); pick the smallest API that keeps the core
   framework-neutral.

Proof: Flutter widget test — sortable list inside a scrolled
`SingleChildScrollView`/`ListView`; after scrolling, a drag lands on the target
under the pointer, not offset by the scroll amount. Auto-scroll test where
rects stay correct across ticks.

### Group 3 — Drop-where-highlighted strategy (feedback 3.2)

Add `SortableStrategies.dropOnOver` (delegates to
`input.fallbackMoveDetails()`), unit-tested in core. Document on
`verticalList`/`horizontalList`/`grid` that they commit on rect-center
crossing, and on `DndDroppableDetails.isOver` that the highlight tracks
collision, not the committed move.

Proof: core unit tests for `dropOnOver` (same-container, `overId == activeId`,
unmeasured cases).

### Group 4 — Overlay ghost sizing (feedback 3.4)

Capture the drag-start rect once at `startDrag` (runtime keeps it stable for
the session, e.g. `initialActiveRect`), keep `activeRect` live for collision.
`DndDragOverlay` sizes its `Positioned` from the drag-start size and exposes
both rects via `DndDragOverlayDetails`. Collapsing the source slot mid-drag
must not clip the ghost.

Proof: Flutter widget test — collapse the source to height 0 during a drag;
the overlay child still renders at its drag-start size.

### Group 5 — Docs, changelog, release prep

- Four recipes under `docs/` (location per existing docs layout): scroll-view
  sortables, nested/parallel scopes with one controller, placeholder gap,
  drop-on-over.
- API docs for the previously undocumented surfaces listed in Scope.
- ADR: "exclude the active draggable from collision candidates" (behavior
  default change).
- CHANGELOG + version 0.6.0 for `dnd_kit`, `dnd_kit_flutter` (and
  `dnd_kit_jaspr` if it re-exports affected core behavior).

## Risks And Recovery

- Behavior change risk: filtering the active id changes `overId` sequences that
  existing apps may observe. Mitigation: changelog "breaking behavior" note +
  ADR; the old behavior was the reported footgun.
- `markAllDirty` on every auto-scroll tick could cost performance on large
  boards. Mitigation: measure with the existing examples; if needed, dirty only
  droppables (not draggables) or throttle to once per frame.
- Overlay API change (`DndDragOverlayDetails` gaining a second rect) must stay
  additive; keep `activeRect` semantics documented. If downstream visual
  regressions appear, the `Positioned` sizing change is isolated to
  `drag_overlay.dart` and easy to revert independently.
- Recovery: each group is a separate commit on `release/0.6.0`; revert the
  offending commit without unwinding the rest. No migrations or destructive
  operations involved.

## Progress

- [x] Branch `release/0.6.0` created from `main` (732f558).
- [x] Group 1 — active id excluded from collision candidates + tests
      (`_updateCollision` skips `session.activeId`; doc on
      `DndCollisionInput.droppableRects`; 2 new runtime tests; core 137 /
      flutter 105 / jaspr VM 37 tests green).
- [x] Group 2 — drag-start re-measure + auto-scroll invalidation + tests
      (`beginDrag` marks all measurements dirty and refreshes when it must
      resolve the active rect itself; `DndAutoScrollController.onScrolled`
      fires after each tick and `DndAutoScroll` wires it to
      `markAllDirty` + `moveDrag(currentPointer)` so overId tracks content
      moving under a stationary pointer; core 139 / flutter 106 / jaspr VM 37
      tests green).
- [x] Group 3 — `SortableStrategies.dropOnOver` + tests + strategy docs
      (new strategy delegating to `fallbackMoveDetails`; center-crossing
      caveat documented on the three geometric strategies; `isOver` documented
      as collision-driven on Flutter `DndDroppableDetails` /
      `SortableItemDetails` and Jaspr `DndDroppableDetails`; core 142 /
      flutter 106 / jaspr VM 37 tests green).
- [x] Group 4 — overlay drag-start sizing + tests (`DndRuntime.initialActiveRect`
      captured at `beginDrag` and cleared at `reset`; exposed on both adapter
      controllers and on `DndDragOverlayDetails`; Flutter and Jaspr overlays
      size from it; core 143 / flutter 107 / jaspr VM 37 tests green, jaspr
      analyze clean).
- [x] Group 5 — recipes, API docs, ADR, changelogs, version bump to 0.6.0
      (ADR 0024; family bumped to 0.6.0 with changelogs; Flutter README
      documents `dropOnOver`; new `/docs/recipes` website page covering the
      four recipes, linked from the collision and sortable pages; website
      analyze clean and the SSG build generates the page).
- [x] Full validation lane green; plan moved to `docs/plans/completed/`.

## Decisions

- 2026-07-22: Branch named `release/0.6.0` — the batch represents the next
  library version rather than a single feature/fix.
- 2026-07-22: Feedback items 3.7 and 3.9 are refuted by source verification;
  3.7 becomes a documentation task, 3.9 is dropped.
- 2026-07-22: Placeholder/animated sortable (3.5) deferred out of 0.6.0; it
  needs a design pass and should not block the four correctness fixes.
- 2026-07-22: `DndAutoScrollController` stays decoupled from the controller
  via an `onScrolled` callback; `DndAutoScroll` wires it. The tick handler
  also re-runs `moveDrag(currentPointer)` because auto-scroll moves content
  under a stationary pointer — invalidating rects alone would leave `overId`
  stale until the next pointer move.
- 2026-07-22: The drag-start rect is a full `DndRect` named `initialActiveRect`
  (not a size-only field), so the overlay derives both position and size from
  one value and applications can reason about the original slot. The live
  `activeRect` keeps its current semantics for collision. Both Flutter and
  Jaspr overlays were fixed — the sizing defect was identical in each.

## Validation

- Focused proof: new core unit tests (`packages/dnd_kit`, `dart test`) for
  Groups 1–3; new Flutter widget tests (`packages/dnd_kit_flutter`,
  `flutter test`) for Groups 2 and 4.
- Integration or end-to-end proof: run the affected examples (sortable list in
  scroll view, multi-container board) and verify drop-at-highlight and
  post-scroll accuracy interactively.
- Repository-required checks: `dart run melos run validate` (full release
  gate) before claiming completion; `MELOS_DIFF=HEAD dart run melos run
  validate:affected` during development.

## Result

All five groups landed on `release/0.6.0`, one commit per group. The four
must-have defects from `INTEGRATION_FEEDBACK.md` are fixed at the default and
the family is versioned 0.6.0.

Verified:

- `dart run melos run validate` (full release gate) is green across all six
  workspace packages: `dnd_kit`, `dnd_kit_flutter`, `dnd_kit_jaspr`,
  `dnd_kit_website`, `flutter_example_gallery`, `jaspr_example_gallery`.
- Focused suites: core 143 tests, Flutter 107, Jaspr VM 37 — all passing, with
  8 new tests covering active-id exclusion, drag-start re-measure, auto-scroll
  invalidation, `dropOnOver`, and drag-start overlay sizing.
- Jaspr browser suites (`@TestOn('browser')`, not part of the melos lane) pass
  under `-p chrome`: 23 tests across the five browser test files.
- The website SSG build generates `/docs/recipes` and the page renders its four
  sections.

Limitations and risks:

- One flaky failure was observed once in the Jaspr browser suite
  (`auto_scroll_browser_test.dart`, "resolves horizontal collision against a
  target scrolled into view"). It did not reproduce in seven subsequent runs of
  the same command, and four baseline runs on `main` also passed, so the cause
  is unproven. The test polls with a timeout while auto-scroll runs, so it is
  timing-sensitive; worth watching in CI.
- Forcing the whole Jaspr suite onto Chrome (`dart test -p chrome`) fails 14
  VM-oriented tests with `TestRenderFragment is not a subtype of
  DomRenderObject`. This is pre-existing — `main` fails the same 14 — and is
  not addressed here.
- The behavior changes are breaking for consumers who relied on `overId`
  equalling `activeId`, on receiving the active item as a collision candidate,
  or on overlays tracking a live source resize. `DndDragOverlayDetails` also
  gains a required `initialActiveRect`. All are recorded in ADR 0024 and the
  changelogs.
- No interactive end-to-end pass was run against the examples; proof is the
  automated suites plus the website build.

Unattempted, tracked in ADR 0024 follow-up and this plan's out-of-scope list:
opt-in animated sortable / placeholder API with a preview insert index, making
`isOver` reflect the strategy decision, a programmatic drag API for tests, and
scroll-listener-driven re-measurement for mid-drag manual scrolling.
