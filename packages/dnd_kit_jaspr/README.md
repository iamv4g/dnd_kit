# dnd_kit_jaspr

Jaspr (web) adapter for the [`dnd_kit`](https://github.com/vanvixi/dnd_kit)
drag-and-drop family.

`dnd_kit_jaspr` is built on the shared `dnd_kit_core` engine, so Jaspr and
Flutter behave as peer adapters over one drag runtime — the same domain model,
drag lifecycle, collision logic, modifiers, and sortable math. It depends only
on `dnd_kit_core` and `jaspr` (no Flutter).

> Status: early development. This release provides `DndScope`,
> `DndController`, `DndDraggable`, `DndDroppable`, and `DndDragHandle` over
> the shared runtime. Overlay and sortable presets are still in progress. See
> `SPEC_JASPR.md` and
> `docs/stories/phase-14-jaspr-foundation/`.

## Usage

```dart
import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';

// Wrap an interactive subtree in a DndScope; descendants read the controller
// via DndScope.of(context).
DndScope(
  child: myDragDropUi,
);
```

Applications own their item, board, or document data. `dnd_kit_jaspr` reports
drag/drop intent so app code updates its own state.
