# dnd_kit

`dnd_kit` is the pure Dart core engine for the dnd_kit drag-and-drop family.

It contains the framework-neutral drag runtime, geometry, collision detection,
modifiers, registry contracts, sensor contracts, sortable math, and auto-scroll
math shared by every adapter. It has no Flutter dependency.

> **Building an app?** You usually want an adapter, not this package directly:
> Flutter apps depend on
> [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter); Jaspr (Dart web)
> apps depend on [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr). Depend
> on `dnd_kit` directly only when you need the framework-agnostic engine (custom
> adapters, testable drag/drop math, or contract tests).

> **Migrating from `dnd_kit` `0.1.x`?** Those releases were the Flutter umbrella
> that re-exported `dnd_kit_flutter`. As of `0.3.0-dev.0`, `dnd_kit` is the
> engine. Replace `package:dnd_kit/dnd_kit.dart` with
> `package:dnd_kit_flutter/dnd_kit_flutter.dart` and depend on `dnd_kit_flutter`.

## Import

```dart
import 'package:dnd_kit/dnd_kit.dart';
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
- `DndAnnouncements` as the shared pure-Dart accessibility announcement
  contract reused by framework adapters.
- `DndRegistry` and diagnostics hooks for draggable and droppable metadata.
- `DndMeasuringRegistry`, sortable move/strategy math, and auto-scroll
  edge/velocity helpers shared by adapters.

## Package Boundary

`dnd_kit` intentionally has no Flutter dependency. It does not import
`package:flutter/*`, `dart:ui`, `BuildContext`, `RenderBox`, `Offset`, `Rect`,
or `Size`.

Flutter widgets, measuring, overlays, auto-scroll, and stable sortable presets
live in the `dnd_kit_flutter` adapter. The Jaspr component layer lives in
`dnd_kit_jaspr`.

## dnd_kit family

| Package                                                       | Use it for                                                                |
| ------------------------------------------------------------- | ------------------------------------------------------------------------- |
| [`dnd_kit`](https://pub.dev/packages/dnd_kit)                 | The shared, framework-agnostic engine. Build adapters or use the math.    |
| [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter) | Flutter apps — widgets, sensors, overlays, and sortable presets.          |
| [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr)     | Jaspr (Dart web) apps — the current dev adapter release.                  |
