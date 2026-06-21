# Validation

## Proof Strategy

Before this story is done, the workspace must resolve and validate against the
prepared `0.3.1` package line, and each package must pass
`dart pub publish --dry-run` in dependency order before the actual pub.dev
publication is attempted.

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | Existing package unit coverage continues to pass through the shared family validation lane. |
| Integration | Existing adapter/example suites continue to pass under `fvm dart run melos run validate`, as exercised by the shared family verifier. |
| E2E | Not required beyond the existing browser/example proof already exercised by the validation lane. |
| Platform | `dart pub get` and `fvm dart run tool/verify_family_release.dart` pass, and the verifier completes publish dry-runs for `packages/dnd_kit`, `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr` in dependency order. |
| Performance | Not required; no new runtime hot path is introduced by the release packet itself. |
| Logs/Audit | Harness intake/story/trace records capture the prepared versions, dry-run proof, final publish order, and any blocker. |

## Fixtures

- Current workspace with package versions already set to `0.3.1`.
- Package-local changelogs for `dnd_kit`, `dnd_kit_flutter`, and
  `dnd_kit_jaspr`.
- `tool/verify_family_release.dart`.

## Commands

```text
dart pub get
fvm dart run tool/verify_family_release.dart
scripts/bin/harness-cli story verify US-073
```

## Acceptance Evidence

- Prepared versions remain:
  - `dnd_kit 0.3.1`
  - `dnd_kit_flutter 0.3.1` depending on `dnd_kit: ^0.3.1`
  - `dnd_kit_jaspr 0.3.1` depending on `dnd_kit: ^0.3.1`
- Changelog scope matches the landed patch work:
  - `dnd_kit`: shared `DndAnnouncements` contract.
  - `dnd_kit_flutter`: Flutter accessibility hardening.
  - `dnd_kit_jaspr`: SSR handle-sync assertion fix plus shared-announcements reuse.
- Verified 2026-06-20:
  - `scripts/bin/harness-cli story verify US-073` -> pass.
  - `fvm dart run tool/verify_family_release.dart` -> pass.
  - The verifier completed `dart pub get`, `fvm dart run melos run validate`,
    and `fvm dart pub publish --dry-run` for `packages/dnd_kit`,
    `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr` in dependency
    order.
  - All three package dry-runs reported `Package has 0 warnings.`
- Published 2026-06-20 in strict dependency order:
  - `dnd_kit 0.3.1`
  - `dnd_kit_flutter 0.3.1`
  - `dnd_kit_jaspr 0.3.1`
- Final publish order was:
  `dnd_kit -> dnd_kit_flutter -> dnd_kit_jaspr`.
