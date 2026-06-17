# dnd_kit_jaspr Example

This package-local example gives pub.dev a compact, illustrative sample. The
full runnable Jaspr browser app lives in the repository-level
[`examples/jaspr_basic_drag_drop`](https://github.com/vanvixi/dnd_kit/tree/main/examples/jaspr_basic_drag_drop)
directory.

```dart
import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class TaskBoard extends StatelessComponent {
  const TaskBoard({super.key});

  @override
  Component build(BuildContext context) {
    return DndScope(
      child: Component.fragment([
        DndDroppable(
          id: const DndId('done'),
          builder: (context, details, child) {
            return div(
              classes: details.isOver ? 'lane lane--active' : 'lane',
              [child ?? text('Drop here')],
            );
          },
          child: div([text('Done')]),
        ),
        DndDraggable(
          id: const DndId('task-1'),
          label: 'Task 1',
          child: div(classes: 'card', [text('Task 1')]),
        ),
        const DndLiveRegion(),
      ]),
    );
  }
}
```

More complete examples:

- [`examples/jaspr_basic_drag_drop`](https://github.com/vanvixi/dnd_kit/tree/main/examples/jaspr_basic_drag_drop)
  shows a runnable browser drag/drop app with handles, overlay, modifiers, and
  shared-runtime behavior.
