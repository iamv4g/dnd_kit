# dnd_kit_jaspr

Jaspr (web) adapter for the [`dnd_kit`](https://github.com/vanvixi/dnd_kit)
drag-and-drop family.

`dnd_kit_jaspr` is built on the shared `dnd_kit_core` engine, so Jaspr and
Flutter behave as peer adapters over one drag runtime — the same domain model,
drag lifecycle, collision logic, modifiers, and sortable math. It depends only
on `dnd_kit_core` and `jaspr` (no Flutter).

> Status: first public development release. This package provides `DndScope`,
> `DndController`, `DndDraggable`, `DndDroppable`, `DndDragHandle`,
> `DndDragOverlay`, `DndAutoScroll`, and `DndLiveRegion` over the shared runtime.
> Shared modifiers are exercised in browser tests, and
> `examples/jaspr_basic_drag_drop` is the runnable app used for browser proof.
> Sortable presets are still in progress. See `SPEC_JASPR.md`,
> `docs/stories/phase-14-jaspr-foundation/`, and
> `docs/stories/phase-15-jaspr-hardening/`.

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

### Auto-scroll

Wrap a scroll container in `DndAutoScroll` to scroll it while a drag rests near
its top or bottom edge. The edge/velocity math is shared with Flutter via
`dnd_kit_core`; the Jaspr component only adds the browser scroll execution.
Style the rendered viewport so it scrolls vertically (a bounded height plus
`overflow`):

```dart
DndAutoScroll(
  styles: Styles(
    height: 400.px,
    overflow: Overflow.only(y: Overflow.auto),
  ),
  child: longDraggableList,
);
```

Horizontal auto-scroll is not yet supported.

### Accessibility

Mount a `DndLiveRegion` inside the scope to announce drag start, drag-over
changes, drop, and cancel to screen readers. Messages come from a configurable
`DndAnnouncements` (with English defaults) provided through `DndScope`, and
draggables/handles accept an accessible `label` plus optional keyboard
`description`:

```dart
DndScope(
  announcements: const DndAnnouncements(),
  child: Component.fragment([
    DndDraggable(
      id: const DndId('task-1'),
      label: 'Task one',
      description: 'Press space to lift, arrow keys to move, space to drop.',
      child: myCard,
    ),
    const DndLiveRegion(),
  ]),
);
```

Keyboard drags keep focus on the activator throughout pickup, movement, and
drop/cancel.

## Example

See `examples/jaspr_basic_drag_drop` for a runnable Jaspr browser app that
wires `DndScope`, `DndDraggable`, `DndDroppable`, `DndDragHandle`,
`DndDragOverlay`, and shared-runtime modifiers into one small flow.

## dnd_kit family

Project home: https://vanvixi.github.io/dnd_kit/

| Package                                                       | Use it for                                                                                 |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [`dnd_kit`](https://pub.dev/packages/dnd_kit)                 | Flutter apps — the stable, recommended Flutter entry point (re-exports `dnd_kit_flutter`). |
| [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter) | Flutter apps that want dev releases or the explicit adapter package.                       |
| [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr)     | Jaspr (Dart web) apps — the current dev adapter release.                                   |
| [`dnd_kit_core`](https://pub.dev/packages/dnd_kit_core)       | The shared, framework-agnostic engine.                                                     |
