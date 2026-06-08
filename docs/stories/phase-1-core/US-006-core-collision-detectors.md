# US-006 Core Collision Detectors

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_core` must expose pure Dart collision detector contracts and built-in
algorithms that later controllers, measuring runtimes, sortable presets, and
Flutter adapters can share without depending on Flutter layout types.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `dnd_kit_core` exports a `DndCollisionDetector` typedef.
- Collision input exposes the active draggable rectangle, candidate droppable
  rectangles, and optional pointer coordinates without Flutter geometry types.
- Built-in detectors exist for closest center, closest corners, rectangle
  intersection, pointer within, and detector composition.
- Collision results are immutable value objects sorted by a clear score or
  ranking.
- `compose` returns the first detector result that has non-empty collisions.
- Unit tests cover multiple rectangle scenarios and public value behavior.

## Design Notes

- Commands: `fvm dart format .`, `fvm dart analyze`,
  `fvm dart test packages/dnd_kit_core`, and
  `scripts/bin/harness-cli story verify US-006`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: pure Dart collision contracts and built-in algorithms only; no
  controller, registry, modifier runtime, sensor implementation, or Flutter
  widget behavior in this story.
- Tables: none.
- Domain rules: applications still own user data and collection mutation.
- UI surfaces: none.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-006 --unit 1 --integration 0 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm dart test packages/dnd_kit_core` passes. |
| Integration | Not required; this story introduces only one package's pure Dart collision model. |
| E2E | Not required; no user-facing UI exists. |
| Platform | Not required; no Flutter/platform code exists. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds the fourth Phase 1 story packet and durable matrix row.

## Evidence

- `fvm dart format .` completed with no changes needed after implementation.
- `fvm dart analyze` passed with no issues.
- `fvm dart test packages/dnd_kit_core` passed with 43 tests.
- `scripts/bin/harness-cli story verify US-006` passed with
  `fvm dart test packages/dnd_kit_core`.
