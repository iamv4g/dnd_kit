# US-013 Flutter Measuring And Collision Runtime

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_flutter` must measure registered Flutter draggable and droppable
widgets into core geometry and use the core collision detector contracts to
identify the droppable currently under an active drag.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `DndController` exposes current measured rectangles for adapter-owned
  draggable and droppable widgets without storing Flutter geometry types in
  core registrations.
- `DndDroppable` measures its global bounds and keeps the controller measuring
  data current while mounted.
- `DndDraggable` measures its global bounds when a drag begins and updates
  collision state while the drag moves.
- Disabled droppables remain registered but are ignored by collision runtime.
- `DndController.overId` reports the highest ranked droppable from the
  configured core `DndCollisionDetector`, or null when no candidate exists.
- Drag end events include the latest resolved `overId`.
- Widget tests cover measuring, collision updates, disabled droppable
  filtering, and end-event `overId`.

## Design Notes

- Commands: `fvm dart format .`, `fvm flutter test packages/dnd_kit_flutter`,
  `fvm dart analyze`, and `scripts/bin/harness-cli story verify US-013`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: adapter measuring registry and controller collision runtime only.
- Tables: none.
- Domain rules: applications still own user data and collection mutation.
- UI surfaces: no overlay, auto-scroll, sortable preset, drag handles, or new
  platform-specific sensors in this story.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-013 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm flutter test packages/dnd_kit_flutter` passes. |
| Integration | Widget tests prove measured Flutter bounds drive controller collision state through `DndScope`, `DndDraggable`, and `DndDroppable`. |
| E2E | Not required; no full example app flow changes in this story. |
| Platform | Not required; measurement uses Flutter widget tests only. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds the fourth Phase 2 story packet and durable matrix row.

## Evidence

- `fvm dart format .` passed with 29 Dart files already formatted after final
  cleanup.
- `fvm flutter test packages/dnd_kit_flutter` passed with 21 tests.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-013` passed.
