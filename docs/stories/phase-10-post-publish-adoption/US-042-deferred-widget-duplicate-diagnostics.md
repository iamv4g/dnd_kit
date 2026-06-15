# US-042 Deferred widget duplicate diagnostics

## Status

implemented

## Lane

normal

## Product Contract

Widget-registered draggable and droppable ids should recover actionable
duplicate diagnostics without reintroducing the lazy-list reconciliation crash
fixed by US-040. Duplicate ids created through `DndDraggable` or
`DndDroppable` remain tolerant during same-frame owner handoff, but if more
than one live widget instance still claims the same id after reconciliation,
the library emits a deferred warning through `DndDiagnosticsConfig.onWarning`.

Direct `DndRegistry` usage without an `owner` keeps the existing strict
behavior from US-033: duplicate registration warns immediately and still trips
the debug assertion.

## Relevant Product Docs

- `docs/product/api-principles.md`
- `docs/product/overview.md`
- `docs/stories/phase-8-production-hardening/US-033-diagnostics-duplicate-ids-registry-issues.md`
- `docs/stories/phase-10-post-publish-adoption/US-040-drag-inside-scrollable-and-lazy-lists/validation.md`
- Decision `docs/decisions/0011-owner-aware-registration.md`

## Acceptance Criteria

- A persistent duplicate `DndDraggable` id registered through widgets emits an
  actionable `onWarning` callback after the frame settles.
- A persistent duplicate `DndDroppable` id registered through widgets emits an
  actionable `onWarning` callback after the frame settles.
- A lazy-list owner handoff like the US-040 regression path does not assert,
  does not crash, and does not emit a duplicate warning when the old owner is
  disposed by the end of reconciliation.
- Direct `DndRegistry.registerDraggable` and `registerDroppable` calls without
  `owner` keep the current immediate warning plus debug assertion behavior.
- Duplicate warnings remain non-fatal in release mode and reuse the existing
  diagnostics surface (`DndDiagnosticsConfig` / `DndWarning`) unless
  implementation evidence proves a new code or field is necessary.

## Design Notes

- Commands:
  - `scripts/bin/harness-cli query matrix`
  - `fvm dart test packages/dnd_kit_core`
  - `fvm flutter test packages/dnd_kit`
  - `fvm dart run melos run validate`
- Queries:
  - `rg -n "duplicate|owner-aware|diagnostic|warning" docs packages`
- API:
  - Prefer keeping `DndDiagnosticsConfig` and `DndWarning` source-compatible.
  - Preserve `registerDraggable(..., owner: ...)` and
    `registerDroppable(..., owner: ...)` semantics from US-040.
- Domain rules:
  - Duplicate detection for widget-owned registrations should be deferred until
    after the current frame so transient remounts in lazy slivers are not
    treated as bugs.
  - Warning emission should be id-specific and actionable, matching the style
    established in US-033.
  - The implementation should avoid repeated warning spam for the same
    persistent duplicate while the registry state is unchanged.
- UI surfaces:
  - `DndDraggable`
  - `DndDroppable`
  - Any `SortableItem` flow that depends on widget registration

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-042 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm dart test packages/dnd_kit_core` keeps direct-registry duplicate warning/assertion coverage and adds any core-level deferred-diagnostics state tests if logic lands in `dnd_kit_core`. |
| Integration | `fvm flutter test packages/dnd_kit` proves persistent widget duplicates warn after a pump, while the US-040 lazy-list re-register path stays warning-free and crash-free. |
| E2E | Not required unless example coverage is needed to prove no warning spam in a real lazy-list reorder flow. |
| Platform | Not required beyond Flutter widget coverage. |
| Release | `fvm dart run melos run validate` passes with the new diagnostics coverage in place. |

## Harness Delta

- New story only; no Harness policy change expected.
- If implementation reveals that existing warning codes cannot distinguish
  direct-registry misuse from deferred widget duplicates cleanly, record the API
  choice in a durable decision before release-facing docs are updated.

## Evidence

- Implemented deferred owner-aware duplicate diagnostics in
  `packages/dnd_kit_core/lib/src/registry.dart` by tracking widget owner claims
  per id, coalescing a deferred check, and warning only when duplicate widget
  claims persist after reconciliation.
- `DndDraggable` and `DndDroppable` now update owner-aware registrations with
  `owner: this`, so widget metadata changes stay attached to the correct live
  owner during duplicate detection.
- `DndController` now supplies a post-frame scheduler to `DndRegistry`, so
  widget duplicate checks run after the current frame settles.
- `docs/product/api-principles.md` now documents that widget ids are last-wins
  within the frame but emit a deferred warning if duplicates remain after
  reconciliation.
- `packages/dnd_kit/CHANGELOG.md` notes the restored widget-level duplicate
  diagnostics.
- `fvm dart test packages/dnd_kit_core/test/src/registry_test.dart` passed with
  deferred warning, transient handoff, and no-warning-spam coverage.
- `fvm flutter test packages/dnd_kit/test/src/widgets/draggable_test.dart`
  passed, including persistent duplicate draggable warning coverage.
- `fvm flutter test packages/dnd_kit/test/src/widgets/droppable_test.dart`
  passed, including persistent duplicate droppable warning coverage.
- `fvm flutter test packages/dnd_kit/test/src/widgets/draggable_in_scrollable_test.dart`
  passed, confirming the lazy-list re-register path still stays warning-free and
  crash-free.
- `fvm dart analyze` passed with no issues.
- `fvm flutter test packages/dnd_kit` passed.
- `fvm dart run melos run validate` passed, covering workspace format, analyze,
  core tests, package tests, and example widget suites.
