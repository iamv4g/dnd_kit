# US-060 Core As Brand Package Rename

## Status

implemented

## Lane

high-risk

## Product Contract

The pure Dart engine, previously published as `dnd_kit_core`, becomes the
`dnd_kit` package, and the thin Flutter umbrella that previously held the
`dnd_kit` name is removed. Flutter apps depend on `dnd_kit_flutter`; Jaspr apps
depend on `dnd_kit_jaspr`; both build on `dnd_kit`. This implements ADR 0017,
which supersedes ADR 0014. The change is breaking for `dnd_kit 0.1.x` (Flutter
umbrella) users and discontinues `dnd_kit_core`. Engine git history must be
preserved through the rename.

## Relevant Product Docs

- `docs/decisions/0017-core-as-brand-package.md`
- `docs/decisions/0014-release-versioning-brand-home-strategy.md` (superseded)
- `docs/product/package-architecture.md`
- `packages/dnd_kit/pubspec.yaml`
- `packages/dnd_kit_flutter/pubspec.yaml`
- `packages/dnd_kit_jaspr/pubspec.yaml`

## Acceptance Criteria

- `packages/dnd_kit_core` is renamed to `packages/dnd_kit` via `git mv` so the
  engine's `lib/src/*` and `test/*` history is preserved as renames; the old
  Flutter umbrella package at `packages/dnd_kit` is removed.
- `dnd_kit` publishes `0.3.0-dev.0` as the pure Dart engine (name, description,
  repository path, library entry point `package:dnd_kit/dnd_kit.dart`). API
  surface is unchanged from `dnd_kit_core 0.2.0-dev.0`.
- `dnd_kit_flutter` and `dnd_kit_jaspr` bump to `0.3.0-dev.0` and depend on
  `dnd_kit: ^0.3.0-dev.0`; all `package:dnd_kit_core/...` imports become
  `package:dnd_kit/...`.
- Flutter examples (`basic_drag_drop`, `kanban_board`,
  `multi_container_sortable`) depend on `dnd_kit_flutter` and import
  `package:dnd_kit_flutter/dnd_kit_flutter.dart` instead of the removed umbrella;
  `jaspr_basic_drag_drop` overrides `dnd_kit` instead of `dnd_kit_core`.
- Root workspace membership and the `melos validate:full` script reference
  `packages/dnd_kit` (not `packages/dnd_kit_core`).
- Package docs, the architecture doc, ADR 0017, and ADR 0014's superseded status
  reflect the new topology; family tables drop the `dnd_kit_core` row.
- `dart pub get`, `fvm dart run melos run validate`, and
  `fvm dart pub publish --dry-run` for `packages/dnd_kit`,
  `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr` pass.

## Design Notes

- Commands:
  `dart pub get`
  `fvm dart run melos run validate`
  `cd packages/dnd_kit && fvm dart pub publish --dry-run`
  `cd packages/dnd_kit_flutter && fvm dart pub publish --dry-run`
  `cd packages/dnd_kit_jaspr && fvm dart pub publish --dry-run`
- Queries:
  `rg -n "dnd_kit_core|umbrella" packages examples docs`
- Domain rules: package-topology and release change; no runtime API change.
- The publish + `dnd_kit_core` discontinue act is irreversible and deferred to
  explicit human go-ahead.

## Validation

`scripts/bin/harness-cli story update --id US-060 --unit 0 --integration 0 --e2e 0 --platform 1`

| Layer | Expected proof |
| --- | --- |
| Unit | Not required; no logic change. Engine `dart test` runs as a regression check under the platform gate. |
| Integration | Not required beyond release/validation. |
| E2E | Not required for the rename act. |
| Platform | `dart pub get` + `fvm dart run melos run validate` + `fvm dart pub publish --dry-run` for the three packages pass with the finalized names/versions. |
| Release | Story records the publish order (`dnd_kit` -> `dnd_kit_flutter` -> `dnd_kit_jaspr`) and the `dnd_kit_core` discontinue step, or the exact blocker if deferred. |

## Harness Delta

No Harness process change. This story exists to keep the brand-as-core rename
explicit and auditable, with ADR 0017 superseding ADR 0014.

## Evidence

- Created 2026-06-17 after the owner committed to making `dnd_kit` the engine
  (brand-on-foundation) following US-059, accepting that Flutter users move to
  `dnd_kit_flutter` and that `dnd_kit_core` is discontinued (not unpublished).
- Implemented 2026-06-17 — see Proof below.

## Proof

- Restructure: `git mv packages/dnd_kit_core packages/dnd_kit` after removing the
  old umbrella; all engine `lib/src/*` and `test/*` files recorded as renames
  (history preserved). Entry point `lib/dnd_kit_core.dart` -> `lib/dnd_kit.dart`.
- Imports migrated: `package:dnd_kit_core/dnd_kit_core.dart` ->
  `package:dnd_kit/dnd_kit.dart` across adapters, tests, and examples; the three
  Flutter examples moved from the removed umbrella import to
  `package:dnd_kit_flutter/dnd_kit_flutter.dart`.
- `dart pub get` (workspace) resolved cleanly after the rename.
- `fvm dart run melos run validate` passed: format clean, analyze clean, engine
  `dart test packages/dnd_kit` (113 tests), Jaspr tests, Flutter adapter tests,
  and the kanban / multi-container / gallery example suites.
- `fvm dart pub publish --dry-run` passed for `packages/dnd_kit`,
  `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr` — only the expected
  dirty-git-tree warning and the intentional version-bump hint.
- Harness: intake #117, decision `0017-core-as-brand-package`, trace #133
  (detailed 3/3), `story verify US-060` = pass.

## Release

- Publish order when going live: `dnd_kit 0.3.0-dev.0` ->
  `dnd_kit_flutter 0.3.0-dev.0` -> `dnd_kit_jaspr 0.3.0-dev.0`.
- Then mark `dnd_kit_core` discontinued on pub.dev (published `0.1.0` /
  `0.2.0-dev.0` versions stay resolvable; no new releases).
- Actual publish and discontinue are intentionally deferred pending a clean
  commit and explicit human go-ahead for the irreversible steps.
