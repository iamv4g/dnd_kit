# US-019 Flutter Adapter Source Grouping

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_flutter` source files should be grouped by adapter responsibility so
scope/controller, widgets, sensors, and measuring code are easier to navigate
without changing the package's public API or runtime behavior.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `packages/dnd_kit_flutter/lib/src/scope/` contains controller and scope
  implementation files.
- `packages/dnd_kit_flutter/lib/src/widgets/` contains draggable, droppable,
  and drag handle implementation files.
- `packages/dnd_kit_flutter/lib/src/sensors/` contains pointer sensor and
  long-press activation implementation files.
- `packages/dnd_kit_flutter/lib/src/measuring/` contains measuring
  implementation files.
- `packages/dnd_kit_flutter/test/src/` mirrors the same responsibility groups
  as `lib/src/` for scope, widgets, sensors, and measuring tests.
- Existing flat Flutter adapter tests are moved into the matching grouped test
  folders; no implementation-focused test remains directly under
  `packages/dnd_kit_flutter/test/src/*.dart`.
- `packages/dnd_kit_flutter/lib/dnd_kit_flutter.dart` continues to export the
  same public API names after the move.
- Internal imports are updated to the grouped paths with no stale references to
  the old flat `lib/src/*.dart` layout.
- Existing Flutter adapter tests continue to pass with no behavior assertions
  removed or weakened.

## Design Notes

- Commands: `fvm dart format .`, `fvm flutter test packages/dnd_kit_flutter`,
  `fvm dart analyze`, and `scripts/bin/harness-cli story verify US-019`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: no public type, constructor, callback, or export contract changes; this
  is an internal source layout refactor.
- Tables: none.
- Domain rules: applications still own user data and collection mutation.
- UI surfaces: none; this story changes file organization only.
- Target layout:

```text
lib/
  dnd_kit_flutter.dart
  src/
    scope/
      controller.dart
      scope.dart
    widgets/
      draggable.dart
      droppable.dart
      drag_handle.dart
    sensors/
      pointer_sensor.dart
      long_press_activation.dart
    measuring/
      measuring.dart
```

Test layout must mirror the same responsibility groups:

```text
test/
  src/
    scope/
      controller_test.dart
      scope_test.dart
    widgets/
      draggable_test.dart
      droppable_test.dart
    sensors/
      pointer_sensor_test.dart
    measuring/
      measuring_test.dart
```

If a group has no tests yet, the folder may be introduced only when the first
matching test exists; the implementation must still avoid leaving moved tests in
the old flat `test/src/*.dart` layout.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-019 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm flutter test packages/dnd_kit_flutter` passes with the grouped adapter test suite. |
| Integration | Existing widget tests continue to prove `DndScope`, `DndController`, `DndDraggable`, `DndDroppable`, `DndDragHandle`, and sensor interactions. |
| E2E | Not required; no example app flow changes in this story. |
| Platform | Not required; source grouping has no platform-specific behavior. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds a maintenance/architecture story packet after US-018 so source grouping
  can be implemented and verified independently from input-kind behavior.

## Evidence

- `fvm dart format .` passed; the public Flutter barrel export was formatted
  after path updates.
- `fvm flutter test packages/dnd_kit_flutter` passed with 43 tests under the
  grouped `test/src/scope`, `test/src/widgets`, and `test/src/sensors`
  folders.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-019` passed.
