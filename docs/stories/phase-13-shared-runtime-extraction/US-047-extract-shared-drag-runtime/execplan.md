# Exec Plan

## Goal

Move the framework-neutral drag runtime and measuring-cache contract from
`dnd_kit_flutter` into `dnd_kit_core` so Flutter and the future Jaspr adapter
share one drag engine, with zero public API or behavior change for current
Flutter users.

## Scope

In scope:

- Move `DndMeasuringRegistry` + `DndMeasurementStatus` to `dnd_kit_core`.
- Extract a pure-Dart `DndRuntime` from Flutter `DndController`.
- Re-wrap Flutter `DndController` as a thin `ChangeNotifier` over `DndRuntime`.
- Move the sortable contract + strategy math (`SortableMoveDetails`,
  `SortableMoveCallback`, `SortableStrategy`, `SortableStrategyInput`,
  `SortableStrategies`) to `dnd_kit_core` (SPEC_JASPR §4.5).
- Extract the DOM-free auto-scroll edge/velocity math
  (`DndAutoScrollOptions`, `dndAutoScrollVelocity`) to `dnd_kit_core`
  (SPEC_JASPR §6.4); keep the Flutter ticker/render-box/scroll execution.
- Re-export moved types from `dnd_kit_flutter` to preserve its public surface.
- Add reusable core runtime, measuring, sortable, and auto-scroll contract tests.
- Update `docs/ARCHITECTURE.md` and `docs/product/package-architecture.md`.

Out of scope:

- Any Jaspr adapter code.
- The Flutter auto-scroll widget/ticker/scroll-execution layer (stays adapter-specific).
- Behavior changes.

## Risk Classification

Risk flags:

- Public contracts (types move between published packages).
- Existing behavior (test-covered `DndController` and measuring).
- Cross-platform (sets up the Flutter/Jaspr split).
- Multi-domain (core + flutter).

Hard gates:

- None (no auth, data, audit, external provider, or validation weakening).
  4+ non-gate flags ⇒ high-risk lane.

## Work Phases

1. Discovery — controller, measuring, barrels, tests, pubspecs read. Done.
2. Design — `DndRuntime` shape + re-export strategy. See `design.md`.
3. Validation planning — see `validation.md`.
4. Implementation:
   1. Slice 1: measuring registry → core + re-export; tests green.
   2. Slice 2: `DndRuntime` → core; Flutter `DndController` delegates; tests green.
5. Verification — `melos analyze` + `melos test`; confirm Flutter public API
   unchanged (no symbol removed from the barrel).
6. Harness update — record story proof + evidence; ADR 0015.

## Stop Conditions

Pause for human confirmation if:

- Any change would alter `DndController`'s public method/getter signatures.
- A moved type cannot be re-exported without breaking existing imports.
- `DndRuntime` cannot be made Flutter-free without losing behavior parity.
- Validation requirements would need to be weakened.
