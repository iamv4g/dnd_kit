# US-038 Hosted Example Gallery And README Link

## Status

implemented

## Lane

normal

## Product Contract

The repository must publish a hosted Flutter web example gallery so users can
open one public demo link and try multiple `dnd_kit` example flows without
cloning the repo.

## Relevant Product Docs

- `docs/product/release-roadmap.md`
- `docs/product/package-architecture.md`
- `packages/dnd_kit/README.md`
- `examples/README.md`

## Acceptance Criteria

- `examples/example_gallery` exists as a runnable Flutter web example app.
- The gallery can show the basic drag/drop, Kanban, and experimental
  multi-container sortable demos from one UI.
- Existing standalone example apps remain runnable independently.
- GitHub Actions builds the gallery web app and deploys it to GitHub Pages.
- `packages/dnd_kit/README.md` links to the hosted gallery near the top.
- Local validation includes a release web build of `examples/example_gallery`.

## Design Notes

- Commands:
  - `fvm flutter test examples/example_gallery`
  - `cd examples/example_gallery && fvm flutter build web --release --base-href /dnd_kit.flutter/`
  - `fvm dart analyze`
- Queries:
  - `scripts/bin/harness-cli query matrix`
- API:
  - No package public API changes.
- Tables:
  - No schema changes.
- Domain rules:
  - Examples remain application-owned state demos.
  - The gallery is a host app and does not replace standalone examples.
- UI surfaces:
  - Hosted GitHub Pages gallery.
  - Package README demo link.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id <id> --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm flutter test examples/example_gallery` |
| Integration | Gallery imports and renders standalone example widgets |
| E2E | Not required |
| Platform | `cd examples/example_gallery && fvm flutter build web --release --base-href /dnd_kit.flutter/` |
| Release | `fvm dart analyze` |

## Harness Delta

None expected.

## Evidence

- `fvm flutter pub get` passed.
- `fvm flutter test examples/example_gallery` passed with 2 widget tests.
- `fvm flutter test examples/multi_container_sortable` passed with 3 widget
  tests after hosted-demo contrast polish.
- `fvm dart analyze` passed with no issues.
- `cd examples/example_gallery && fvm flutter build web --release --base-href /dnd_kit.flutter/`
  built `build/web`; Flutter reported non-blocking dependency update notices,
  a Wasm dry-run suggestion, and the existing icon tree-shaking/font warning.
- `fvm dart run melos run validate` passed after formatting the workspace.
- `git diff --check` passed.
- Browser verification served the release artifact under
  `/dnd_kit.flutter/`, rendered the Basic demo, and navigated to Kanban and
  Multi-container demos.
- Follow-up gallery bugfix: `DndDragOverlay` now converts global draggable
  rects into the local coordinates of the nearest parent `Stack`, preventing
  Basic demo overlays from shifting by the gallery sidebar offset. Regression
  proof passed with `fvm flutter test packages/dnd_kit/test/src/widgets/drag_overlay_test.dart`,
  `fvm flutter test examples/example_gallery`, `fvm dart analyze`,
  `cd examples/example_gallery && fvm flutter build web --release --base-href /dnd_kit.flutter/`,
  `fvm dart run melos run validate`, and `git diff --check`.
