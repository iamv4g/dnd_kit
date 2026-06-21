# Changelog

## 0.3.1

- Fixes a framework assertion (`owner._debugCurrentBuildTarget != null`) thrown
  during static/server pre-rendering when a `DndDraggable` contains a
  `DndDragHandle`. Registering a handle scheduled a deferred `setState` that ran
  outside a build owner on the server; it is now guarded to the client. The
  pre-rendered markup matches the first client build, so hydration reuses the
  subtree instead of replacing it.
- Depends on `dnd_kit: ^0.3.1` and now reuses the shared `DndAnnouncements`
  accessibility contract from the core package instead of maintaining a local
  duplicate.

## 0.3.0

- Depends on the renamed engine package `dnd_kit: ^0.3.0` (previously
  `dnd_kit_core`, now discontinued). The dependency rename tracks the engine
  package becoming `dnd_kit`. See ADR 0017.
- Adds the Jaspr sortable preset at parity with the Flutter adapter:
  `SortableScope` (item order + pluggable `SortableStrategy`, default
  `verticalList`) and `SortableItem` (a draggable + droppable that reports
  `SortableMoveDetails` reorder intent via `onMove`).
- Reuses the shared `dnd_kit` engine reorder math, so Jaspr and Flutter compute
  identical move intent and Jaspr inherits the vertical/horizontal/grid
  single-container strategies already re-exported from the engine. See ADR 0019.
- Multi-container sorting (`SortableContainer`/`SortableMultiContainer`) is not
  included; it remains a Flutter-only experimental feature for now.
- Extends `DndAutoScroll` with axis-aware browser execution, so Jaspr scroll
  containers can auto-scroll horizontally through the shared `dnd_kit`
  velocity math while preserving the existing vertical default.
- Keeps Jaspr auto-scroll execution component-owned rather than introducing a
  separate controller surface, because DOM node ownership, timer lifecycle,
  and SSR guards still belong to the rendered viewport component.
- Fixes `DndDragOverlay` rebinding when the nearest `DndScope` controller is
  replaced, so overlays stay synchronized after a controlled scope/controller
  swap.

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
