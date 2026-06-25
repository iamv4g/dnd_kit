# dnd_kit_jaspr

Jaspr (web) adapter for the [`dnd_kit`](https://github.com/iamv4g/dnd_kit)
drag-and-drop family.

`dnd_kit_jaspr` is built on the shared `dnd_kit` engine, so Jaspr and
Flutter behave as peer adapters over one drag runtime — the same domain model,
drag lifecycle, collision logic, modifiers, sortable math, and auto-scroll
curve. It depends only on `dnd_kit` and `jaspr` (no Flutter).

> Status: stable `0.4.0` release. This package provides `DndScope`,
> `DndController`, `DndDraggable`, `DndDroppable`, `DndDragHandle`,
> `DndDragOverlay`, `DndAutoScroll`, `DndLiveRegion`, `SortableScope`, and
> `SortableItem` over the shared runtime. Shared modifiers and sortable
> behavior are exercised in browser and component tests, and
> `examples/jaspr_example_gallery` is the runnable app used for browser proof.
> See `SPEC_JASPR.md`, `docs/stories/phase-14-jaspr-foundation/`,
> `docs/stories/phase-15-jaspr-hardening/`, and
> `docs/stories/phase-18-jaspr-sortable/`, and
> `docs/stories/phase-20-jaspr-example-gallery/`, and
> `docs/stories/phase-21-jaspr-adapter-fixes/`.

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

### Sortable

Use `SortableScope` and `SortableItem` for single-container sortable UIs.
The reorder math is shared with Flutter via `dnd_kit`, so both adapters compute
the same `SortableMoveDetails` intent for vertical, horizontal, and grid
strategies.

### Auto-scroll

Wrap a scroll container in `DndAutoScroll` to scroll it while a drag rests near
its leading or trailing edge on the selected axis. The edge/velocity math is
shared with Flutter via `dnd_kit`; the Jaspr component only adds the browser
scroll execution. Style the rendered viewport so it scrolls on that axis:

```dart
DndAutoScroll(
  axis: DndScrollAxis.horizontal,
  styles: Styles(
    width: 600.px,
    overflow: Overflow.only(x: Overflow.auto),
  ),
  child: wideDraggableRow,
);
```

Vertical remains the default. Unlike Flutter, Jaspr does not expose a separate
`DndAutoScrollController`; the component keeps browser execution local so DOM
node ownership, timer lifecycle, and SSR guards stay tied to the rendered
viewport.

### Accessibility

Mount a `DndLiveRegion` inside the scope to announce drag start, drag-over
changes, drop, and cancel to screen readers. Messages come from a configurable
`DndAnnouncements` (shared from `dnd_kit`, with English defaults) provided
through `DndScope`, and draggables/handles accept an accessible `label` plus
optional keyboard `description`:

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

See `examples/jaspr_example_gallery` for a runnable tabbed Jaspr browser
feature gallery covering generic drag/drop, sortable, auto-scroll,
accessibility, and shared-runtime modifiers.

## dnd_kit family

| Package                                                       | Use it for                                                                                 |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [`dnd_kit_flutter`](https://pub.dev/packages/dnd_kit_flutter) | Flutter apps — widgets, sensors, overlays, and sortable presets. |
| [`dnd_kit_jaspr`](https://pub.dev/packages/dnd_kit_jaspr)     | Jaspr (Dart web) apps — the current dev adapter release.         |
| [`dnd_kit`](https://pub.dev/packages/dnd_kit)                 | The shared, framework-agnostic engine.                          |
