# dnd_kit_flutter Example

This package-local example gives pub.dev a compact, illustrative sample. Full
runnable Flutter apps live in the repository-level
[`examples/`](https://github.com/vanvixi/dnd_kit/tree/main/examples)
directory.

```dart
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

class TaskDropZone extends StatelessWidget {
  const TaskDropZone({super.key});

  @override
  Widget build(BuildContext context) {
    return DndScope(
      child: Stack(
        children: [
          DndDroppable(
            id: const DndId('done'),
            builder: (context, details, child) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: details.isOver ? Colors.blue : Colors.grey,
                  ),
                ),
                child: child,
              );
            },
            child: const SizedBox(
              width: 240,
              height: 160,
              child: Center(child: Text('Drop here')),
            ),
          ),
          DndDraggable(
            id: const DndId('task-1'),
            onDragEnd: (event) {
              if (event.overId == const DndId('done')) {
                // Update application-owned task state here.
              }
            },
            child: const Card(
              child: ListTile(title: Text('Task 1')),
            ),
          ),
          DndDragOverlay(
            builder: (context, details) {
              return const Card(
                child: ListTile(title: Text('Task 1')),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

More complete examples:

- [`examples/basic_drag_drop`](https://github.com/vanvixi/dnd_kit/tree/main/examples/basic_drag_drop)
  shows a small runnable drag/drop app.
- [`examples/kanban_board`](https://github.com/vanvixi/dnd_kit/tree/main/examples/kanban_board)
  shows a realistic board built with generic drag/drop APIs.
- [`examples/multi_container_sortable`](https://github.com/vanvixi/dnd_kit/tree/main/examples/multi_container_sortable)
  documents the experimental multi-container sortable shape.
