# US-075 Run affected-only validation in the Validate CI

## Status

implemented

## Lane

normal

## Product Contract

The Validate workflow validates only the packages affected by a change instead
of always running `validate:full`. It runs on pull requests and on pushes to
`main` (so a direct push to `main` is still validated), and the website package
(`dnd_kit_website`) is covered. Structural changes still escalate to full
validation.

## Relevant Product Docs

- `.github/workflows/validate.yml`
- `tool/affected_validate.dart` (US-054 affected tooling)
- `pubspec.yaml` (`melos` scripts: `validate:affected`, `analyze:affected`)

## Acceptance Criteria

- `validate.yml` runs `dart run melos run validate:affected` (not `validate`),
  with `fetch-depth: 0` so the tool can diff against a base commit.
- The diff base is event-aware: the PR base commit on `pull_request`, the prior
  tip (`github.event.before`) on `push` to `main`.
- Triggers remain `pull_request` and `push` to `main` — direct pushes to `main`
  are validated, not only PRs.
- A change under `website/` is validated: every changed `.dart` file is
  format-checked and `dnd_kit_website` is analyzed.
- A change to `tool/`, `scripts/`, `.github/workflows/`, root `pubspec.*`, or
  `analysis_options.yaml` still falls back to `validate:full`.

## Design Notes

- No change to `affected_validate.dart` was needed: it already format-checks
  every changed `.dart` file (so `website/lib/*.dart` drift is caught) and
  analyzes the package that owns each changed file — `dnd_kit_website` is a melos
  workspace package, so website analyze is selected. Docs-only files
  (`readme.md`, `changelog.md`, `doc/`, …) are ignored; workspace/tooling/
  workflow/pubspec changes force `validate:full`.
- Diff base: `MELOS_DIFF` is set to
  `github.event.pull_request.base.sha` on PRs and `github.event.before` on
  pushes; the tool reads `MELOS_DIFF` (default `HEAD`).
- Edge case: a push whose `before` is all-zero (a brand-new branch or a
  force-push) has no usable base; normal merges to `main` carry a valid prior
  tip, so this is acceptable for the `main` push path. (Follow-up if it ever
  bites: guard the env and fall back to `validate:full`.)
- Builds on US-054, which introduced and accepted affected-only validation with
  a full-validation safety fallback; this story only adopts it in CI.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-075 --unit 0 --integration 0 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | n/a |
| Integration | n/a |
| E2E | n/a |
| Platform | `validate.yml` runs green on a PR and on a push to `main`, selecting only affected packages |
| Release | First green affected run on `main` |

## Harness Delta

New phase folder `phase-27-ci-affected-validation`. No template or tooling
change; reuses the US-054 affected validator.

## Evidence

- `dart run tool/affected_validate.dart validate --files=website/lib/site.dart`
  → changed-file format check passes, `dart analyze` on `dnd_kit_website`
  SUCCESS, tests skipped (no `test/` dir).
- `affected_validate.dart plan` for `website/lib/site.dart` and
  `website/web/styles.tw.css` selects `dnd_kit_website`; `website/README.md` is
  reported docs-only / ignored.
