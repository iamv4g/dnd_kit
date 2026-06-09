# US-025 Sortable Scope And Item Foundation

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_sortable` provides the first stable sortable preset surface by
introducing a scope, sortable item widget, and move intent details. The preset
composes existing Flutter drag-and-drop primitives, reports reorder intent, and
keeps application-owned collections outside the library.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `SortableScope` owns the sortable item order supplied by the application and
  exposes a `DndController` through the underlying `DndScope`.
- `SortableItem` registers itself as both draggable and droppable using the
  nearest sortable scope.
- Dropping one sortable item over another emits `SortableMoveDetails` with
  `activeId`, `overId`, `oldIndex`, and `newIndex`.
- The sortable preset reports intent only and does not mutate the application
  list.
- Disabled sortable items stay registered as disabled drag/drop metadata.
- Existing core, Flutter adapter, and umbrella exports remain source-compatible.

## Design Notes

- Commands:
  - `fvm dart format .`
  - `fvm flutter test packages/dnd_kit_sortable`
  - `fvm dart analyze`
- Queries:
  - `scripts/bin/harness-cli query matrix`
- API:
  - `SortableScope`
  - `SortableItem`
  - `SortableItemBuilder`
  - `SortableItemDetails`
  - `SortableMoveDetails`
- Tables:
  - Harness `story` proof row for `US-025`.
- Domain rules:
  - User data remains external; sortable callbacks report reorder intent only.
  - Strategy-specific vertical, horizontal, and grid placement logic remains
    future work.
- UI surfaces:
  - Flutter sortable subtree backed by `DndScope`, `DndDraggable`, and
    `DndDroppable`.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-025 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | Widget tests prove scope lookup, item drag/drop registration, move intent details, disabled state, and external data ownership. |
| Integration | `fvm flutter test packages/dnd_kit_sortable` passes. |
| E2E | Not required for this preset foundation slice. |
| Platform | Not required for this preset foundation slice. |
| Release | `fvm dart analyze` and `fvm dart format .` pass. |

## Harness Delta

None expected.

## Evidence

- `fvm dart format .` passed.
- `fvm flutter test packages/dnd_kit_sortable` passed with 8 sortable widget
  tests.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-025` passed.
