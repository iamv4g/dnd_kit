# Phase 32 - Website Docs Page And Post-0.4.0 Doc Alignment

The coordinated family stable `0.4.0` published on 2026-06-24 (Phase 31), but
public-facing docs still described the pre-release state: the website had only a
`#docs` placeholder, the root README status stopped at `US-076`, and the Jaspr
and Flutter package READMEs still carried "dev release" wording.

This phase closes that adoption gap across two normal-lane stories:

- `US-080` gave the website a real Getting Started docs page on its own `/docs`
  route (the marketing site was previously a single page with an in-page
  `#docs` anchor placeholder) and aligned the root README plus the Jaspr and
  Flutter package READMEs with the shipped stable `0.4.0` family;
- `US-081` then expanded `/docs` from that single page into a dndkit.com-style
  multi-page docs section: a shared `DocsShell` (grouped sidebar, right-rail
  "On this page" TOC, previous/next pager), a Flutter|Jaspr `CodeTabs` block,
  and nine core pages (Overview, Installation, Quickstart, Draggable,
  Droppable, Drag overlay, Sortable lists, Multi-container, Accessibility).

## Principle

Doc-alignment and website work in this phase must:

- introduce real on-site routing rather than another in-page anchor: the docs
  page is a separate statically generated route (`docs/index.html`), reached
  from the nav and footer;
- keep the static build deployable under the `/dnd_kit/` project Pages subpath —
  every generated page needs its `<base href>` rewritten, and cross-page links
  resolve relative to that base;
- describe only the already-shipped `0.4.0` surface; no new product behavior.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-080** | Add the website `/docs` Getting Started page (jaspr_router) and align root/package READMEs + website docs link with stable `0.4.0` | No ADR (docs/adoption work under the existing website and package-topology decisions) |
| **US-081** | Expand `/docs` into a multi-page docs section: shared `DocsShell` (sidebar + TOC + pager), Flutter\|Jaspr `CodeTabs`, nine core pages | No ADR (unified single docs tree with per-snippet adapter tabs, under the existing website decisions) |

## Validation Ladder

- Static-site proof: `tool/styles.sh --minify` plus
  `dart pub global run jaspr_cli:jaspr build` generate both the `/` and `/docs`
  routes, and `website/build/jaspr/docs/index.html` is present with the
  per-route `<title>` and relative asset URLs.
- Analyzer/format proof: `fvm dart analyze` and `fvm dart format` stay clean for
  the `website` package.
- Deploy proof: the deploy workflow rewrites `<base href>` on every generated
  HTML file and verifies both `index.html` and `docs/index.html`.
