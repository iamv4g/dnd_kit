# dnd_kit

`dnd_kit` is a Flutter drag-and-drop toolkit for building sortable lists,
grids, Kanban boards, dashboards, canvas editors, and other drag-heavy
interfaces.

This package is a thin umbrella: it re-exports the Flutter adapter from
[`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter), which is built on
the framework-agnostic [`dnd_kit_core`](https://pub.dev/packages/dnd_kit_core)
engine. Importing `dnd_kit` and `dnd_kit_flutter` gives you the exact same API;
`dnd_kit` simply offers the shorter name.

Try the hosted example gallery:
https://vanvixi.github.io/dnd_kit/

## Import

```dart
import 'package:dnd_kit/dnd_kit.dart';
```

This re-exports the full Flutter widget layer (`DndScope`, `DndController`,
`DndDraggable`, `DndDroppable`, `DndDragOverlay`, auto-scroll helpers, and the
stable `SortableScope` / `SortableItem` presets) plus the pure Dart
`dnd_kit_core` primitives such as `DndId`, `DndRect`, collision detectors,
modifiers, events, and drag state.

See the [`dnd_kit_flutter` documentation](https://pub.dev/packages/dnd_kit_flutter)
for the full API guide and usage examples.

## Package family

| Package | Role |
| --- | --- |
| `dnd_kit_core` | Pure Dart engine: geometry, collision, modifiers, sensors, state, sortable math. Framework-agnostic. |
| `dnd_kit_flutter` | Flutter adapter: widgets, controllers, sensors, measuring, overlay, auto-scroll, sortable presets. |
| `dnd_kit` | Umbrella re-export of `dnd_kit_flutter` under the shorter name. |
