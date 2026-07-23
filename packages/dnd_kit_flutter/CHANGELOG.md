# Changelog

## 0.6.0

- Depends on `dnd_kit: ^0.6.0`, inheriting the drag-default fixes: the active
  item is no longer its own drop target, drag start re-measures droppables, and
  `SortableStrategies.dropOnOver` lands the drop where the highlight is.
- **Breaking behavior:** `DndAutoScroll` now invalidates measurements and
  re-resolves collision on every auto-scroll tick, so `overId` follows content
  moving under a stationary pointer. `DndAutoScrollController` takes an
  `onScrolled` callback for direct use.
- **Breaking behavior:** `DndDragOverlay` sizes the preview from the drag-start
  rect instead of the live active rect, so collapsing the source slot to open a
  placeholder gap no longer clips the preview to zero.
  `DndDragOverlayDetails` gains a required `initialActiveRect` alongside the
  live `activeRect`.
- `DndController` exposes `initialActiveRect`.
- Adds live sortable feedback: `SortableScopeData.preview` and
  `SortableMultiScopeData.preview` report where the active item would land, and
  `SortableItemDetails` gains `previewIndex`, `previewContainerId`, and
  `offset`.
- `SortableScope` takes an `offsetResolver` (default `SortableOffsets.none`).
  Set `SortableOffsets.verticalList` and apply `details.offset` inside your
  `SortableItem.builder` — with `AnimatedSlide` or `Transform.translate` — to
  open a placeholder gap. Apply it inside the builder, not around the item, so
  the shift stays below the measured box.
- `SortableMultiContainerArea` is now a `StatefulWidget` so it can publish its
  strategy to the scope. Its constructor is unchanged.
- `SortableMultiScope` takes an `offsetResolver` (default
  `SortableMultiOffsets.none`), so a board can open a live gap within and across
  columns. Apply `details.offset` inside your `SortableMultiItem` builder.
- `DndController` takes an optional `collisionDetector` and exposes it as a
  settable property.
- `SortableMultiScope` takes an optional `collisionDetector` and installs its
  effective detector on whatever controller it is given — including one the
  application created and passed in — so a board wired to an external controller
  ranks collisions correctly with no manual setup.
- Inherits the core multi-container refinements: cross-container insertion
  tracks the pointer within the hovered card, the gap between cards (and the
  space below the last card) resolves to the nearest card, and picking an item
  up or dropping it back in place no longer reorders.


## 0.5.0

- Depends on `dnd_kit: ^0.5.0` (`DndCollisionInput.activeId`).


## 0.4.0

- Depends on `dnd_kit: ^0.4.0`.
- Adds a production multi-container adapter surface:
  `SortableMultiScope`, `SortableMultiContainerArea`, and `SortableMultiItem`.
- Default cross-container collision ranking and drag-end move resolution now
  come from the shared `dnd_kit` core contract, so apps no longer have to wire
  a custom detector or item-level `onDragEnd` callback for the common case.
- The runnable multi-container example now uses the supported adapter surface
  and a single-phase application-owned state update.
- Keeps exporting the experimental multi-container helper contract from
  `package:dnd_kit_flutter/dnd_kit_flutter.dart`, but the underlying
  `SortableContainer` and `SortableMultiContainer` source now lives in the
  shared `dnd_kit` engine so Jaspr can reuse the same move-intent helper.

## 0.3.2

- Updates the pub.dev homepage metadata to the hosted project website.
- Refreshes the package links for the repository transfer to
  `iamv4g/dnd_kit`.
- Depends on `dnd_kit: ^0.3.2` with no runtime API changes.

## 0.3.1

- Depends on `dnd_kit: ^0.3.1`, which now owns the shared `DndAnnouncements`
  accessibility contract reused by both adapters.
- Adds scope-level drag lifecycle announcements for assistive technologies
  through Flutter's announcement APIs.
- `DndDraggable` and `DndDragHandle` now support optional semantics `label`
  and `hint` fields so applications can provide accessible naming and usage
  instructions without forking drag behavior.
- Keyboard drag focus stays on the activator through pickup, movement, drop,
  and cancel flows, with widget-test coverage for focus and announcement
  behavior.

## 0.3.0

- Depends on the renamed engine package `dnd_kit: ^0.3.0` (previously
  `dnd_kit_core`, now discontinued). The dependency rename tracks the engine
  package becoming `dnd_kit`. See ADR 0017.
- Adopts the axis-aware shared auto-scroll contract from `dnd_kit` by adding
  horizontal support to `DndAutoScroll` and `DndAutoScrollController` while
  preserving vertical default behavior.
- The Kanban example now uses `DndAutoScroll(axis: DndScrollAxis.horizontal)`
  instead of a custom app-owned horizontal board auto-scroll helper.

## 0.2.0-dev.0

- Starts the shared-runtime development line for `dnd_kit_flutter` on top of
  `dnd_kit_core: ^0.2.0-dev.0`.
- **Breaking:** `DndPointerSensor` moved to `dnd_kit_core` and is now driven by a
  `DndRuntime` instead of a `DndController`. Construct it with
  `DndPointerSensor(runtime: controller.runtime, ...)`. The class remains
  importable from `package:dnd_kit_flutter/dnd_kit_flutter.dart` via re-export.
  This lets the Flutter and Jaspr adapters share one pointer-activation state
  machine.
- Added `DndController.runtime` to expose the shared runtime to adapter sensors.

## 0.1.0

- First public release of the Flutter adapter under the
  `dnd_kit_flutter` name (previously published as `dnd_kit`). Includes
  scope/controller, draggable, droppable, drag handle, overlay,
  pointer/long-press/keyboard sensors, measuring, auto-scroll, diagnostics, and
  stable sortable presets.
- Depends on `dnd_kit_core: ^0.1.0`.
- **Breaking:** removed `DndLongPressActivation.hapticFeedback`. Haptic
  feedback is now configured through `DndDraggable.enableHapticFeedback` or the
  nearest `DndScope.enableHapticFeedback` default, which defaults to `true`.
- Touch drag activation now emits one `HapticFeedback.selectionClick()` pulse
  by default when the drag starts, including both the platform-adaptive delayed
  touch path and explicit `longPressActivation`. Mouse, trackpad, and keyboard
  activations emit no haptic feedback.
- Fixed active drag geometry so overlays and collision detection stay aligned
  with the pointer when a scrollable ancestor moves during the drag.
- Draggables now work inside scrollables, including lazy `ListView.builder`.
  `DndDraggable` activates through an arena-winning `MultiDragGestureRecognizer`
  instead of a pan recognizer, so a drag can start without losing the gesture to
  an enclosing `Scrollable`.
- **Behavior change:** default activation is now platform-adaptive — precise
  pointers (mouse) drag immediately, while touch uses a short hold (delayed) so a
  quick touch can still scroll. Set
  `activationConstraint: DndSensorActivationConstraint(distance: …)` for
  immediate touch drag.
- Sortable strategies (`verticalList`, `horizontalList`, `grid`) now compute
  reorder intent from the measured (visible) item subset, so reordering stays
  correct in lazy lists where off-screen items are not measured.
- An active drag and its registration/measured rect now survive the source
  element being recycled by a lazy list mid-drag.
- Fixed a `Duplicate draggable/droppable id` crash that could occur while
  auto-scrolling a lazy list during a drag, when the list re-mounts a keyed
  item before disposing the old one. `findChildIndexCallback` is now a
  performance recommendation rather than a requirement.
- Duplicate `DndDraggable`/`DndDroppable` ids that remain mounted after widget
  reconciliation now surface an actionable `DndDiagnosticsConfig.onWarning`
  callback instead of staying silently last-wins.
- The Kanban and multi-container examples now use `ListView.builder` (with
  `findChildIndexCallback`) to demonstrate lazy sortable columns. The Kanban
  board is lazy in both axes — the horizontal column row and each column's
  vertical task list. Their task cards use the default platform-adaptive
  activation (immediate with a mouse, hold-to-drag on touch) so a quick swipe
  scrolls the list instead of starting a drag.

## 0.1.0-dev.1

- Added a package-local `example/example.md` so pub.dev can render a compact
  illustrative example for the package.
- Clarified package README links to the quick example and full runnable
  repository examples.
- Updated the `dnd_kit_core` dependency to `^0.1.0-dev.1`.

## 0.1.0-dev.0

- Initial development release of the main `dnd_kit` Flutter package.
- Includes core drag/drop widgets, scope/controller APIs, pointer, long-press,
  and keyboard activation, measuring, collision runtime, modifiers, drag
  overlays, visual state builders, auto-scroll, diagnostics, and stable
  sortable list/grid presets.
- Exposes the pure Dart `dnd_kit_core` API through the main package for
  application convenience.
- Keeps experimental multi-container sortable helpers out of the stable
  same-container sortable contract.
