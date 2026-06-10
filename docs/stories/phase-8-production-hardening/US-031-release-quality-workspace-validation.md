# US-031 Release-Quality Workspace Validation

## Status

implemented

## Lane

normal

## Product Contract

The workspace has a single release-quality validation entrypoint that proves
formatting, static analysis, package tests, and the Kanban example test suite
before production hardening work advances.

## Relevant Product Docs

- `docs/product/release-roadmap.md`
- `docs/product/package-architecture.md`

## Acceptance Criteria

- A workspace validation command exists for local release-quality checks.
- The validation command covers formatting, workspace analysis, package tests,
  and the Kanban example widget tests.
- CI runs the same validation command on pull requests and pushes to `main`.
- Harness story proof records identify the story as Phase 8 production
  hardening.

## Design Notes

- Commands:
  - `fvm dart run melos run validate`
- Queries:
  - `scripts/bin/harness-cli query matrix`
- API:
  - None.
- Tables:
  - Harness `story` proof row for `US-031`.
- Domain rules:
  - Release validation must stay workspace-level and avoid changing product API
    behavior.
- UI surfaces:
  - None.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-031 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | Package tests run through the workspace validation command. |
| Integration | Kanban example widget tests run through the workspace validation command. |
| E2E | Not required for this release-quality validation slice. |
| Platform | Deferred to a dedicated cross-platform build story. |
| Release | `fvm dart run melos run validate` passes locally and CI uses the same command. |

## Harness Delta

None expected.

## Evidence

- `fvm dart run melos run validate` passed.
- Validation covered `dart format --set-exit-if-changed .`, workspace
  analysis for five packages, `dart test packages/dnd_kit_core`,
  `flutter test packages/dnd_kit_flutter`,
  `flutter test packages/dnd_kit_sortable`, and
  `flutter test examples/kanban_board`.
- `scripts/bin/harness-cli story verify US-031` passed.
