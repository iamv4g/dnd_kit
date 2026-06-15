# Validation

## Proof Strategy

The extraction is behavior-preserving, so the primary proof is that the existing
Flutter `DndController` test suite passes unchanged against the re-wrapped
controller, plus new pure-Dart core tests proving the runtime and measuring
registry behave the same without Flutter.

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | Core `DndRuntime`: idle start, lifecycle notify count, pending/active cancel, modifier application + collision, dirty measurement refresh, stable active-rect origin during source remeasure (ported from `controller_test.dart`, driven by an `onNotify` counter). Core `DndMeasuringRegistry`: status transitions (missing/clean/dirty/removed), refreshDirty, remove. Core `SortableStrategies` vertical/horizontal/grid (ported from `sortable_strategy_test.dart`). Core `dndAutoScrollVelocity`: neutral band, leading/trailing edges, clamps, out-of-bounds. |
| Integration | Flutter `controller_test.dart`, `auto_scroll_test.dart`, `sortable_*_test.dart` pass unchanged (controller delegates to `DndRuntime`; sortable/auto-scroll widgets use re-exported core math). |
| E2E | N/A this story. |
| Platform | `dart test` (core) + `flutter test` (flutter) both green. |
| Performance | N/A (no hot-path change; same algorithms). |
| Logs/Audit | Duplicate-id diagnostics warning test passes (ported to core runtime). |

## Fixtures

- Deterministic `DndRect` / `DndPoint` literals reused from `controller_test.dart`.
- An `onNotify` counter closure to assert notification parity in core tests.
- A capturing `DndCollisionDetector` to assert collision input (active-rect
  origin stability case).

## Commands

```text
fvm dart test packages/dnd_kit_core
fvm flutter test packages/dnd_kit_flutter
melos run analyze
melos run test
```

## Acceptance Evidence

Verified 2026-06-15 (fvm Dart 3.10.4 / Flutter 3.38.5):

- `fvm dart test packages/dnd_kit_core` → **108 passed**: 10 `DndRuntime`
  contract tests + 2 `DndMeasuringRegistry` tests + 18 `SortableStrategies`
  tests (vertical/horizontal/grid, ported from the Flutter adapter) + 6
  `dndAutoScrollVelocity` tests, on top of the existing core suite.
- `fvm flutter test packages/dnd_kit_flutter` → **100 passed**;
  `controller_test.dart`, `auto_scroll_test.dart`, and the `sortable_*` widget
  tests are unchanged and pass against the re-wrapped controller and the
  re-exported core math. (Count dropped from 118 because the 18 sortable-strategy
  unit tests moved into the core contract suite.)
- `fvm dart analyze` on `dnd_kit_core`, `dnd_kit_flutter`, and `dnd_kit` →
  **No issues found** in all three.
- Public surfaces unchanged: `DndController` keeps 11 getters (`registry`,
  `measuring`, `collisionDetector`, `modifiers`, `state`, `overId`,
  `activeRect`, `isIdle`, `isDragging`, `activeSession`, `activeId`) + 6 methods
  (`beginDrag`, `startDrag`, `moveDrag`, `endDrag`, `cancelDrag`, `reset`) +
  identical constructor; `SortableMoveDetails`, `SortableStrategies`,
  `SortableStrategyInput`, and `DndAutoScrollOptions` remain importable from
  `package:dnd_kit_flutter/dnd_kit_flutter.dart` via re-export.
