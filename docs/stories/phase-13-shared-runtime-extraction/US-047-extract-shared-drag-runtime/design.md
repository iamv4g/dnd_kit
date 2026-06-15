# Design

## Domain Model

No new domain entities. Existing value objects (`DndPoint`, `DndRect`,
`DndTransform`, `DndState`, `DndDragSession`, events) stay in core unchanged.

New core runtime building blocks:

- `DndMeasuringRegistry` / `DndMeasurementStatus` — moved verbatim from the
  Flutter adapter (already pure Dart). File: `dnd_kit_core/lib/src/measuring.dart`.
- `DndRuntime` — pure-Dart owner of the drag lifecycle. File:
  `dnd_kit_core/lib/src/runtime.dart`.
- Sortable contract + strategy math (`SortableMoveDetails`,
  `SortableMoveCallback`, `SortableStrategy`, `SortableStrategyInput`,
  `SortableStrategies` and private helpers) — moved verbatim (already pure
  Dart). File: `dnd_kit_core/lib/src/sortable.dart`.
- `DndAutoScrollOptions` + `dndAutoScrollVelocity(...)` — the auto-scroll
  edge-threshold and velocity curve, extracted from the Flutter
  `DndAutoScrollController._velocityFor`. File:
  `dnd_kit_core/lib/src/auto_scroll.dart`. The function takes a viewport-local
  pointer, viewport size, and scroll extents and returns logical pixels to
  scroll this frame; the Flutter controller keeps the `Ticker`, `RenderBox`
  measuring, and `ScrollPosition.jumpTo` execution and delegates the math.

## Application Flow

`DndRuntime` reproduces today's `DndController` logic without Flutter:

```text
DndRuntime({
  DndState initialState = const DndIdle(),
  DndCollisionDetector? collisionDetector,
  Iterable<DndModifier> modifiers = const [],
  DndDiagnosticsConfig diagnosticsConfig = const DndDiagnosticsConfig(),
  void Function()? onNotify,                 // replaces notifyListeners()
  void Function(void Function())? scheduleDeferredTask, // registry deferral
})
```

- State machine: `beginDrag`, `startDrag`, `moveDrag`, `endDrag`, `cancelDrag`,
  `reset` (moved verbatim).
- Collision orchestration: `_updateCollision`, `_refreshMeasurements`,
  `_modifiedSession`, `_setOverId` (moved verbatim).
- Owns `registry` (`DndRegistry`), `measuring` (`DndMeasuringRegistry`),
  `collisionDetector`, `modifiers`, and the `state` / `overId` / `activeRect`
  getters.
- Every place that called `notifyListeners()` calls `onNotify?.call()`.
- `scheduleDeferredTask` is forwarded to the `DndRegistry`; when null the
  registry runs deferred tasks synchronously (its existing default).

## Interface Contract

Flutter `DndController` keeps its exact public signature:

```dart
class DndController extends ChangeNotifier {
  DndController({ initialState, collisionDetector, modifiers, diagnosticsConfig });
  // delegates to a private DndRuntime created with:
  //   onNotify: notifyListeners,
  //   scheduleDeferredTask: (t) => SchedulerBinding.instance.addPostFrameCallback((_) => t()),
}
```

All getters (`state`, `overId`, `activeRect`, `isIdle`, `isDragging`,
`activeSession`, `activeId`, `registry`, `measuring`, `collisionDetector`,
`modifiers`) and methods forward to the runtime. No symbol is removed from
`dnd_kit_flutter.dart`.

Re-export strategy (non-breaking):

- `dnd_kit_core/lib/dnd_kit_core.dart` adds
  `export 'src/measuring.dart';` and `export 'src/runtime.dart';`.
- `dnd_kit_flutter/lib/src/measuring/measuring.dart` becomes:
  `export 'package:dnd_kit_core/dnd_kit_core.dart' show DndMeasuringRegistry, DndMeasurementStatus;`
  plus the Flutter-only `measureDndRect` and `DndMeasuredBox`.
- The Flutter barrel's existing
  `export 'src/measuring/measuring.dart' hide DndMeasuredBox;` keeps working,
  so `DndMeasuringRegistry` stays importable from `dnd_kit_flutter`.
- Flutter `src/sortable/sortable_details.dart` and `sortable_strategy.dart`
  become `export ... show ...` re-exports of the moved core symbols; sibling
  sortable widgets and the barrel keep resolving them unchanged.
- Flutter `src/widgets/auto_scroll.dart` re-exports `DndAutoScrollOptions`
  (`export ... show DndAutoScrollOptions;`) and delegates `_velocityFor` to
  `dndAutoScrollVelocity`.

## Data Model

No tables, migrations, or persisted data.

## UI / Platform Impact

None in this story. Sets up the future Jaspr adapter to build on `DndRuntime`
(SPEC_JASPR §4.3). Flutter behavior and rendering unchanged.

## Observability

Diagnostics (`DndDiagnosticsConfig`, duplicate-id warnings) move with the
runtime and keep firing identically; covered by the existing controller test.

## Alternatives Considered

1. Keep the runtime in Flutter and duplicate it in Jaspr — rejected: violates
   SPEC_JASPR Success Criteria (no second drag engine).
2. Make Flutter `DndController` subclass a core `DndRuntime` that itself is the
   notifier — rejected: `ChangeNotifier` is a Flutter type; the runtime must
   stay Flutter-free, so composition (controller wraps runtime) is cleaner than
   inheritance.
3. Introduce a new pure-Dart package instead of growing `dnd_kit_core` —
   deferred (SPEC_JASPR Open Question 1); not needed yet.
