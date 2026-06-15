# API Principles

## Flutter-Style Naming

Use Flutter-native names:

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

## Controlled And Uncontrolled Scope

`DndScope` must support both lifecycle modes.

Uncontrolled:

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

## Activation Principles

Drag activation must coexist with scrolling so draggables work inside lazy
lists (`ListView.builder`).

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

## Lazy List Principles

- Sortable strategies operate on the measured (visible) item subset, so reorder
  intent stays correct when off-screen items are not built.
- An active drag and its registration survive the source element being recycled
  by a lazy list mid-drag.
- Registration is owner-aware: a lazy list may re-mount a keyed item (new owner)
  before disposing the old element without tripping duplicate-id detection, and
  a departing owner cannot remove a registration a newer owner took over. As a
  result, registering an id through a widget is last-wins during the current
  frame; if multiple widget owners still claim the same id after reconciliation,
  `DndDiagnosticsConfig.onWarning` emits a deferred duplicate warning. The
  strict duplicate-id debug assertion still applies only to direct
  `DndRegistry` use without an `owner`.
- When using `ListView.builder` with reorderable content, providing
  `findChildIndexCallback` is recommended so keyed items are relocated (not
  rebuilt) on reorder. It is a performance optimization, not a correctness
  requirement.

## Performance Principles

- Do not rebuild the whole app on every pointer move.
- Update overlays independently from source layout.
- Cache measuring data during drag where possible.
- Run collision detection at most once per frame.
- Keep core algorithms testable without Flutter.
