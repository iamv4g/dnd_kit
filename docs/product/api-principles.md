# API Principles

## Shared Family Naming

Use family-consistent names across adapters where practical:

- `DndScope`
- `DndController`
- `DndDraggable`
- `DndDroppable`
- `DndDragHandle`
- `DndDragOverlay`
- `SortableScope`
- `SortableItem`

Avoid React-specific API shapes such as `DndContext`, `useDraggable`,
`useDroppable`, or hook-style naming.

Adapter barrels stay framework-specific:

- Flutter apps import `package:dnd_kit_flutter/dnd_kit_flutter.dart`.
- Jaspr apps import `package:dnd_kit_jaspr/dnd_kit_jaspr.dart`.
- Engine-only users import `package:dnd_kit/dnd_kit.dart`.

## Shared Scope And Controller Lifecycle

Adapters that expose `DndScope` / `DndController` pairing must support both
controlled and uncontrolled lifecycle modes.

Flutter-style example:

```dart
DndScope(
  child: App(),
)
```

Controlled:

```dart
final controller = DndController();

DndScope(
  controller: controller,
  child: App(),
)
```

Rules:

- If the user provides a controller, the user owns its lifecycle.
- If no controller is provided, `DndScope` creates and disposes an internal
  controller.
- `DndScope` must never dispose an external controller.

## Users Own Data

The library reports drag/drop intent. It must not mutate user collections,
tasks, boards, or app state.

Sortable callbacks provide enough information for the user to mutate their own
data with `setState`, Riverpod, BLoC, Provider, Redux, or any other approach.

## Stable IDs

`DndId` wraps an application-owned `String` value. The value must be stable
during the widget lifecycle and is compared as an exact string match.

The library does not trim, case-fold, normalize, parse, or namespace ID values.
Applications should pass the same canonical string they use to identify the
underlying item, container, or user-owned entity.

Prefer:

```dart
DndId(task.id)
DndId('column-todo')
DndId(user.id)
DndId('column:${column.id}/task:${task.id}')
```

Avoid:

```dart
DndId('')
DndId('   ')
DndId(UniqueKey().toString())
DndId(DateTime.now().toIso8601String())
DndId(Object().toString())
```

Empty values are invalid. Whitespace-only values should be treated as invalid
by application code because they make diagnostics and duplicate detection hard
to understand.

Duplicate IDs inside a registry should be caught by debug diagnostics.
Recoverable registry diagnostics should also be available through
`DndDiagnosticsConfig.onWarning` so applications can surface actionable
warnings without depending only on debug assertions.

## Shared Drag And Registry Principles

- Drag activation must coexist with scrolling; adapters should specialize the
  exact activation mechanics to their platform without changing the core drag
  contract.
- Sortable strategies operate on the measured (visible) item subset, so reorder
  intent stays correct when off-screen items are not currently measured.
- An active drag and its registration survive the source element being recycled
  during the drag.
- Registration is owner-aware: a new owner can take over an id before the old
  owner disposes, and a departing owner cannot remove a registration a newer
  owner already took over. If duplicate owners still remain after
  reconciliation, `DndDiagnosticsConfig.onWarning` emits a deferred duplicate
  warning. The strict duplicate-id debug assertion still applies only to direct
  `DndRegistry` usage without an `owner`.

## Flutter Adapter Notes

- `DndDraggable` activates through an arena-winning `MultiDragGestureRecognizer`,
  not a plain pan recognizer, so a drag can start inside a `Scrollable`.
- The default activation is platform-adaptive: precise pointers (mouse) drag
  immediately; touch uses a short hold (delayed) so a quick touch still scrolls
  an ancestor list. This matches `ReorderableListView` conventions.
- Touch activation emits one selection-style haptic pulse when the drag starts
  by default. Resolve haptic feedback with
  `DndDraggable.enableHapticFeedback` first, then the nearest `DndScope`
  default, which is non-null and defaults to `true`, then the library default
  of `true` only when no scope exists. Mouse, trackpad, and keyboard
  activations do not emit haptics.
- `activationConstraint` and `longPressActivation` override the default:
  `distance` drags immediately on all pointers after the threshold, `delay`
  (and `longPressActivation`) drag after a hold.
- For immediate touch drag (e.g. outside a scrollable), set an explicit
  `activationConstraint: DndSensorActivationConstraint(distance: …)`.
- When using `ListView.builder` with reorderable content, providing
  `findChildIndexCallback` is recommended so keyed items are relocated (not
  rebuilt) on reorder. It is a performance optimization, not a correctness
  requirement.

## Jaspr Adapter Notes

- The browser adapter supports pointer, mouse, touch, and keyboard activation,
  DOM measuring, overlay rendering, browser auto-scroll execution, and
  live-region accessibility over the shared engine.
- Shared accessibility copy customization belongs in the pure-Dart
  `DndAnnouncements` contract; adapter execution of those announcements stays
  local to Flutter semantics APIs and Jaspr live regions.
- Browser access must remain SSR-safe: no DOM requirement at import time, and
  browser-only behavior stays guarded behind runtime checks.
- Where parity is portable, Flutter and Jaspr should preserve the same
  drag/drop meaning even when the framework-specific event wiring differs.

## Performance Principles

- Do not rebuild the whole app on every pointer move.
- Update overlays independently from source layout.
- Cache measuring data during drag where possible.
- Run collision detection at most once per frame.
- Keep core algorithms testable without Flutter or Jaspr.
