# US-067 Jaspr Example Feature Gallery

## Status

implemented

## Lane

normal

## Product Contract

`examples/jaspr_example_gallery` becomes a single runnable Jaspr client gallery
that demonstrates every supported `dnd_kit_jaspr` public surface, so a developer
evaluating the adapter can see — and drive in a real browser — generic
drag/drop, drag handle, drag overlay, sortable preset, drag-driven auto-scroll,
keyboard dragging, accessibility announcements, and movement modifiers, all over
the same shared `dnd_kit` runtime. The change is example-only: no package,
public API, or test-infrastructure change.

## Relevant Product Docs

- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `packages/dnd_kit_jaspr/lib/dnd_kit_jaspr.dart`
- `docs/stories/phase-20-jaspr-example-gallery/README.md`

## Acceptance Criteria

- The example renders a tabbed gallery; each tab is self-contained and uses the
  real shared runtime, not mocked drag behavior.
- Coverage includes every supported surface: `DndScope`/`DndController`,
  `DndDraggable`, `DndDroppable`, `DndDragHandle`, `DndDragOverlay`,
  `DndAutoScroll`, `DndLiveRegion` + custom `DndAnnouncements`, keyboard dragging
  (pickup/move/drop/cancel) with `aria-label`/`aria-describedby`, `SortableScope`
  + `SortableItem`, and `DndModifiers` (axis restriction + snap-to-grid).
- App-owned state stays external: lanes, list order, and bins are updated by app
  code from reported drag intent; the library reports intent only.
- The example stays SSR-safe and client-runnable with `jaspr serve` /
  `jaspr build`, with no new package dependencies beyond `jaspr`.
- No `dnd_kit`, `dnd_kit_flutter`, or `dnd_kit_jaspr` package source changes; no
  test-infrastructure changes.
- The example README documents each demo tab and how to run it.

## Design Notes

- Commands:
  `cd examples/jaspr_example_gallery && ~/.pub-cache/bin/jaspr build`
  `fvm dart analyze examples/jaspr_example_gallery`
  `cd examples/jaspr_example_gallery && ~/.pub-cache/bin/jaspr serve` (manual)
- Queries:
  `rg -n "DndAutoScroll|SortableScope|SortableItem|DndLiveRegion|DndAnnouncements|DndModifiers" examples/jaspr_example_gallery packages/dnd_kit_jaspr/lib`
- API:
  `DndScope`, `DndController`, `DndDraggable`, `DndDroppable`, `DndDragHandle`,
  `DndDragOverlay`, `DndAutoScroll`, `DndScrollAxis`, `DndLiveRegion`,
  `DndAnnouncements`, `SortableScope`, `SortableItem`, `SortableStrategies`,
  `DndModifiers`.
- Domain rules:
  The shared `DndRuntime` stays the only drag engine. The example owns DOM
  styling and app state only; modifiers are configured per-controller.
- UI surfaces:
  Tabbed gallery shell plus one component per demo under
  `examples/jaspr_example_gallery/lib/demos/`, with shared inline-style helpers.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-067 --unit 0 --integration 0 --e2e 1 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | N/A — example-only; package unit coverage is unchanged. |
| Integration | N/A — no package logic added; demos compose published components. |
| E2E | Chrome browser proof: each tab drives a real drag (pointer + keyboard) on `http://localhost:8080`, reorders/moves app-owned state, and the modifier/auto-scroll tabs show their effect. |
| Platform | `fvm dart analyze examples/jaspr_example_gallery` clean and `jaspr build` succeeds; SSR-safe import posture intact. |
| Release | Example README lists every demonstrated surface and run instructions. |

## Harness Delta

No Harness process change. New phase-20 trail records the example-coverage
slice that brings the runnable Jaspr example to surface parity with the adapter.

## Evidence

- Created 2026-06-18 after Phase 19 closed the adapter horizontal auto-scroll
  slices, leaving the runnable Jaspr example as the remaining surface-coverage
  gap.
- Verified 2026-06-19 against the renamed `examples/jaspr_example_gallery`
  workspace member and its feature-gallery docs.

## Proof

- `fvm dart analyze examples/jaspr_example_gallery` -> No issues found.
- `cd examples/jaspr_example_gallery && ~/.pub-cache/bin/jaspr build` ->
  completed successfully and wrote `/build/jaspr`.
