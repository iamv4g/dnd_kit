# US-039 Scroll-Driven Drag Overlay Alignment

## Status

implemented

## Lane

normal

## Product Contract

Active drag visuals and collision geometry stay aligned with the pointer when a
scrollable ancestor moves during the drag, including horizontally scrolled
Kanban boards and vertically scrolled columns.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- Drag overlays remain attached to the pointer when auto-scroll or manual
  scroll changes the source draggable's measured global rect during a drag.
- Collision detection uses stable active drag geometry derived from the drag
  origin plus the current session transform.
- Droppable measurements may still refresh while dragging so scroll-driven
  target changes remain detectable.
- Kanban board behavior is covered by the package-level regression that caused
  the published example drift.

## Design Notes

- Commands:
  - `fvm flutter test packages/dnd_kit/test/src/widgets/drag_overlay_test.dart`
  - `fvm flutter test examples/kanban_board`
  - `fvm dart analyze`
  - `fvm dart format .`
- Queries:
  - `scripts/bin/harness-cli query matrix`
- API:
  - No new public API.
- Tables:
  - Harness `story` proof row for `US-039`.
- Domain rules:
  - User data remains external to the library.
  - Scroll movement should update droppable target measurements without moving
    the active overlay away from the pointer.
- UI surfaces:
  - `DndDragOverlay`
  - Kanban board example

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-039 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | Package widget regression proves overlay position ignores source rect shifts during an active drag. |
| Integration | Kanban board widget tests continue to pass. |
| E2E | Not required. |
| Platform | Not required for this bugfix. |
| Release | `fvm dart analyze` and `fvm dart format .` pass. |

## Harness Delta

None expected.

## Evidence

- `fvm flutter test packages/dnd_kit/test/src/scope/controller_test.dart packages/dnd_kit/test/src/widgets/drag_overlay_test.dart`
  passed with 14 tests.
- `fvm flutter test packages/dnd_kit` passed with 107 tests.
- `fvm flutter test examples/kanban_board` passed with 5 tests.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-039` passed with
  `fvm dart run melos run validate`.
- `fvm dart pub publish --dry-run` in `packages/dnd_kit` built the
  `0.1.0-dev.2` archive and reported only the expected dirty git tree warning
  before commit.
