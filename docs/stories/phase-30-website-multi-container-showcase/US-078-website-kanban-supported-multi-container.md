# US-078 Upgrade website Kanban showcase to the supported Jaspr multi-container surface

## Status

implemented

## Lane

normal

## Product Contract

The hosted Jaspr homepage uses the supported production multi-container surface
for its Kanban showcase, so the public website demonstrates the same
board/list contract shipped by `dnd_kit_jaspr` instead of a stale app-owned
assembly path built on raw generic droppables.

## Relevant Product Docs

- `docs/product/release-roadmap.md`
- `website/README.md`
- `website/lib/site.dart`

## Acceptance Criteria

- `website/lib/sections/kanban_showcase.dart` uses `SortableMultiScope`,
  `SortableMultiContainerArea`, and `SortableMultiItem` for the homepage board.
- The homepage preserves app-owned rendering, telemetry, overlay, and state
  mutation while delegating default multi-container semantics to the library.
- Website copy no longer claims the homepage Kanban is built because Jaspr only
  supports single-container sortable presets.
- Product roadmap records the website adoption slice as the next completed
  multi-container follow-up after Phase 29.

## Design Notes

- Commands: `fvm dart analyze website`; `fvm dart run tool/affected_validate.dart validate --files=website/lib/sections/kanban_showcase.dart,website/lib/site.dart`; `cd website && tool/styles.sh --minify && fvm dart pub global run jaspr_cli:jaspr build --verbose`
- Queries: `rg -n "kanban|multi-container|SortableMultiScope" website docs`
- API: `SortableMultiScope`, `SortableMultiContainerArea`, `SortableMultiItem`
- Domain rules: library owns default board/list move semantics; website still
  owns visuals and collection mutation.
- UI surfaces: website homepage Kanban showcase, homepage section copy, website
  architecture README, release roadmap.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-078 --unit 0 --integration 1 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | n/a (website adoption slice; library contract already covered in package tests) |
| Integration | `fvm dart run tool/affected_validate.dart validate --files=website/lib/sections/kanban_showcase.dart,website/lib/site.dart` passes for the website workspace package. |
| E2E | n/a |
| Platform | `fvm dart analyze website` passes and `cd website && tool/styles.sh --minify && fvm dart pub global run jaspr_cli:jaspr build --verbose` succeeds. |
| Release | Homepage docs and roadmap describe the hosted Kanban as a supported multi-container showcase. |

## Harness Delta

Adds Phase 30 and a normal-lane website adoption story so the post-Phase-29
follow-up is tracked as product work rather than left implicit in ADR 0022.

## Evidence

- Implemented 2026-06-24.
- The homepage Kanban now uses `SortableMultiScope`,
  `SortableMultiContainerArea`, and `SortableMultiItem`.
- Website copy and roadmap now describe the showcase as the supported Jaspr
  multi-container surface.
