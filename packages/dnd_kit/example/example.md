# dnd_kit Example

`dnd_kit` re-exports the Flutter adapter from `dnd_kit_flutter`, so usage is
identical — import `package:dnd_kit/dnd_kit.dart` and use the same API. Full
runnable Flutter apps live in the repository-level
[`examples/`](https://github.com/vanvixi/dnd_kit/tree/main/examples)
directory.

```dart
import 'package:dnd_kit/dnd_kit.dart';
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

See the [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter) package for
the full API guide.
