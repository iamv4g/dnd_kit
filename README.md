# dnd_kit

`dnd_kit` is a Flutter drag-and-drop toolkit inspired by React dnd-kit and
designed around Flutter's widget, render, gesture, and state models.

The package is intended to provide a generic draggable and droppable engine for:

- basic drag and drop;
- sortable lists and grids;
- Kanban boards;
- dashboard builders;
- canvas editors;
- form and page builders;
- admin UIs for web and desktop;
- mobile UIs with long-press dragging.

## Design Direction

The architecture is:

```text
generic DnD engine first
Flutter toolkit package second
sortable as built-in preset
Kanban as showcase
multi-container as experimental
native OS drag/drop as future package
```

The release package layout is:

```text
packages/
  dnd_kit_core/
  dnd_kit_flutter/
  dnd_kit_jaspr/
  dnd_kit/
examples/
docs/
```

## Packages

| Package           | Role                                                                                                                                            |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `dnd_kit_core`    | Pure Dart geometry, state, collision, modifier, sensor, and sortable math contracts. Framework-agnostic and shared by every adapter.            |
| `dnd_kit_flutter` | Flutter adapter with scope, controller, draggable, droppable, overlay, sensors, measuring, auto-scroll, semantics, and stable sortable presets. |
| `dnd_kit`         | Thin umbrella that re-exports `dnd_kit_flutter` under the shorter name; the canonical `package:dnd_kit/dnd_kit.dart` import keeps working.      |

This split keeps the framework-agnostic engine reusable so additional adapters
such as `dnd_kit_jaspr` can build on `dnd_kit_core` without depending on the
Flutter adapter.

### Which package should I use?

- **Flutter app:** depend on `dnd_kit` (stable entry point) or `dnd_kit_flutter`
  (for dev releases / the explicit adapter).
- **Jaspr (Dart web) app:** depend on `dnd_kit_jaspr`. `dnd_kit` requires the
  Flutter SDK and is not usable in a pure Jaspr project. The Jaspr adapter is
  currently in dev releases while sortable presets are still in progress.
- **Shared engine only:** depend on `dnd_kit_core`.

`dnd_kit` publishes stable releases only; `dnd_kit_core` and the adapters carry
the faster dev releases. The neutral project home is the repository README and
the gallery at https://vanvixi.github.io/dnd_kit/.

## Current Status

The repository has completed Phase 0 foundation work, the Phase 1 pure Dart
core engine, the Phase 2 basic Flutter adapter, Phase 3 sensor and activation
work, Phase 4 measuring, collision runtime, modifier, and cached measuring
work, Phase 5 overlay, visual state, and auto-scroll work, the Phase 6 stable
sortable preset foundation through `US-028`, the Phase 7 Kanban showcase and
experimental multi-container sortable exploration through `US-030`, the Phase
8 production hardening work through `US-034`, the package rename/collapse work
through `US-035`, the shared-runtime multi-framework extraction through
`US-047`, and the first Jaspr adapter foundation/hardening plus first public
dev-release standardization through `US-059`.

The living source of truth is split from historical [SPEC.md](SPEC.md) input
material into product docs, story packets, validation expectations, and decision
records under `docs/`. Use `scripts/bin/harness-cli query matrix` for durable
story proof status.

## Harness

This repo uses Harness for agent-ready implementation work. Before changing
code, read [AGENTS.md](AGENTS.md) and use `scripts/bin/harness-cli` for intake,
story, proof, decision, and trace records.

For verification, keep two lanes:

- `dart run melos run validate`: full-workspace release gate.
- `MELOS_DIFF=HEAD dart run melos run validate:affected`: changed-code lane for
  day-to-day story work.

Use another git ref such as `MELOS_DIFF=origin/main` when you want the
affected-only lane to compare your branch against a shared base.
