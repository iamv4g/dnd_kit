# US-044 Update Repository Links After GitHub Rename

## Status

implemented

## Lane

normal

## Product Contract

The GitHub repository was renamed from `vanvixi/dnd_kit.flutter` to
`vanvixi/dnd_kit`. All live links that point at the old `dnd_kit.flutter` slug
must be updated to the new `dnd_kit` repository so that pub.dev metadata, package
docs, examples, and the hosted gallery deployment resolve correctly.

The canonical repository URL becomes:

```text
https://github.com/vanvixi/dnd_kit
```

The local Git `origin` remote must also be updated to the new URL.

Because the repository name drives GitHub Pages, the hosted example gallery URL
becomes `https://vanvixi.github.io/dnd_kit/` and the gallery web build must use
the `--base-href /dnd_kit/` path.

## Relevant Product Docs

- `packages/dnd_kit_core/pubspec.yaml`
- `packages/dnd_kit_flutter/pubspec.yaml`
- `packages/dnd_kit/pubspec.yaml`
- `packages/dnd_kit_flutter/README.md`
- `packages/dnd_kit/README.md`
- `.github/workflows/deploy-example-gallery.yml`
- `examples/example_gallery/README.md`

## Acceptance Criteria

- The local Git remote is updated:
  `git remote set-url origin https://github.com/vanvixi/dnd_kit.git`, and
  `git remote -v` shows the new URL.
- Every package `pubspec.yaml` (`dnd_kit_core`, `dnd_kit_flutter`, `dnd_kit`)
  has `homepage`, `repository`, and `issue_tracker` pointing at
  `https://github.com/vanvixi/dnd_kit` (with the correct `tree/main/packages/...`
  path per package).
- Package READMEs and `example/example.md` files link to
  `https://github.com/vanvixi/dnd_kit/...` instead of the old slug.
- The hosted gallery link in package READMEs is
  `https://vanvixi.github.io/dnd_kit/`.
- The Pages deploy workflow and `examples/example_gallery/README.md` use
  `--base-href /dnd_kit/`.
- No live file (under `packages/`, `.github/`, root `README.md`, or `examples/`)
  contains the old `dnd_kit.flutter` slug.
- Historical evidence under `docs/stories/*` and `docs/decisions/*` is left
  unchanged, because those records describe what was true at the time.

## Design Notes

- Commands:
  `git remote set-url origin https://github.com/vanvixi/dnd_kit.git`;
  search/replace `dnd_kit.flutter` -> `dnd_kit` and
  `vanvixi.github.io/dnd_kit.flutter` -> `vanvixi.github.io/dnd_kit` and
  `/dnd_kit.flutter/` -> `/dnd_kit/` in live files only.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: no code or public API surface changes; this is metadata and link text.
- Tables: story row `US-044`.
- Domain rules: do not touch `docs/stories/*` or `docs/decisions/*` historical
  references; they are evidence, not live links.
- UI surfaces: the hosted gallery moves to `https://vanvixi.github.io/dnd_kit/`
  once the repo rename and `--base-href /dnd_kit/` build are in effect.
- Decision point: this story assumes the GitHub Pages site name follows the repo
  rename (`/dnd_kit/`). Confirm the repo is actually renamed and Pages is enabled
  for `dnd_kit` before relying on the new gallery URL.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-044 --unit 0 --integration 0 --e2e 0 --platform 0`.

Mechanical verify command (passes only when no live file contains the old slug):

```bash
bash -c '! git grep -q "dnd_kit\.flutter" -- packages .github README.md examples'
```

| Layer | Expected proof |
| --- | --- |
| Unit | Not applicable; no code behavior changes. |
| Integration | Not applicable; no code behavior changes. |
| E2E | Not required. |
| Platform | Hosted gallery web build with `--base-href /dnd_kit/` succeeds; deployed gallery loads at `https://vanvixi.github.io/dnd_kit/`. |
| Release | `git remote -v` shows the new URL; `fvm dart pub publish --dry-run` for each package shows the new repository/homepage metadata; `fvm dart run melos run validate` still passes; the mechanical verify command above exits 0. |

## Harness Delta

No Harness tool changes expected.

## Evidence

- `git remote set-url origin https://github.com/vanvixi/dnd_kit.git`;
  `git remote -v` now shows `https://github.com/vanvixi/dnd_kit.git`.
- Replaced `dnd_kit.flutter` -> `dnd_kit` across 9 live files: the three
  package `pubspec.yaml` files, `dnd_kit`/`dnd_kit_flutter` READMEs and
  `example/example.md`, `examples/example_gallery/README.md`, and
  `.github/workflows/deploy-example-gallery.yml` (now `--base-href /dnd_kit/`).
- `docs/stories/*` and `docs/decisions/*` left unchanged on purpose; the only
  remaining `dnd_kit.flutter` references are historical evidence in
  `docs/decisions/0009-mit-package-license.md` and
  `docs/stories/phase-10-post-publish-adoption/US-038-hosted-example-gallery.md`.
- `scripts/bin/harness-cli story verify US-044` passed:
  `! git grep -q "dnd_kit\.flutter" -- packages .github README.md examples`
  exits 0 (no stale slug in live files).
- `fvm dart run melos run validate` passed: format clean, analyze SUCCESS for
  all packages, and all test suites passed.
- `fvm dart pub publish --dry-run` for the packages reports only the expected
  dirty-git-tree warning; pubspec metadata now points at the new repository.
