# US-014 Flutter Pointer Sensor Activation Constraints

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_flutter` must provide a real pointer sensor runtime that implements the
core `DndSensor` lifecycle and uses the core sensor activation constraint model
so a drag session starts only after the configured distance and delay
requirements are satisfied.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `dnd_kit_flutter` exposes `DndPointerSensor` as a Flutter adapter runtime
  implementing the core `DndSensor` interface.
- `DndPointerSensor` owns pointer pending, start, move, end, cancel, delay, and
  tolerance lifecycle behavior.
- `DndDraggable` exposes a pointer `activationConstraint` that defaults to
  `DndSensorActivationConstraint.none` and delegates pointer gestures to
  `DndPointerSensor`.
- Pointer gestures enter pending activation before `onDragStart` is emitted.
- Distance constraints prevent drag start until pointer movement reaches the
  configured threshold.
- Delay constraints prevent drag start until the configured delay elapses.
- Delayed activation cancels when pointer movement exceeds tolerance before
  the delay elapses.
- Ending or cancelling a gesture before activation cancels pending controller
  state and returns to idle.
- Existing unconstrained pointer gestures keep their drag lifecycle behavior.
- Widget tests cover distance, delay, tolerance cancellation, and early end
  cancellation.

## Design Notes

- Commands: `fvm dart format .`, `fvm flutter test packages/dnd_kit_flutter`,
  `fvm dart analyze`, and `scripts/bin/harness-cli story verify US-014`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: `DndPointerSensor` and `DndDraggable.activationConstraint`.
- Tables: none.
- Domain rules: applications still own user data and collection mutation.
- UI surfaces: pointer activation only; drag handles, long press, mouse/touch
  specialization, keyboard sensors, overlays, auto-scroll, and sortable presets
  remain out of scope.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-014 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm flutter test packages/dnd_kit_flutter` passes. |
| Integration | Widget tests prove pointer activation constraints through `DndScope`, `DndController`, and `DndDraggable`. |
| E2E | Not required; no full example app flow changes in this story. |
| Platform | Not required; pointer activation uses Flutter widget tests only. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds the first Phase 3 story packet and durable matrix row.

## Evidence

- `fvm dart format .` passed after formatting changed Dart files.
- `fvm flutter test packages/dnd_kit_flutter` passed with 28 tests, including direct `DndPointerSensor` runtime tests.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-014` passed.
