# US-059 Jaspr First Development Release Standardization

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_jaspr` has not published a public package release yet. After Phase C
hardening closes with US-058, the repository must standardize the package's
release metadata, changelog presentation, and publish proof so the first public
Jaspr adapter release ships intentionally on a shared-runtime dev line
(`0.2.0-dev.0`) instead of pretending it can ship against the already-published
`dnd_kit_core 0.1.0` / `dnd_kit_flutter 0.1.0` artifacts, which predate the
runtime extraction in US-047.

## Relevant Product Docs

- `docs/product/package-architecture.md`
- `docs/decisions/0014-release-versioning-brand-home-strategy.md`
- `docs/stories/phase-15-jaspr-hardening/README.md`
- `docs/stories/phase-15-jaspr-hardening/US-058-jaspr-diagnostics-alignment.md`
- `packages/dnd_kit_jaspr/pubspec.yaml`
- `packages/dnd_kit_jaspr/CHANGELOG.md`

## Acceptance Criteria

- `dnd_kit_core` publishes a new development release that includes the shared
  runtime surface (`DndRuntime`, measuring registry, shared pointer sensor,
  sortable math, auto-scroll math) rather than pointing Jaspr at the already
  published `0.1.0` core.
- `dnd_kit_flutter` publishes a matching development release that depends on
  the new core dev line and carries the `DndController.runtime` /
  `DndPointerSensor(runtime: ...)` shared-runtime changes.
- `dnd_kit_jaspr` publishes its first public package release as
  `0.2.0-dev.0`, with package metadata and dependency constraints reflecting the
  actual shipped surface and the new core dev line.
- The package changelog clearly presents the first published Jaspr release
  without implying that an unpublished version was already available on pub.dev.
- `dart pub publish --dry-run` succeeds for `packages/dnd_kit_core`,
  `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr`, and the story
  records the exact publish command/order and any follow-up release notes.
- Package-facing docs (`README.md`, changelog, family cross-links if touched)
  stay aligned with ADR 0014: adapters may ship dev releases directly while the
  `dnd_kit` umbrella remains stable-only.

## Design Notes

- Commands:
  `fvm dart run melos run validate`
  `cd packages/dnd_kit_core && fvm dart pub publish --dry-run`
  `cd packages/dnd_kit_flutter && fvm dart pub publish --dry-run`
  `cd packages/dnd_kit_jaspr && fvm dart pub publish --dry-run`
  `scripts/bin/harness-cli query matrix`
- Queries:
  `rg -n "0\\.1\\.0|0\\.2\\.0-dev|Unreleased|publish" packages/dnd_kit_core packages/dnd_kit_flutter packages/dnd_kit_jaspr docs`
- API:
  Package versioning and release metadata only; no new runtime API expected.
- Domain rules:
  This is a release-standardization story, not a feature story. It should ship
  only after the Phase C hardening surface is complete and validated.
- UI surfaces:
  pub.dev/package-facing metadata and documentation for `dnd_kit_jaspr`.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-059 --unit 0 --integration 0 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | Not required unless release prep reveals package-local logic changes. |
| Integration | Not required unless docs or examples need executable proof beyond release validation. |
| E2E | Not required for the release act itself. |
| Platform | `fvm dart run melos run validate` plus `fvm dart pub publish --dry-run` from `packages/dnd_kit_core`, `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr` pass with finalized version/changelog metadata and dependency order. |
| Release | Story records the publish order and outcome for `dnd_kit_core 0.2.0-dev.0`, `dnd_kit_flutter 0.2.0-dev.0`, and the first public `dnd_kit_jaspr 0.2.0-dev.0` release, or the exact blocker if publishing is deferred. |

## Harness Delta

No Harness process change expected. This story exists to keep the first Jaspr
package release explicit and auditable after the adapter hardening stories.

## Evidence

- Created 2026-06-16 after confirming that `dnd_kit_jaspr` is still unpublished
  while its local changelog already contains `0.1.0-dev.0` plus `Unreleased`.
- Sequenced after US-058 by user direction so diagnostics parity lands before
  the first public Jaspr dev release.
- Corrected 2026-06-17 after checking pub.dev:
  - `dnd_kit_core`, `dnd_kit_flutter`, and `dnd_kit` are published at `0.1.0`,
    while `dnd_kit_jaspr` still returns `404`.
  - The published `0.1.0` core/flutter artifacts predate US-047 and therefore do
    not include the shared runtime extraction required by Jaspr.
  - The story target therefore moves from a Jaspr-only `0.1.0-dev.1` release to
    a coordinated shared-runtime dev line:
    `dnd_kit_core 0.2.0-dev.0` -> `dnd_kit_flutter 0.2.0-dev.0` ->
    `dnd_kit_jaspr 0.2.0-dev.0`.
- Implemented 2026-06-17:
  - Bumped `packages/dnd_kit_core` to `0.2.0-dev.0` and updated its pub.dev
    surface (`pubspec` description, README, CHANGELOG) to reflect the shared
    runtime now living in core.
  - Bumped `packages/dnd_kit_flutter` to `0.2.0-dev.0` with
    `dnd_kit_core: ^0.2.0-dev.0`, promoting the existing shared-runtime
    migration notes from `Unreleased` into a publishable changelog entry.
  - Moved the first public Jaspr release target to
    `packages/dnd_kit_jaspr 0.2.0-dev.0` with
    `dnd_kit_core: ^0.2.0-dev.0`, keeping the changelog public-facing.
  - Added `packages/dnd_kit_jaspr/LICENSE` (MIT) for pub validation and kept
    the formatter-only fix in
    `packages/dnd_kit_jaspr/test/accessibility_browser_test.dart`.
  - Updated the local `packages/dnd_kit/pubspec.yaml` dependency to
    `dnd_kit_flutter: ^0.2.0-dev.0` so the workspace can still solve and run
    validation while the published umbrella package remains `0.1.0` on pub.dev.
- Proof:
  - `dart pub get` passed after the coordinated version/constraint update.
  - `fvm dart run melos run validate` passed (format clean, analyze clean, core
    tests, Jaspr tests, Flutter adapter tests, and all three example suites).
  - `fvm dart pub publish --dry-run` passed from `packages/dnd_kit_core`,
    `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr`. Each dry-run now
    reports only the expected dirty-git-tree warning before commit/publish.
- Release:
  - The correct publish order is now explicit and validated locally:
    `dnd_kit_core 0.2.0-dev.0` -> `dnd_kit_flutter 0.2.0-dev.0` ->
    `dnd_kit_jaspr 0.2.0-dev.0`.
  - Actual pub.dev publish remains intentionally deferred pending a clean commit
    and explicit human go-ahead for the irreversible publish steps.
