# US-066 Jaspr Axis-Aware Auto-Scroll Adoption

## Status

planned

## Lane

normal

## Product Contract

`dnd_kit_jaspr` adopts the shared axis-aware auto-scroll contract so Jaspr
scroll containers can auto-scroll horizontally through the same
`dndAutoScrollVelocity(...)` math already used by `dnd_kit` and
`dnd_kit_flutter`, while preserving current vertical behavior and SSR safety.
This story also decides whether Jaspr should keep auto-scroll execution inside
`DndAutoScroll` component state or introduce a dedicated controller surface; if
no new reuse or lifecycle need is proven, the component-owned execution model
remains the contract.

## Relevant Product Docs

- `docs/product/release-roadmap.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/decisions/0020-axis-aware-auto-scroll.md`
- `docs/stories/phase-15-jaspr-hardening/US-056-jaspr-auto-scroll-execution.md`
- `docs/stories/phase-19-horizontal-auto-scroll/README.md`
- `packages/dnd_kit_jaspr/lib/src/widgets/auto_scroll.dart`

## Acceptance Criteria

- `dnd_kit_jaspr` `DndAutoScroll` exposes axis selection with vertical default
  behavior preserved for existing call sites.
- Horizontal Jaspr auto-scroll executes through DOM `scrollLeft`,
  `scrollWidth`, and `clientWidth`, reusing the shared core velocity math
  without forking the threshold or curve.
- Browser tests cover horizontal leading/trailing edge scroll, extent
  clamping, and post-scroll collision refresh against a target scrolled into
  view.
- The story explicitly resolves the controller-abstraction question:
  - either Jaspr keeps component-owned auto-scroll execution and records why a
    dedicated controller surface is not yet justified;
  - or Jaspr introduces a dedicated controller surface with clear lifecycle and
    reuse benefits documented in code and story evidence.
- SSR safety is preserved: no top-level `dart:js_interop`, all DOM access stays
  behind `kIsWeb`, and no Flutter-only abstractions enter the Jaspr adapter.
- No Flutter package behavior changes in this story.

## Design Notes

- Commands:
  `fvm dart test packages/dnd_kit_jaspr`
  `cd packages/dnd_kit_jaspr && fvm dart test -p chrome test/auto_scroll_browser_test.dart`
  `fvm dart analyze packages/dnd_kit_jaspr`
- Queries:
  `scripts/bin/harness-cli query matrix`
  `rg -n "DndAutoScroll|DndScrollAxis|scrollLeft|scrollTop|markAllDirty|Timer" packages/dnd_kit_jaspr docs/stories/phase-15-jaspr-hardening docs/stories/phase-19-horizontal-auto-scroll`
- API:
  `DndAutoScroll`
  `DndScrollAxis`
  `dndAutoScrollVelocity`
  optional Jaspr-side auto-scroll controller surface only if the story proves it
  materially improves lifecycle/reuse over the current component-owned model.
- Domain rules:
  The shared `DndRuntime` remains the only drag engine. Jaspr owns DOM
  measuring and browser scroll execution only. Any controller-abstraction
  decision must preserve that separation and avoid inventing adapter-local
  velocity math.
- UI surfaces:
  Jaspr scroll containers under `DndScope`, plus any existing example or test
  fixture used to prove horizontal browser scrolling.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-066 --unit 1 --integration 1 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | Existing shared-core axis math remains green; any Jaspr-local helper logic for axis selection or controller wiring is covered in `packages/dnd_kit_jaspr` tests. |
| Integration | `fvm dart test packages/dnd_kit_jaspr` passes with component-level coverage for horizontal configuration and teardown behavior. |
| E2E | Chrome browser auto-scroll coverage proves `scrollLeft` advances in the edge band and collision refresh works after scroll without another pointer move. |
| Platform | `fvm dart analyze packages/dnd_kit_jaspr` passes and SSR-safe import posture remains intact. |
| Release | Public exports/docs/changelog mention the Jaspr horizontal auto-scroll surface and record the controller-abstraction outcome. |

## Harness Delta

No Harness process change expected. This story extends the existing Phase 19
adapter-adoption trail and should update durable evidence with the chosen
Jaspr execution shape.

## Evidence

- Created 2026-06-18 after `US-065` closed the Flutter execution slice.
- This story is the planned Jaspr follow-up for Phase 19 and explicitly pulls
  the `DndAutoScrollController` question into scope so the adapter contract is
  decided by code and durable story evidence rather than by ad hoc discussion.
