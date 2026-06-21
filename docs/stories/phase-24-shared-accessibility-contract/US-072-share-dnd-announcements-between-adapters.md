# US-072 Share DndAnnouncements Between Adapters

## Status

implemented

## Lane

normal

## Product Contract

`DndAnnouncements` is a pure-Dart accessibility contract that should be shared
by the package family, not duplicated per adapter. `dnd_kit` must own the
announcement typedefs, default message builders, and public export surface so
`dnd_kit_flutter` and `dnd_kit_jaspr` both reuse one source of truth while
keeping their platform-specific execution local. This change must remain
backward-compatible for adapter users and is intended to continue the `0.3.1`
release line without forking accessibility copy across adapters.

## Relevant Product Docs

- `docs/ARCHITECTURE.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`
- `docs/stories/phase-15-jaspr-hardening/US-057-jaspr-keyboard-accessibility.md`
- `docs/stories/phase-23-flutter-accessibility-hardening/US-071-flutter-accessibility-hardening.md`

## Acceptance Criteria

- `dnd_kit` exports a shared `DndAnnouncements` contract and default builders
  without taking on any adapter dependency.
- `dnd_kit_flutter` and `dnd_kit_jaspr` both consume the shared contract
  instead of maintaining local copies.
- Adapter-local execution remains unchanged: Flutter keeps semantics
  announcement execution and Jaspr keeps `DndLiveRegion`.
- Default/custom-builder unit proof moves to the shared package so duplicate
  contract tests do not need to live in both adapters.
- Public adapter imports remain usable for application code after the
  extraction.
- README/story/release docs reflect that the contract is shared from `dnd_kit`
  while execution remains adapter-local.

## Design Notes

- Commands:
  `scripts/bin/harness-cli query matrix`
  `fvm dart test packages/dnd_kit`
  `fvm flutter test packages/dnd_kit_flutter`
  `fvm dart test packages/dnd_kit_jaspr`
  `fvm dart analyze packages/dnd_kit packages/dnd_kit_flutter packages/dnd_kit_jaspr`
- Queries:
  `rg -n "DndAnnouncements|DndDragStartAnnouncement|DndDragOverAnnouncement|DndDragEndAnnouncement|DndDragCancelAnnouncement" packages docs`
- API:
  Move the announcement typedefs and `DndAnnouncements` to `package:dnd_kit`,
  export them from the core barrel, and update adapter imports/exports
  accordingly.
- Tables:
  none.
- Domain rules:
  Only the pure-Dart contract moves. No adapter runtime, focus, semantics, DOM,
  or live-region execution behavior moves into core.
- UI surfaces:
  none directly; this story changes shared API ownership, not end-user visual
  behavior.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-072 --unit 1 --integration 1 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm dart test packages/dnd_kit` covers the shared `DndAnnouncements` defaults and custom builders. |
| Integration | `fvm flutter test packages/dnd_kit_flutter` and `fvm dart test packages/dnd_kit_jaspr` still pass after the adapters are rewired to the shared contract. |
| E2E | Not required; this extraction does not change browser/app-level user flows. |
| Platform | `fvm dart analyze packages/dnd_kit packages/dnd_kit_flutter packages/dnd_kit_jaspr` stays clean. |
| Release | Core/adapter docs and story evidence reflect shared-contract ownership accurately. |

## Harness Delta

Creates the first Phase 24 story packet for shared accessibility contract
extraction and gives the follow-up parity cleanup a durable matrix row.

## Evidence

- Created 2026-06-20 as a follow-up to `US-071` after confirming that the new
  Flutter announcement contract duplicated the existing Jaspr pure-Dart
  contract instead of sharing it from `dnd_kit`.
- Implemented 2026-06-20:
  - Moved `DndAnnouncements` and its typedefs into `packages/dnd_kit`.
  - Rewired both adapters to consume the shared core contract while keeping
    Flutter semantics announcements and Jaspr `DndLiveRegion` execution
    adapter-local.
  - Moved default/custom announcement contract unit proof into
    `packages/dnd_kit/test/src/announcements_test.dart`.
  - Removed duplicate adapter-local announcement contract files and tests.
- Proof:
  - `fvm dart test packages/dnd_kit` -> pass.
  - `fvm flutter test packages/dnd_kit_flutter` -> pass.
  - `fvm dart test packages/dnd_kit_jaspr` -> pass.
  - `fvm dart analyze packages/dnd_kit packages/dnd_kit_flutter packages/dnd_kit_jaspr`
    -> No issues found.
  - `pubspec.yaml` metadata updated so `dnd_kit` is `0.3.1` and both adapters
    now depend on `dnd_kit: ^0.3.1`.
