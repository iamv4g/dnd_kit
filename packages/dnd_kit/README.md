# dnd_kit

`dnd_kit` is a Flutter drag-and-drop toolkit for building sortable lists,
grids, Kanban boards, dashboards, canvas editors, and other drag-heavy
interfaces.

This is the **stable Flutter entry point**. It is a thin umbrella that re-exports
the Flutter adapter from
[`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter), which is built on
the framework-agnostic [`dnd_kit_core`](https://pub.dev/packages/dnd_kit_core)
engine. Importing `dnd_kit` and `dnd_kit_flutter` gives you the exact same API;
`dnd_kit` simply offers the shorter name.

`dnd_kit` publishes **stable releases only**. If you want the latest dev
releases, depend on `dnd_kit_flutter` directly. Building for **Jaspr** (Dart
web) instead of Flutter? Use `dnd_kit_jaspr` — `dnd_kit` requires the
Flutter SDK and is not usable in a pure Jaspr project.

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

## dnd_kit family

| Package                                                       | Use it for                                                                                 |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [`dnd_kit`](https://pub.dev/packages/dnd_kit)                 | Flutter apps — the stable, recommended Flutter entry point (re-exports `dnd_kit_flutter`). |
| [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter) | Flutter apps that want dev releases or the explicit adapter package.                       |
| [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr)     | Jaspr (Dart web) apps — the current dev adapter release.                                   |
| [`dnd_kit_core`](https://pub.dev/packages/dnd_kit_core)       | The shared, framework-agnostic engine.                                                     |
