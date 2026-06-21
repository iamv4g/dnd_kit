# dnd_kit website

The marketing home page for the **dnd_kit** drag-and-drop family, built with
[Jaspr](https://github.com/schultek/jaspr) in **static (SSG)** mode and styled
with **Tailwind**. The page is also a live proof of the library: the Kanban,
the hero capability chips, the reorderable nav and feature cards, and the
playground all run on `dnd_kit_jaspr`, and a telemetry strip reads the engine's
drag state as you go.

## Architecture

- **Static rendering + hydration islands.** Sections pre-render to HTML on the
  server (`lib/main.server.dart`); only interactive pieces are `@client`
  components hydrated in the browser (`lib/main.client.dart`). The drag widgets
  are SSR-safe, so they pre-render and hydrate without DOM access on the server.
- **Drag woven in, not bolted on.** `lib/sections/kanban_showcase.dart` is the
  centerpiece — a cross-column board on the generic `DndDraggable` /
  `DndDroppable` primitives with app-owned move logic (the Jaspr adapter ships a
  single-container sortable preset only). The nav pills and feature grid use the
  `SortableScope` preset; the hero chips and playground use generic drop zones.
- **Telemetry HUD** (`lib/drag/telemetry_hud.dart`) is the signature element: a
  shared `DragBus` collects every island's controller state into one live
  readout.
- **Theme** is a `dark` class on `<html>`, set before first paint by a no-flash
  script and toggled by `lib/theme/theme_toggle.dart` (persisted to
  `localStorage`).

## Tailwind

`jaspr_tailwind`'s build_runner integration pulls in `build_modules`, which
collides with `build_web_compilers` in this pub workspace. We therefore compile
Tailwind directly with the **standalone Tailwind CLI** via `tool/styles.sh`
(the binary auto-downloads on first run). Config lives in `tailwind.config.js`;
the warm "claude.ai" palette is driven by CSS variables in `web/styles.tw.css`
so a single class (`bg-paper`, `text-ink`) adapts to light/dark.

## Develop

```sh
# from this directory (website/)
tool/styles.sh --watch          # terminal 1: rebuild CSS on change
dart pub global run jaspr_cli:jaspr serve   # terminal 2: dev server on :8080
```

(If `tailwindcss` is already on your PATH you can use that instead of
`tool/styles.sh`.)

## Build (static site)

```sh
tool/styles.sh --minify         # compile web/styles.css
dart pub global run jaspr_cli:jaspr build   # outputs static files to build/jaspr
```

The contents of `build/jaspr` are plain static files — deploy them to any
static host (GitHub Pages, Netlify, Cloudflare Pages, …).

## Links

- GitHub: https://github.com/vanvixi/dnd_kit
- pub.dev: https://pub.dev/packages/dnd_kit_jaspr
- Docs: _coming soon_ (currently a `#docs` placeholder in the nav/footer)
