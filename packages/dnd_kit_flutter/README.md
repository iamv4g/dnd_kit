# dnd_kit_flutter

`dnd_kit_flutter` is the Flutter adapter of the dnd_kit toolkit for building
sortable lists, grids, Kanban boards, dashboards, canvas editors, and other
drag-heavy interfaces. It builds on the framework-agnostic `dnd_kit` engine.

Try the hosted example gallery:
https://vanvixi.github.io/dnd_kit/

The package is centered on Flutter-native widgets and controllers:

- `DndScope` and `DndController` coordinate drag state.
- `DndDraggable` registers draggable widgets.
- `DndDroppable` registers drop targets.
- `DndDragOverlay` renders an independent drag visual.
- `SortableScope` and `SortableItem` provide stable same-container list and
  grid sorting presets.

Applications own their data. The library reports drag, drop, and sortable move
intent; your app updates its own lists, boards, stores, or documents.

## Import

```dart
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
```

This entry point also exports the pure Dart `dnd_kit` engine primitives such as
`DndId`, `DndRect`, collision detectors, modifiers, events, and drag state.

## Basic Drag And Drop

Wrap the drag-and-drop area in a `DndScope`, then place draggables and
droppables inside it.

```dart
DndScope(
  child: Stack(
    children: [
      DndDroppable(
        id: const DndId('inbox'),
        builder: (context, details, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: details.isOver ? const Color(0xff2563eb) : const Color(0xffd1d5db),
              ),
            ),
            child: child,
          );
        },
        child: const SizedBox(width: 240, height: 160),
      ),
      DndDraggable(
        id: const DndId('task-1'),
        onDragEnd: (event) {
          final overId = event.overId;
          if (overId == const DndId('inbox')) {
            // Update application-owned state here.
          }
        },
        child: const Card(child: ListTile(title: Text('Task 1'))),
      ),
      DndDragOverlay(
        builder: (context, details) {
          return const Card(child: ListTile(title: Text('Task 1')));
        },
      ),
    ],
  ),
)
```

Use `DndDraggable.builder` and `DndDroppable.builder` when visuals need to
react to active, dragging, dropping, or over states.

## Sortable Lists And Grids

Use `SortableScope` to provide the current item order and `SortableItem` for
each child. The callback tells the app what moved; it does not mutate the list.

```dart
SortableScope(
  itemIds: items.map((item) => DndId(item.id)),
  strategy: SortableStrategies.verticalList,
  onMove: (details) {
    setState(() {
      final item = items.removeAt(details.fromIndex);
      items.insert(details.toIndex, item);
    });
  },
  child: ListView(
    children: [
      for (final item in items)
        SortableItem(
          id: DndId(item.id),
          child: ListTile(title: Text(item.title)),
        ),
    ],
  ),
)
```

Stable strategies include:

- `SortableStrategies.verticalList`
- `SortableStrategies.horizontalList`
- `SortableStrategies.grid`

## Customization

Core behavior is intentionally open:

- pass a custom `DndCollisionDetector` to `DndController`;
- compose built-in detectors with `DndCollisionDetectors.compose`;
- constrain movement with `DndModifier` values such as
  `DndModifiers.restrictToVerticalAxis` or `DndModifiers.snapToGrid`;
- use `DndLongPressActivation` or `DndSensorActivationConstraint` to tune
  activation;
- attach `DndDiagnosticsConfig.onWarning` to surface duplicate ID and registry
  warnings.

## Accessibility

`dnd_kit_flutter` keeps the Flutter adapter's accessibility model adapter-local
and Flutter-native. `DndAnnouncements` comes from the shared `dnd_kit` engine,
while `DndDraggable` and `DndDragHandle` accept optional semantics labels and
hints and `DndScope` can opt into drag lifecycle announcements for assistive
technologies.

```dart
DndScope(
  announcements: const DndAnnouncements(),
  child: DndDraggable(
    id: const DndId('task-1'),
    label: 'Quarterly planning task',
    hint: 'Press Space to pick up, arrow keys to move, Enter to drop.',
    child: ListTile(
      title: const Text('Quarterly planning'),
      trailing: const DndDragHandle(
        label: 'Reorder handle',
        hint: 'Drag from here to move this task.',
        child: Icon(Icons.drag_indicator),
      ),
    ),
  ),
)
```

Announcements are derived from shared controller state transitions and the
shared `DndAnnouncements` contract, so keyboard and pointer drags speak the
same start, over-target, drop, and cancel events without introducing a second
drag runtime.

## dnd_kit family

| Package                                                       | Use it for                                                                            |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter) | Flutter apps — widgets, sensors, overlays, and sortable presets. |
| [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr)     | Jaspr (Dart web) apps — the current dev adapter release.         |
| [`dnd_kit`](https://pub.dev/packages/dnd_kit)                 | The shared, framework-agnostic engine.                          |
