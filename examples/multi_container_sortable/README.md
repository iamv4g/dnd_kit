# Experimental Multi-Container Sortable Example

This example shows the experimental multi-container sortable API shape. The API
is annotated with `@experimental`, now lives in the shared `dnd_kit` engine,
and can change before V1.

```dart
final containers = <SortableContainer>[
  SortableContainer(
    id: const DndId('todo'),
    itemIds: const <DndId>[DndId('task-1'), DndId('task-2')],
  ),
  SortableContainer(
    id: const DndId('done'),
    itemIds: const <DndId>[DndId('task-3')],
  ),
];

void handleDragEnd(DndDragEndEvent event) {
  final move = SortableMultiContainer.moveDetailsFor(
    event,
    containers: containers,
  );

  if (move == null) {
    return;
  }

  // Applications own mutation. Remove move.activeId from
  // move.fromContainerId at move.fromIndex, then insert it into
  // move.toContainerId at move.toIndex.
}
```

Use the stable `SortableScope` and `SortableItem` APIs for same-container lists
and grids. Reach for this experimental surface only when prototyping movement
between application-owned containers.
