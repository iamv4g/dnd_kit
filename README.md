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
Flutter adapter second
sortable as preset
Kanban as showcase
multi-container as experimental
native OS drag/drop as future package
```

The initial package layout is:

```text
packages/
  dnd_kit_core/
  dnd_kit_flutter/
  dnd_kit_sortable/
  dnd_kit/
examples/
docs/
```

## Packages

| Package | Role |
| --- | --- |
| `dnd_kit_core` | Pure Dart geometry, state, collision, modifier, sensor, and sortable math contracts. |
| `dnd_kit_flutter` | Flutter adapter with scope, controller, draggable, droppable, overlay, sensors, measuring, auto-scroll, and semantics. |
| `dnd_kit_sortable` | Sortable preset package for vertical lists, horizontal lists, and grids. |
| `dnd_kit` | Umbrella package exporting the stable public APIs from the sub-packages. |

## Current Status

The repository has completed Phase 0 foundation work, the Phase 1 pure Dart
core engine, the Phase 2 basic Flutter adapter, Phase 3 sensor and activation
work, Phase 4 measuring, collision runtime, modifier, and cached measuring
work, Phase 5 overlay, visual state, and auto-scroll work, the Phase 6 stable
sortable preset foundation through `US-028`, the Phase 7 Kanban showcase and
experimental multi-container sortable exploration through `US-030`, and Phase
8 production hardening work through `US-034` performance baseline smoke
benchmarks for drag and sortable flows.

The living source of truth is split from historical [SPEC.md](SPEC.md) input
material into product docs, story packets, validation expectations, and decision
records under `docs/`. Use `scripts/bin/harness-cli query matrix` for durable
story proof status.

## Harness

This repo uses Harness for agent-ready implementation work. Before changing
code, read [AGENTS.md](AGENTS.md) and use `scripts/bin/harness-cli` for intake,
story, proof, decision, and trace records.
