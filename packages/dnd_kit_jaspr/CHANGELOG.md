# Changelog

## 0.2.0-dev.0

- First public development release of `dnd_kit_jaspr`.
- Ships the first shared-runtime Jaspr drag-and-drop surface:
  `DndScope`, `DndController`, `DndDraggable`, `DndDroppable`,
  `DndDragHandle`, and `DndDragOverlay`.
- Supports mouse, touch, and keyboard drag activation on top of the shared
  `DndRuntime`, including handle-only activation and keyboard drag flows.
- Adds vertical `DndAutoScroll` for browser scroll containers, reusing the
  shared `dnd_kit_core` auto-scroll edge and velocity math.
- Adds accessibility support through `DndLiveRegion` and
  `DndAnnouncements`, plus accessible labels/descriptions for draggables and
  drag handles.
- Includes browser-tested modifier behavior and the
  `examples/jaspr_basic_drag_drop` example app as the current integration proof.
- Keeps the adapter SSR-safe: browser access stays guarded and no Flutter
  dependency is introduced.
- Sortable presets are not included yet; they follow in a later phase.
