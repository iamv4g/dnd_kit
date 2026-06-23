# Architecture

This repository now targets `dnd_kit`, a drag-and-drop toolkit with a pure
Dart core plus Flutter and Jaspr adapters.

The detailed living product contract is split across:

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

Historical input material remains in:

- `SPEC.md` for the original repository/product seed specification
- `SPEC_JASPR.md` for the Jaspr adapter design input that informed the shared
  runtime extraction and adapter direction

Those specs are no longer the living contract; ongoing truth lives in the
product docs, story packets, and decision records under `docs/`.

## Product Surfaces

- Pure Dart package APIs for geometry, state, collision, modifier, sensor,
  sortable math, the experimental multi-container helper contract, the
  framework-neutral drag runtime (`DndRuntime`), and the measuring-cache
  contract (`DndMeasuringRegistry`).
- Flutter widget APIs for drag scopes, controllers, draggables, droppables,
  handles, overlays, measuring, sensors, auto-scroll, and accessibility.
- Jaspr component APIs for drag scopes, controllers, draggables, droppables,
  handles, overlays, sortable presets, browser measuring, auto-scroll, and
  accessibility.
- Sortable preset APIs for vertical lists, horizontal lists, and grids.
- Example Flutter and Jaspr apps used as adoption guides and integration proof.

## Package Layers

```text
dnd_kit
  <- dnd_kit_flutter
  <- dnd_kit_jaspr
```

`dnd_kit` is the shared engine. `dnd_kit_flutter` and `dnd_kit_jaspr` are peer
adapters over it; neither depends on the other. There is no umbrella package.
Sortable widgets now live in both adapters, while the sortable move/strategy
math and experimental multi-container helper contract they use are shared from
`dnd_kit`.

## Dependency Rule

Inner packages must not depend on outer packages, and adapters must not depend on
each other.

| Package | May depend on | Must not depend on |
| --- | --- | --- |
| `dnd_kit` | `collection`, `meta`, Dart SDK | Flutter, Jaspr, `dart:ui`, DOM/browser types, widget/render/gesture APIs, state management packages |
| `dnd_kit_flutter` | Flutter SDK, `dnd_kit`, small annotations/utilities | Jaspr, `dnd_kit_jaspr`, external state management |
| `dnd_kit_jaspr` | `dnd_kit`, `jaspr`, `universal_web` (for DOM), `meta` | Flutter, `dart:ui`, `dnd_kit_flutter`, external state management |

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

`dnd_kit` owns the single drag engine. `DndRuntime` holds the drag state
machine, collision orchestration, modifier application, and measuring-cache
interactions in pure Dart. Adapters wrap it with their own change-notification:
`dnd_kit_flutter`'s `DndController extends ChangeNotifier` forwards
`notifyListeners`, and `dnd_kit_jaspr` wraps the same runtime for the browser.
See `SPEC_JASPR.md` §4.3 and ADR 0015.

The shared layer also owns the sortable contract and strategy math
(`SortableMoveDetails`, `SortableStrategies` for vertical/horizontal/grid),
the experimental multi-container helper contract
(`SortableContainer`, `SortableMultiContainer`), and the DOM-free auto-scroll
edge/velocity math (`dndAutoScrollVelocity`, `DndAutoScrollOptions`,
`DndScrollAxis`). Adapters keep only the framework-specific execution: Flutter
retains the `Ticker`, render-box measuring, and `ScrollPosition` scrolling and
delegates the math.

## Decisions

- `docs/decisions/0007-dnd-kit-package-architecture.md`
- `docs/decisions/0015-shared-runtime-in-core.md`
- `docs/decisions/0017-core-as-brand-package.md`
- `docs/decisions/0018-flutter-3-44-workspace-unification.md`
- `docs/decisions/0020-axis-aware-auto-scroll.md`
- `docs/decisions/0021-shared-experimental-multi-container.md`

For historical Jaspr-specific design context, also see `SPEC_JASPR.md`.
