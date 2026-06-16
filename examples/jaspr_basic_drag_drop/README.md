# Jaspr Basic Drag Drop Example

Runnable browser example for `dnd_kit_jaspr`.

It demonstrates:

- `DndScope` controller ownership;
- `DndDraggable`, `DndDroppable`, and `DndDragHandle`;
- `DndDragOverlay` for the active drag visual;
- application-owned drop state;
- modifier-shaped drag movement driven by the shared runtime.

Current behavior: pressing and dragging the visible `DndDragHandle` starts a real
browser drag through the shared `DndRuntime`. The active gesture is tracked with
capture-phase window pointer listeners, so the drag keeps moving and drops
cleanly even after the pointer leaves the draggable's own DOM subtree (the US-055
regression fix). A live status panel shows the controller state and drag
counters, and dropping across lanes updates the example's own (`Brief` → `Ship`)
state on `onDragEnd` while the library only reports intent.

This is the app used for the US-053/US-055 browser proof: a real-browser drag on
`http://localhost:8080` leaves `DndIdle`, reports non-zero start/move/end metrics
(`s:1 m:5 e:1 c:0`), and moves the lane. Automated coverage lives in
`packages/dnd_kit_jaspr/test/draggable_browser_test.dart` (incl. the
leaves-subtree regression case) and `drag_overlay_browser_test.dart`.

## Run

```bash
cd examples/jaspr_basic_drag_drop
~/.pub-cache/bin/jaspr serve
```

The development server defaults to `http://localhost:8080`.

## Build

```bash
cd examples/jaspr_basic_drag_drop
~/.pub-cache/bin/jaspr build
```
