# US-074 Publish the homepage to GitHub Pages via CI

## Status

planned

## Lane

normal

## Product Contract

When a pull request is merged into `main`, the Jaspr marketing site in
`website/` is built in release mode and deployed to GitHub Pages, so the project Pages URL
(`https://vanvixi.github.io/dnd_kit/`) serves the homepage. The site loads its
CSS and hydration bundle correctly under the `/dnd_kit/` subpath. GitHub Pages
stops serving the Flutter example gallery from the Pages root (only one Pages
deployment can exist), so the existing gallery deploy is retired or relocated.

## Relevant Product Docs

- `website/` (the Jaspr homepage app)
- `.github/workflows/deploy-example-gallery.yml` (the deploy being replaced)
- `website/tool/styles.sh` (Tailwind build, self-bootstrapping per platform)

## Acceptance Criteria

- A GitHub Actions workflow builds `website/` with the repo-pinned SDK
  (`.fvmrc`, Flutter 3.44.2), compiles Tailwind, runs `jaspr build`, and deploys
  `website/build/jaspr` to GitHub Pages.
- The deployed homepage loads `styles.css` and `main.client.dart.js` with no 404
  under the `/dnd_kit/` subpath (base href resolved for the project subpath).
- Drag islands and the theme toggle hydrate on the deployed site (release build
  has no DWDS dev client — see this session's Android finding).
- Exactly one workflow owns the Pages deployment; the example-gallery deploy no
  longer competes for the `github-pages` environment / `pages` concurrency group.
- A `.nojekyll` marker ships in the artifact so Jekyll does not reprocess the
  Jaspr asset filenames.
- The workflow runs only when a pull request is merged into `main` (a closed PR
  with `merged == true`) and via `workflow_dispatch` — not on every PR event.

## Design Notes

- Commands: `website/tool/styles.sh --minify` (auto-downloads the Linux
  tailwindcss binary on CI); `jaspr build` run from `website/` under the
  fvm-pinned Dart (activate `jaspr_cli` with the same SDK to avoid the kernel
  131/130 mismatch seen locally).
- Base href: `jaspr build` has no `--base-href`, and the Jaspr `Document`
  emits `<base href="/"/>`. For the `/dnd_kit/` project subpath the build output
  must carry `<base href="/dnd_kit/"/>`. Chosen approach: post-build rewrite of
  `build/jaspr/index.html` in the workflow (keeps local dev at `/`). Alternative
  recorded: drive the base from `String.fromEnvironment` and pass it at build
  time; or use a custom domain (CNAME) so the site lives at root and base `/`
  works unchanged.
- Asset paths in `index.html` are already relative (`styles.css`,
  `main.client.dart.js`), so they resolve correctly once the base href points at
  the subpath. The brand/home link `href="/"` is absolute and will point at the
  domain root, not `/dnd_kit/` — follow-up nit, not a blocker.
- SDK consistency: build with the Flutter 3.44.2 toolchain that
  `subosito/flutter-action@v2` installs from `.fvmrc`; run the Jaspr CLI under
  that Dart so cached build snapshots match.
- Gallery replacement: only one Pages site exists per repo. Replace
  `deploy-example-gallery.yml`, or relocate the gallery under a subpath
  (e.g. `/dnd_kit/gallery/`) inside the same Pages artifact. Open decision below.
- Trigger: `pull_request` `closed` on `main` gated by
  `github.event.pull_request.merged == true` (deploy the merged result, not
  preview every PR), plus `workflow_dispatch`. Checkout uses
  `github.event.pull_request.base.ref` (post-merge `main`) so the artifact is the
  landed content. If the `github-pages` environment is later restricted to a
  branch allow-list, a PR-triggered deploy may be blocked and the trigger would
  need to move to `push: [main]`.
- CI ergonomics borrowed from the reference Firebase workflow: cache
  `~/.pub-cache` keyed on `pubspec.lock`, `flutter-action` SDK cache, a
  verify-build-output gate, and `jaspr build --verbose`. Tailwind keeps the repo
  helper `tool/styles.sh` (self-fetches the Linux binary, uses the project
  config and `web/styles.tw.css` paths) instead of a manual binary download.
- UI surfaces: none changed; this is deploy infrastructure only.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-074 --unit 0 --integration 0 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | n/a (no app logic changes) |
| Integration | n/a |
| E2E | n/a |
| Platform | `jaspr build` succeeds locally; the Pages workflow runs green; the deployed `/dnd_kit/` URL loads the homepage with working CSS/JS and hydrated drag + theme toggle |
| Release | First successful Pages deployment from `main` |

## Harness Delta

New phase folder `phase-26-website-homepage-deploy`. No template or rule
changes. The website itself was built ad hoc (not previously tracked by a US);
this story is the first harness record for website delivery infrastructure.

## Open Decisions

- Gallery fate: drop the example-gallery deploy entirely, or keep it served from
  a subpath alongside the homepage. Needs human confirmation before the gallery
  workflow is removed.

## Evidence

- Local release build + LAN serve confirmed this session that the production
  build hydrates (drag + theme toggle) where the dev `jaspr serve` did not
  (DWDS client hardcodes `localhost`).
