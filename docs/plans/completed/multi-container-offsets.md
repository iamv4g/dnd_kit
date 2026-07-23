# Execution Plan: Cross-Container Sortable Offsets

Date: 2026-07-23

## Status

Completed

## Outcome

A multi-container sortable board can open a live placeholder gap while dragging,
within a column and across columns: the source column closes the gap the
dragged item left, and the target column opens a gap where it will land. The
library reports the per-item offsets; the application animates them. Offsets
default to off, so existing boards are unchanged.

## Context

- Follows the single-container work shipped on the 0.6.0 line
  (`docs/plans/completed/sortable-live-offsets-0.6.0.md`, ADR 0025), which
  deferred cross-container offsets as follow-up.
- Current state after that work:
  - `SortableMultiScope` publishes a live preview (`previewIndex`,
    `previewContainerId`) resolved with the source container's strategy, but its
    `SortablePreview` is created **without** an offset resolver, so
    `SortableItemDetails.offset` is always `DndPoint.zero` on a multi item.
  - `SortableOffsets.verticalList` / `horizontalList` compute offsets for a
    **single** list — one `itemIds`, one `fromIndex`/`toIndex`. They cannot
    express a cross-container move, which touches two lists with two index
    spaces and includes a removal (source) plus an insertion (target).
- Authority: `docs/product/api-principles.md` — applications own animation;
  override hooks are additive; sortable works on the measured visible subset.
  ADR 0022 — the library owns default board/list interaction; ADR 0025 — offsets
  are output, delivered to the item builder so they cannot feed back into
  measurement.
- API precedent: multi-container already exposes `SortableMultiMoveResolver`
  alongside the single-container `SortableStrategy`. A parallel
  `SortableMultiOffsetResolver` alongside `SortableOffsetResolver` fits that
  shape, so the new surface is not a novel concept.

## Scope

In scope:

- Core: `SortableMultiOffsetResolver`, `SortableMultiOffsetInput`, and built-ins
  `SortableMultiOffsets.verticalLists` / `horizontalLists` / `none` (default).
  Handles same-container moves (delegating to the single-list logic) and
  cross-container moves (source close + target open).
- Flutter and Jaspr: `SortableMultiScope.offsetResolver` (default
  `SortableMultiOffsets.none`), wired into the preview's `resolveOffsets` so
  `SortableItemDetails.offset` reports the shift. No change to
  `SortableItemDetails` — its `offset` getter already reads the preview.
- Demo: the `multi-container` catalog demo opens a gap within and across
  columns, hiding the dragged card (not collapsing it), consistent with the
  single-container demo.
- Docs: extend the recipe/README note to cover the board case; ADR addendum or
  a short new ADR for the cross-container offset contract; changelog.

Out of scope:

- Grid offsets (two-dimensional). Columns are treated as vertical or horizontal
  lists.
- Any change to the single-container `SortableOffsetResolver` contract.
- A `DndDragOverlay` drop animation.

## Approach

Core first so both adapters inherit one policy.

### Group 1 — Core cross-container offset built-ins

Add the resolver type and input carrying what a board move needs: `activeId`,
the `containers`, `itemRects`, `fromContainerId`/`fromIndex`,
`toContainerId`/`toIndex`, and the dragged item's extent rect.

Computation:

- **Same container** (`fromContainerId == toContainerId`): the existing
  single-list shift. Reuse `SortableOffsets.verticalList`/`horizontalList` on
  that container's items so there is one source of truth for the list case.
- **Cross container**: two one-directional shifts by the dragged extent plus
  each column's own gap:
  - source column: items after `fromIndex` shift toward the start (close the
    vacated slot);
  - target column: items at/after `toIndex` shift toward the end (open the
    landing slot).

Rules carried over from ADR 0025: pure and synchronous; unmeasured items still
get an offset because it does not depend on their own rect; a missing dragged
extent yields no offsets (guessing it would misplace everything); offsets are
output only.

Proof: core unit tests — same-container matches the single-list result;
cross-container shifts the source tail up and the target tail down by the
dragged extent; the source==target and no-move cases are empty; unmeasured
target items still get an offset; a missing active rect yields nothing.

### Group 2 — Adapter wiring

Add `offsetResolver` to `SortableMultiScope` on both adapters and pass a
`resolveOffsets` into the scope's `SortablePreview`, building the
`SortableMultiOffsetInput` from the resolved preview move and the live
`droppableRects`. Invalidate on the same signals as the preview.

Proof: Flutter widget tests — dragging within a column shifts that column's
tail; dragging across columns shifts the source tail up and the target tail
down; offsets reach the item builders; the preview-equals-commit relationship
still holds; a guard that applying offsets does not move measured rects or
oscillate `overId`. A Jaspr browser test for the cross-container measured-rect
invariant.

### Group 3 — Demo, docs, changelog

Update the `multi-container` gallery demo to animate `details.offset` inside the
card builder and hide the dragged card. A gallery widget test drives a
cross-column drag and asserts a gap opens in the target column. Extend the
recipe and README; record the contract (ADR addendum to 0025 or a new ADR);
changelog entries on the 0.6.0 line if still unreleased, otherwise a new
version section.

## Risks And Recovery

- **Double-count with real reflow.** Same trap as single-container: the offsets
  reclaim/vacate space, so the demo must hide the dragged card, not collapse its
  slot, or the real layout reclaims the source space twice. Mitigation: the demo
  hides; a test asserts the measured rects are unchanged while offsets apply.
- **Two index spaces.** Cross-container mixes the source container's index space
  (removal) and the target's (insertion); an off-by-one opens the gap one slot
  wrong. Mitigation: `toIndex` is taken straight from the resolved preview move
  (remove-then-insert space, same value the commit uses), and tests pin the
  exact shifted set in both columns.
- **Mid-drag inconsistent state.** While the pointer is between columns the
  preview may briefly resolve to neither; the resolver must return empty rather
  than a partial shift. Mitigation: return `{}` when the move cannot be
  resolved, tested.
- **Public surface growth.** A new resolver type, input, and built-ins.
  Mitigation: mirror the established `SortableMultiMoveResolver` shape; keep it
  opt-in with a `none` default.
- Recovery: each group is a separate commit on this branch; the feature is inert
  until a resolver is set, so reverting is a one-line default change or a clean
  commit revert.

## Progress

- [x] Branch `feat/sortable-multi-container-offsets` created from
      `release/0.6.0` (post-merge, gate green).
- [x] Group 1 — core cross-container offset built-ins + unit tests
      (`SortableMultiOffsetResolver`, `SortableMultiOffsetInput`,
      `SortableMultiOffsets.verticalLists`/`horizontalLists`/`none`; same
      container delegates to the single-list logic; 21 offset tests green).
- [x] Group 2 — adapter wiring + widget tests
      (`SortableMultiScope.offsetResolver` on both adapters, fed the resolved
      preview move; flutter multi-scope tests cover same-column, cross-column,
      and the no-resolver-zero case).
- [x] Group 3 — demo, docs, ADR, changelog (both board demos animate
      `details.offset` and hide the dragged card; ADR 0026; 0.6.0 changelogs
      and the website recipe extended; a gallery test drives a drag and asserts
      a displaced card carries an offset transform).
- [x] Full validation lane green; Jaspr `@TestOn('browser')` offset/multi/
      overlay suites green under `-p chrome`; branch merged into
      `release/0.6.0`; plan moved to `docs/plans/completed/`.

## Decisions

- 2026-07-23: New `SortableMultiOffsetResolver` type rather than reusing
  `SortableOffsetResolver`. The single-list resolver cannot express a
  cross-container move (two lists, removal plus insertion), and multi already
  has a parallel `SortableMultiMoveResolver`, so the shape is precedented.
- 2026-07-23: Same-container offsets delegate to the single-list built-ins, so
  the list case has one implementation and cross-container adds only the
  two-column shift.

Promote the cross-container offset contract into `docs/decisions/` when Group 1
lands (addendum to ADR 0025 or a new record).

## Validation

- Focused: `dart test packages/dnd_kit` for the built-ins;
  `flutter test packages/dnd_kit_flutter` for wiring, the invariants, and the
  no-oscillation guard; `dart test packages/dnd_kit_jaspr -p chrome` on the
  `@TestOn('browser')` files for the measured-rect invariant.
- End-to-end: the multi-container gallery demo with a cross-column drag test.
- Repository-required: `dart run melos run validate`; run the Jaspr
  `@TestOn('browser')` files explicitly since the melos lane skips them.

## Result

Cross-container offsets shipped on the 0.6.0 line. `SortableMultiScope` takes an
`offsetResolver` (default `SortableMultiOffsets.none`); with
`SortableMultiOffsets.verticalLists` a board opens a live gap within a column
and across columns — the source column closes the vacated slot and the target
column opens the landing slot — with the library reporting geometry and the app
animating it.

Verified:

- `dart run melos run validate` green across all six workspace packages.
- Core: same-container offsets equal the single-list result; cross-container
  shifts the source tail up and the target tail down by the dragged extent;
  end-of-target, missing-extent, missing-container, and unmeasured-target cases
  behave as specified.
- Flutter widget tests: same-column and cross-column drags shift the right
  cards; a drag with no resolver leaves every offset zero.
- Jaspr `@TestOn('browser')` offset/multi/overlay suites pass under `-p chrome`.
- Both galleries open a live gap on the board; a gallery widget test drives a
  real drag and asserts a displaced card carries an offset transform.

Delivered vs. deferred:

- Delivered: same- and cross-container offsets for list columns, opt-in, both
  adapters, both demos.
- Deferred (ADR 0026 follow-up): true two-dimensional grid offsets, and a
  `DndDragOverlay` drop animation.

Design decisions held: a dedicated `SortableMultiOffsetResolver` (the
single-list resolver cannot express a two-list removal-plus-insertion move);
same-container delegates to the single-list built-ins for one source of truth;
the demo hides the dragged card rather than collapsing it, consistent with the
single-container pattern.
