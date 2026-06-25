# Examples Standard

This is the contract for the example apps: exactly two gallery projects, a
single canonical demo catalog, shared naming and layout conventions, and a
parity target across the Flutter and Jaspr adapters. It exists so the examples,
the documentation, and the upcoming showcase page all speak the same vocabulary.

Status: standard defined (US-083). Renaming/consolidating the projects and
bringing both adapters to parity is tracked as follow-up work; this document
does not change demo code.

## Why standardize

The two galleries had almost no overlap beyond a basic demo, and different
structures:

- Flutter (`examples/example_gallery`) aggregated three standalone packages —
  `basic_drag_drop`, `kanban_board`, `multi_container_sortable` — as demos.
- Jaspr (`examples/jaspr_example_gallery`) shipped five inline demos under
  `lib/demos/`: Basic, Sortable, Auto-scroll, Accessibility, Modifiers.

A showcase page that presents Flutter and Jaspr side by side needs matched
pairs, so the demos must converge on one catalog and one layout.

## Two gallery projects

After standardization, `examples/` contains exactly two projects:

- `examples/flutter_example_gallery` — the Flutter gallery (the current
  `examples/example_gallery`, renamed).
- `examples/jaspr_example_gallery` — the Jaspr gallery.

The standalone Flutter packages (`basic_drag_drop`, `kanban_board`,
`multi_container_sortable`) are folded into `flutter_example_gallery/lib/demos/`
and removed as separate projects. The website Kanban lives in `website/` and is
not an examples project.

## Demo layout

Each adapter keeps its demos under `lib/demos/`:

- a single-file demo is one file: `lib/demos/<slug>_demo.dart`;
- a demo that needs several files is a subfolder: `lib/demos/<slug>/`, with the
  entry component in `lib/demos/<slug>/<slug>_demo.dart` and its helpers
  alongside.

So a small demo like `collision` is `lib/demos/collision_demo.dart`, while a
multi-file demo like `multi-container` is `lib/demos/multi_container/`.

## Canonical demo catalog

The catalog mirrors the documentation concept taxonomy (`/docs/<concept>`), so
each demo pairs with a docs page and can later back its live embed.

| Slug              | Label           | Pairs with docs        | Demonstrates                                              |
| ----------------- | --------------- | ---------------------- | -------------------------------------------------------- |
| `basic`           | Basic           | draggable, droppable, overlay | pick up, drop on a target, drag handle, floating overlay |
| `collision`       | Collision       | collision              | switching detectors over several overlapping targets     |
| `sensors`         | Sensors         | sensors                | activation distance and press-delay constraints          |
| `modifiers`       | Modifiers       | modifiers              | axis lock, snap-to-grid, boundary clamp                  |
| `auto-scroll`     | Auto-scroll     | auto-scroll            | edge-driven scrolling in a bounded list                  |
| `sortable`        | Sortable        | sortable               | reorder a list; vertical / horizontal / grid strategies  |
| `multi-container` | Multi-container | multi-container        | move cards within and across columns (Kanban shape)      |
| `accessibility`   | Accessibility   | accessibility          | keyboard drag plus live-region announcements             |

`basic` intentionally bundles draggable, droppable, drag handle, and drag
overlay so a newcomer sees a whole interaction in one demo; the dedicated docs
pages still cover each concept on its own. The richer Kanban content from the
old `kanban_board` package is migrated as the `multi-container` demo (a
`lib/demos/multi_container/` subfolder).

## Naming conventions

- A demo's `slug` is kebab-case and equals its docs concept slug where the
  mapping is 1:1 (`collision`, `modifiers`, `auto-scroll`, …).
- The demo widget/component is named `<Concept>Demo`
  (`CollisionDemo`, `SortableDemo`, …) on both adapters, in
  `lib/demos/<slug>_demo.dart` or `lib/demos/<slug>/<slug>_demo.dart`.
- Each gallery registers a demo as `(slug, label, hint, builder)` and orders
  demos by the catalog order above.
- `label` and the one-line `hint` are identical across adapters for the same
  slug.

## Parity matrix

Target: every catalog demo present in both galleries, under `lib/demos/`.

| Demo              | Flutter today                         | Jaspr today           | Action          |
| ----------------- | ------------------------------------- | --------------------- | --------------- |
| `basic`           | ✓ (`basic_drag_drop`, to migrate)     | ✓ `BasicDemo`         | migrate + align |
| `collision`       | ✗                                     | ✗                     | add to both     |
| `sensors`         | ✗                                     | ✗                     | add to both     |
| `modifiers`       | ✗                                     | ✓ `ModifiersDemo`     | add to Flutter  |
| `auto-scroll`     | ✗                                     | ✓ `AutoScrollDemo`    | add to Flutter  |
| `sortable`        | ✗                                     | ✓ `SortableDemo`      | add to Flutter  |
| `multi-container` | ✓ (`multi_container_sortable` / `kanban_board`, to migrate) | ✗ | migrate to Flutter demo; add to Jaspr |
| `accessibility`   | ✗                                     | ✓ `AccessibilityDemo` | add to Flutter  |

Resulting work (for follow-up stories, not this one):

- Rename `example_gallery` → `flutter_example_gallery` and migrate the three
  standalone packages into `lib/demos/` (`basic`, `multi-container`).
- Flutter gains: `collision`, `sensors`, `modifiers`, `auto-scroll`, `sortable`,
  `accessibility`.
- Jaspr gains: `collision`, `sensors`, `multi-container`.

A sensible fill order is shared-engine-visible concepts first (collision,
sensors, modifiers, auto-scroll), then the presets (sortable, multi-container),
then accessibility.

## How this feeds later work

- **Docs live embeds** (deferred from the docs phase): once a catalog demo
  exists on Jaspr, its concept page can embed the live `@client` demo.
- **Showcase page** (next initiative story): presents the catalog as matched
  Flutter/Jaspr pairs. Jaspr demos render live as islands; the Flutter side is
  shown via an embedded Flutter-web build or recordings — that delivery choice
  is decided in the showcase-page story, not here.

## Out of scope for US-083

This story defines the standard only. It writes no demo code, renames no
projects, and does not migrate the standalone packages. Implementation lands in
follow-up parity stories.
