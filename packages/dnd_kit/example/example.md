# dnd_kit Example

`dnd_kit` provides pure Dart geometry, collision, modifier, state, sensor,
registry, runtime, and diagnostics primitives. It has no Flutter dependency.

```dart
import 'package:dnd_kit/dnd_kit.dart';

void main() {
  const activeRect = DndRect(left: 0, top: 0, width: 80, height: 40);
  const droppableRects = <DndId, DndRect>{
    DndId('todo'): DndRect(left: 0, top: 80, width: 240, height: 200),
    DndId('done'): DndRect(left: 280, top: 80, width: 240, height: 200),
  };

  final collisions = DndCollisionDetectors.closestCenter(
    const DndCollisionInput(
      activeRect: activeRect,
      droppableRects: droppableRects,
    ),
  );

  final overId = collisions.isEmpty ? null : collisions.first.id;
  print('Dragging over: ${overId?.value}');
}
```

Use `dnd_kit` directly when you need testable drag/drop math or contracts
without Flutter widgets. For full Flutter scopes, draggables, droppables,
overlays, sensors, auto-scroll, and sortable presets, use
[`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter). For Jaspr web
apps, use [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr).
