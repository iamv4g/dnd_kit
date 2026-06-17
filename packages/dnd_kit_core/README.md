# dnd_kit_core

`dnd_kit_core` contains the pure Dart foundation for `dnd_kit`.

Use this package when you need drag-and-drop primitives, runtime, geometry,
collision detection, modifiers, registry contracts, or sensor contracts
without depending on Flutter.

## Import

```dart
import 'package:dnd_kit_core/dnd_kit_core.dart';
```

## What It Provides

- `DndId` for stable application-owned identifiers.
- `DndPoint`, `DndSize`, `DndRect`, and `DndTransform` for toolkit geometry.
- `DndState`, `DndDragSession`, and drag events for lifecycle modeling.
- `DndRuntime` as the shared framework-neutral drag engine.
- `DndCollisionDetector` plus built-in detectors such as
  `DndCollisionDetectors.closestCenter`,
  `DndCollisionDetectors.closestCorners`,
  `DndCollisionDetectors.rectIntersection`, and
  `DndCollisionDetectors.pointerWithin`.
- `DndModifier` plus built-in modifiers such as
  `DndModifiers.restrictToVerticalAxis`,
  `DndModifiers.restrictToHorizontalAxis`,
  `DndModifiers.restrictToBoundary`, and `DndModifiers.snapToGrid`.
- `DndRegistry` and diagnostics hooks for draggable and droppable metadata.
- `DndMeasuringRegistry`, sortable move/strategy math, and auto-scroll
  edge/velocity helpers shared by adapters.

## Package Boundary

`dnd_kit_core` intentionally has no Flutter dependency. It does not import
`package:flutter/*`, `dart:ui`, `BuildContext`, `RenderBox`, `Offset`, `Rect`,
or `Size`.

Flutter widgets, measuring, overlays, auto-scroll, and stable sortable presets
live in the `dnd_kit_flutter` adapter (re-exported by `dnd_kit`).

## dnd_kit family

| Package                                                       | Use it for                                                                                 |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [`dnd_kit`](https://pub.dev/packages/dnd_kit)                 | Flutter apps — the stable, recommended Flutter entry point (re-exports `dnd_kit_flutter`). |
| [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter) | Flutter apps that want dev releases or the explicit adapter package.                       |
| [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr)     | Jaspr (Dart web) apps — the current dev adapter release.                                   |
| [`dnd_kit_core`](https://pub.dev/packages/dnd_kit_core)       | The shared, framework-agnostic engine.                                                     |
