# US-012 DndDroppable Foundation

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_flutter` must expose a first `DndDroppable` widget that lets Flutter
applications register droppable metadata with the nearest `DndScope` controller
while keeping application data and collection mutation outside the library.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `dnd_kit_flutter` exports `DndDroppable`.
- `DndDroppable` requires a stable `DndId`, a child, and a surrounding
  `DndScope`.
- `DndDroppable` registers a `DndDroppableRegistration` with the nearest
  controller registry and unregisters it when disposed.
- Updating id, disabled state, data, or controller scope keeps registry metadata
  current without leaking stale entries.
- Disabled droppables remain registered as disabled metadata.
- The widget does not introduce measuring, collision runtime, overlay,
  auto-scroll, sortable behavior, or application-owned data mutation.
- Widget tests cover registration, registry updates, controller changes,
  disabled metadata, and unregistering on disposal.

## Design Notes

- Commands: `fvm dart format .`, `fvm flutter test packages/dnd_kit_flutter`,
  `fvm dart analyze`, and `scripts/bin/harness-cli story verify US-012`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: Flutter adapter widget foundation only.
- Tables: none.
- Domain rules: applications own user data and collection mutation.
- UI surfaces: `DndDroppable` wraps a child without adding gestures.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-012 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm flutter test packages/dnd_kit_flutter` passes. |
| Integration | Widget tests prove registration behavior through `DndScope` and `DndController`. |
| E2E | Not required; no complete drag/drop flow exists yet. |
| Platform | Not required; no platform-specific target behavior exists yet. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds the third Phase 2 story packet and durable matrix row.

## Evidence

- `fvm dart format .` passed with 28 Dart files already formatted.
- `fvm flutter test packages/dnd_kit_flutter` passed with 18 tests.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-012` passed.
