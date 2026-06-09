# US-018 Flutter Mouse Touch Input Kind Specialization

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_flutter` must preserve Flutter pointer device kind information for
mouse and touch drag activation so applications can distinguish desktop/web
mouse drags from mobile touch drags while keeping generic pointer behavior for
other pointer devices.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- Mouse pointer activation reports `DndInputKind.mouse`.
- Touch pointer activation reports `DndInputKind.touch`.
- Other pointer device kinds continue to report the generic
  `DndInputKind.pointer`.
- Mouse and touch specialization works through whole-draggable activation.
- Mouse and touch specialization remains compatible with drag handles.
- Touch long-press activation reports `DndInputKind.touch`.
- Pointer sensor runtime tests cover specialized input kind preservation.
- Widget tests cover mouse, touch, drag handle, and long-press behavior.

## Design Notes

- Commands: `fvm dart format .`, `fvm flutter test packages/dnd_kit_flutter`,
  `fvm dart analyze`, and `scripts/bin/harness-cli story verify US-018`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: no new public widget API; `DndDraggable` maps Flutter pointer device
  kinds into existing core `DndInputKind` values.
- Tables: none.
- Domain rules: applications still own user data and collection mutation.
- UI surfaces: mouse/touch input classification only; overlays, auto-scroll,
  sortable presets, and platform build proof remain out of scope.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-018 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm flutter test packages/dnd_kit_flutter` passes, including `DndPointerSensor` input-kind tests. |
| Integration | Widget tests prove mouse/touch behavior through `DndScope`, `DndController`, `DndDraggable`, and `DndDragHandle`. |
| E2E | Not required; no full example app flow changes in this story. |
| Platform | Not required; input kind specialization uses Flutter widget tests only. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds the fifth Phase 3 story packet and durable matrix row.

## Evidence

- `fvm dart format .` passed.
- `fvm flutter test packages/dnd_kit_flutter` passed with 43 tests, including
  pointer sensor mouse/touch activation, whole-draggable mouse/touch, drag
  handle mouse, and touch long-press input-kind coverage.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-018` passed.
