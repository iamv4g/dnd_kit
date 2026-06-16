# US-054 Affected-Only Workspace Validation

## Status

implemented

## Lane

normal

## Product Contract

The workspace provides an affected-only validation entrypoint for day-to-day
story work so package and example verification stays scoped to changed code and
its dependents, while the existing full-workspace release validation remains
available unchanged.

## Relevant Product Docs

- `README.md`
- `docs/product/release-roadmap.md`
- `docs/product/package-architecture.md`
- `docs/stories/phase-8-production-hardening/US-031-release-quality-workspace-validation.md`

## Acceptance Criteria

- A local validation command exists that only analyzes and tests code-affecting
  package/example changes plus their transitive dependents.
- Docs-only package edits do not fan out to unrelated package and example test
  runs.
- Root workspace or validation-tooling changes fall back to the existing
  full-workspace validation path.
- The full-workspace validation path remains a non-mutating, fail-fast release
  gate.
- The existing `melos run validate` release gate remains available for CI and
  full pre-release verification.

## Design Notes

- Commands:
  - `fvm dart run melos run validate:affected`
  - `fvm dart run melos run analyze:affected`
  - `fvm dart run melos run test:affected`
  - `fvm dart run tool/affected_validate.dart plan --files=packages/dnd_kit_jaspr/lib/src/widgets/droppable.dart`
- Queries:
  - `scripts/bin/harness-cli query matrix`
- API:
  - None.
- Tables:
  - Harness `story` row for `US-054`.
- Domain rules:
  - Release validation keeps the full-workspace gate from `US-031`.
  - Affected validation may skip docs-only package changes but must include
    transitive dependents for code-affecting package changes.
- UI surfaces:
  - None.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-054 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | Selection planning reports only the changed package for a leaf Jaspr file and expands to dependents for a shared-core file. |
| Integration | `fvm dart run melos run validate:affected` succeeds and falls back to full validation when workspace-level tooling files change. |
| E2E | Not required. |
| Platform | Not required; this is workspace tooling only. |
| Release | `fvm dart run melos run validate` remains available and still succeeds as the full-workspace release gate. |

## Harness Delta

Added a reusable affected-only validation flow before US-051 so future story
work does not default to full-workspace verification.

## Evidence

- `fvm dart run tool/affected_validate.dart plan --files=packages/dnd_kit_jaspr/lib/src/widgets/droppable.dart`
  selected only `dnd_kit_jaspr`.
- `fvm dart run tool/affected_validate.dart plan --files=packages/dnd_kit_core/lib/src/runtime.dart`
  selected `dnd_kit_core` and its transitive dependents across Flutter, Jaspr,
  and examples.
- `fvm dart run melos run validate:affected` passed and fell back to the full
  workspace path because this story changes root Melos/tooling files.
- The full release-validation path passed through `validate:full`, and
  `validate` now remains a thin alias to that gate with non-mutating format
  checks and fail-fast shell behavior.
- `scripts/bin/harness-cli story verify US-054` passed.
