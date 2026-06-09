# US-022 Flutter Drag Overlay Foundation

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_flutter` exposes a `DndDragOverlay` widget that lets applications render
an independently positioned visual for the active drag session. The overlay is
derived from controller state, follows the active session transform, and leaves
application data ownership outside the library.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `DndDragOverlay` is exported from `dnd_kit_flutter`.
- The overlay renders nothing while the controller is idle, pending, or
  cancelled.
- The overlay renders while dragging and exposes active id, active rect,
  transform, session, and current over id to its builder.
- The overlay position follows the active measured rectangle plus the current
  drag transform.
- The overlay ignores pointer events by default so it does not block drag
  interactions beneath it.

## Design Notes

- Commands:
  - `fvm dart format .`
  - `fvm flutter test packages/dnd_kit_flutter`
  - `fvm dart analyze`
- Queries:
  - `scripts/bin/harness-cli query matrix`
- API:
  - `DndDragOverlay`
  - `DndDragOverlayBuilder`
  - `DndDragOverlayDetails`
  - `DndController.activeRect`
- Tables:
  - Harness `story` proof row for `US-022`.
- Domain rules:
  - User data remains external; overlay builder receives drag state only.
  - Overlay should be a Flutter adapter concern, not a core package concern.
- UI surfaces:
  - Flutter adapter widget tree, typically as a child of a full-size `Stack`.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id <id> --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | Flutter widget tests prove overlay lifecycle, details, positioning, and pointer ignoring. |
| Integration | `fvm flutter test packages/dnd_kit_flutter` passes. |
| E2E | Not required for this foundation slice. |
| Platform | Not required for this foundation slice. |
| Release | `fvm dart analyze` and `fvm dart format .` pass. |

## Harness Delta

None expected.

## Evidence

- `fvm dart format .` passed.
- `fvm flutter test packages/dnd_kit_flutter` passed with 57 tests, including
  `DndDragOverlay` lifecycle, builder details, positioning, and pointer
  ignoring coverage.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-022` passed.
