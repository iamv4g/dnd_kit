# dnd_kit_jaspr Feature Gallery

A single runnable Jaspr client app that demonstrates every supported
`dnd_kit_jaspr` surface over the shared `dnd_kit` runtime. The app is a tabbed
gallery; each tab is a self-contained demo with its own controller and
app-owned state, so switching tabs creates and disposes drag state cleanly.

## Demos

| Tab | Surfaces | What it shows |
| --- | --- | --- |
| **Basic** | `DndScope`, `DndDraggable`, `DndDroppable`, `DndDragHandle`, `DndDragOverlay` | Handle-only pickup, free-form pointer drag, over-target highlight, and an overlay that follows the runtime; dropping across lanes updates app state. |
| **Sortable** | `SortableScope`, `SortableItem`, `SortableStrategies.verticalList`, `DndDragOverlay`, `DndLiveRegion` | A reorderable list whose move intent comes from the shared engine strategy; state-aware row rendering via the item builder; pointer and keyboard reordering. |
| **Auto-scroll** | `DndAutoScroll`, `DndScrollAxis` | A bounded viewport that scrolls while the drag pointer rests in its leading/trailing edge band, reusing the shared core velocity curve, so a token can reach off-screen slots. An axis toggle switches between vertical and horizontal auto-scroll. |
| **Accessibility** | `DndLiveRegion`, custom `DndAnnouncements`, keyboard dragging, `aria-label`/`aria-describedby` | Keyboard pickup/move/drop/cancel, focusable draggables with instructions, and a visible panel that mirrors exactly what the live region announces. |
| **Modifiers** | `DndModifiers` (`restrictToVerticalAxis`, `restrictToHorizontalAxis`, `snapToGrid`) | Per-controller modifiers reshape the drag transform in the runtime before collision, so the overlay follows a constrained path. |

Every demo keeps its own data external: lanes, list order, column placement,
and token slot are updated by app code from reported drag intent — the library
only reports intent.

## Keyboard and accessibility

Each draggable is a focusable `role="button"` with an `aria-label` and an
`aria-describedby` instruction string. Drive any demo from the keyboard:

- **Tab** to a draggable (or its handle),
- **Space** / **Enter** to pick up,
- **Arrow keys** to move,
- **Space** / **Enter** to drop,
- **Escape** to cancel.

A visually-hidden `DndLiveRegion` announces every transition; the Accessibility
tab also mirrors those announcements on screen.

## Run

```bash
cd examples/jaspr_example_gallery
~/.pub-cache/bin/jaspr serve
```

The development server defaults to `http://localhost:8080`.

## Build

```bash
cd examples/jaspr_example_gallery
~/.pub-cache/bin/jaspr build
```

## Notes

- The example stays SSR-safe and client-runnable; it adds no dependencies beyond
  `jaspr` and the local `dnd_kit_jaspr` path package.
- Multi-container sortable is not shown: `SortableContainer` /
  `SortableMultiContainer` are not yet part of `dnd_kit_jaspr` (tracked in
  `docs/stories/backlog.md`).
- Automated browser coverage for the underlying components lives in
  `packages/dnd_kit_jaspr/test/*_browser_test.dart`.
