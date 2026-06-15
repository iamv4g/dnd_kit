# Architecture

This repository now targets `dnd_kit`, a Flutter drag-and-drop toolkit with a
pure Dart core and a primary Flutter package that includes sortable presets.

The detailed living product contract is split across:

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

The seed specification remains in `SPEC.md` as historical input material.

## Product Surfaces

- Pure Dart package APIs for geometry, state, collision, modifier, sensor,
  sortable math, the framework-neutral drag runtime (`DndRuntime`), and the
  measuring-cache contract (`DndMeasuringRegistry`).
- Flutter widget APIs for drag scopes, controllers, draggables, droppables,
  handles, overlays, measuring, sensors, auto-scroll, and accessibility.
- Sortable preset APIs for vertical lists, horizontal lists, and grids.
- Example Flutter apps used as adoption guides and integration proof.

## Package Layers

```text
dnd_kit_core
  <- dnd_kit
```

Sortable source lives inside `dnd_kit` as a preset layer so the canonical app
import, `package:dnd_kit/dnd_kit.dart`, can expose both drag/drop widgets and
stable sortable APIs without a package dependency cycle.

## Dependency Rule

Inner packages must not depend on outer packages.

| Package | May depend on | Must not depend on |
| --- | --- | --- |
| `dnd_kit_core` | `collection`, `meta`, Dart SDK | Flutter, `dart:ui`, widget/render/gesture APIs, state management packages |
| `dnd_kit` | Flutter SDK, `dnd_kit_core`, small annotations/utilities | external state management |

## Boundary Rules

Core geometry must use `DndPoint`, `DndSize`, `DndRect`, and `DndTransform`
rather than Flutter geometry types.

Flutter geometry conversion belongs at adapter boundaries. Unknown Flutter
layout data should be measured and normalized before entering collision or
modifier logic.

User data remains outside the library. Drag/drop and sortable APIs report
intent; applications own mutation.

## Validation Ladder

- Core stories use `dart test` and `dart analyze`.
- Flutter adapter stories use `flutter test` for widget and gesture behavior.
- Example and showcase stories add integration or platform build checks when
  they introduce user-visible flows.
- Release hardening adds `melos run test`, `melos run analyze`, and example
  build checks.

## Shared Runtime

`dnd_kit_core` owns the single drag engine. `DndRuntime` holds the drag state
machine, collision orchestration, modifier application, and measuring-cache
interactions in pure Dart. Adapters wrap it with their own change-notification:
`dnd_kit_flutter`'s `DndController extends ChangeNotifier` forwards
`notifyListeners`, and the future `dnd_kit_jaspr` adapter wraps the same runtime
for the browser. See `SPEC_JASPR.md` §4.3 and ADR 0015.

The shared layer also owns the sortable contract and strategy math
(`SortableMoveDetails`, `SortableStrategies` for vertical/horizontal/grid) and
the DOM-free auto-scroll edge/velocity math (`dndAutoScrollVelocity`,
`DndAutoScrollOptions`). Adapters keep only the framework-specific execution:
Flutter retains the `Ticker`, render-box measuring, and `ScrollPosition`
scrolling and delegates the math.

## Decisions

- `docs/decisions/0007-dnd-kit-package-architecture.md`
- `docs/decisions/0015-shared-runtime-in-core.md`
