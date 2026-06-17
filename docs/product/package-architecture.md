# Package Architecture

## Monorepo Shape

```text
packages/
  dnd_kit/          # pure Dart engine, shared by every adapter
  dnd_kit_flutter/  # Flutter adapter
  dnd_kit_jaspr/    # Jaspr adapter
examples/
  basic_drag_drop/
docs/
```

The framework-agnostic `dnd_kit` package is the shared engine. `dnd_kit_flutter`
is the Flutter adapter built on top of it. `dnd_kit_jaspr` is the Jaspr adapter
built on the same shared runtime without pulling in Flutter. There is no umbrella
package: the brand name `dnd_kit` is the engine itself (the `flutter_bloc`/`bloc`
pattern), so Flutter and Jaspr adapters depend on `dnd_kit` directly.

> History: `dnd_kit` was previously a thin Flutter umbrella that re-exported
> `dnd_kit_flutter`, and the engine was published as `dnd_kit_core`. As of the
> `0.3.0-dev.0` line (US-060 / ADR 0017), the engine took the `dnd_kit` name and
> `dnd_kit_core` is discontinued.

## Package Boundaries

### `dnd_kit`

Pure Dart package with no Flutter dependency. This is the shared engine.

Owns:

- `DndId`
- `DndPoint`, `DndSize`, `DndRect`, `DndTransform`
- drag state and session models
- the framework-neutral drag runtime (`DndRuntime`)
- the measuring-cache contract (`DndMeasuringRegistry`)
- collision detector contracts and built-in algorithms
- modifier contracts and pure Dart modifiers
- sensor contracts and the shared pointer sensor
- registry contracts
- base sortable math and auto-scroll edge/velocity math

Must not import:

- `package:flutter/*`
- `dart:ui`
- `BuildContext`
- `RenderBox`
- `Offset`, `Rect`, or `Size` from Flutter
- animation or overlay APIs

The library entry point is `package:dnd_kit/dnd_kit.dart`.

### `dnd_kit_flutter`

Flutter adapter package depending on `dnd_kit` and Flutter. This is the
package that owns the Flutter widget, sensor, measuring, overlay, and sortable
implementation.

Owns:

- `DndScope`
- `DndController`
- `DndDraggable`
- `DndDroppable`
- `DndDragHandle`
- `DndDragOverlay`
- pointer, mouse, touch, long-press, and keyboard sensors
- Flutter measuring and geometry adapters
- overlay rendering
- auto-scroll
- semantics and accessibility hooks
- stable sortable preset APIs

Also owns sortable preset source:

- `SortableScope`
- `SortableItem`
- `SortableContainer`
- `SortableStrategy`
- `SortableStrategies`
- `SortableMoveDetails`
- sortable keyboard coordinates

Stable V1 strategies are vertical list, horizontal list, and grid.
Multi-container, nested sortable, and virtualized adapters remain experimental.

Flutter apps import `package:dnd_kit_flutter/dnd_kit_flutter.dart`.

### `dnd_kit_jaspr`

Jaspr adapter package depending on `dnd_kit`, `jaspr`, and
`package:universal_web` for browser execution. It owns the Jaspr component
layer over the shared drag runtime.

Owns:

- `DndScope`
- `DndController`
- `DndDraggable`
- `DndDroppable`
- `DndDragHandle`
- `DndDragOverlay`
- browser measuring and collision execution
- browser auto-scroll execution
- live-region accessibility hooks and accessible labels/descriptions

Must not:

- depend on Flutter or `dart:ui`
- reimplement drag state, collision math, modifier math, or sortable math that
  can stay in `dnd_kit`
- require DOM access at import time; all browser access must remain SSR-safe

## Dependency Policy

Core runtime dependencies stay minimal:

- `collection`
- `meta`

Core must not use:

- `vector_math`
- `provider`
- `riverpod`
- `bloc`
- `freezed`
- `equatable`

Flutter packages may depend on Flutter SDK packages, but should avoid locking
users into an app state management approach.

No adapter depends on another adapter; both depend only on `dnd_kit`. No package
has an upward dependency on an adapter.

## SDK Policy

The package family targets:

```yaml
environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"
```
