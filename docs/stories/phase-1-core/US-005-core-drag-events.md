# US-005 Core Drag Event Models

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_core` must expose pure Dart drag event models that later controllers,
sensors, collision detectors, sortable presets, and Flutter callbacks can share
without depending on Flutter or user-owned data.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `dnd_kit_core` exports drag event models for start, move, over, end, and
  cancel lifecycle notifications.
- Drag events expose the active draggable id, session data, pointer movement,
  transform, and input kind without Flutter geometry types.
- Over and end events can report a nullable droppable id without requiring a
  collision detector implementation in this story.
- Cancel events expose the active draggable id, optional session data, and
  cancel reason so pending and active cancellations can share one model.
- Event objects are immutable value objects with predictable equality, hash
  codes, and readable `toString` output.
- Unit tests cover the public behavior introduced by this story.

## Design Notes

- Commands: `fvm dart format .`, `fvm dart analyze`,
  `fvm dart test packages/dnd_kit_core`, and
  `scripts/bin/harness-cli story verify US-005`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: pure Dart drag event payloads only; no controller, registry, collision
  detector, modifier runtime, sensor implementation, or Flutter widget behavior
  in this story.
- Tables: none.
- Domain rules: applications still own user data and collection mutation.
- UI surfaces: none.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-005 --unit 1 --integration 0 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm dart test packages/dnd_kit_core` passes. |
| Integration | Not required; this story introduces only one package's pure Dart event models. |
| E2E | Not required; no user-facing UI exists. |
| Platform | Not required; no Flutter/platform code exists. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds the third Phase 1 story packet and durable matrix row.

## Evidence

- `fvm dart format .` formatted `packages/dnd_kit_core/lib/src/events.dart`.
- `fvm dart analyze` passed with no issues.
- `fvm dart test packages/dnd_kit_core` passed with 32 tests.
- `scripts/bin/harness-cli story verify US-005` passed with
  `fvm dart test packages/dnd_kit_core`.
