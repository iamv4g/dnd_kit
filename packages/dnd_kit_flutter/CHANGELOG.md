# Changelog

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
