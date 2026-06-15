# Overview

## Current Behavior

The drag runtime lives entirely inside the Flutter adapter:

- `dnd_kit_flutter/lib/src/scope/controller.dart` owns the drag state machine,
  collision orchestration, modifier application, and measurement-cache
  interactions. It is coupled to Flutter only through `ChangeNotifier`,
  `SchedulerBinding.instance.addPostFrameCallback`, and the measuring registry.
- `dnd_kit_flutter/lib/src/measuring/measuring.dart` defines
  `DndMeasuringRegistry` and `DndMeasurementStatus`, which are already pure Dart
  (only `dart:collection`, `dnd_kit_core`, and `meta`), plus the genuinely
  Flutter-specific `measureDndRect(BuildContext)` and `DndMeasuredBox`.

`dnd_kit_core` (published 0.1.0) owns geometry, state, events, collision,
modifier, registry, sensor, and diagnostics, but not the runtime that ties them
together. A second adapter (`dnd_kit_jaspr`, see `SPEC_JASPR.md`) cannot reuse
the runtime without duplicating it.

## Target Behavior

`dnd_kit_core` owns the framework-neutral runtime and the measuring-cache
contract:

- A pure-Dart `DndRuntime` owns the state machine, collision orchestration, and
  modifier application, parameterized by an `onNotify` callback and an optional
  deferred-task scheduler. It contains no Flutter or DOM types.
- `DndMeasuringRegistry` / `DndMeasurementStatus` move to core unchanged.

`dnd_kit_flutter` keeps an identical public API: `DndController extends
ChangeNotifier` wraps `DndRuntime` and forwards `notifyListeners`; the measuring
library re-exports the core registry and retains `measureDndRect` /
`DndMeasuredBox`. No breaking change for existing Flutter users.

The shared runtime becomes the single drag engine both Flutter and the future
Jaspr adapter build on (SPEC_JASPR §4.3, §9 Phase A).

## Affected Users

- Library maintainers (extraction enables the Jaspr adapter without a second
  engine).
- Existing `dnd_kit_flutter` / `dnd_kit` consumers (must see no behavior or API
  change).

## Affected Product Docs

- `docs/ARCHITECTURE.md`
- `docs/product/package-architecture.md`
- `SPEC_JASPR.md` (§3.1, §4.3, §4.4, §9 Phase A)

## Non-Goals

- Implementing any Jaspr code in this story.
- Extracting auto-scroll math (deferred to a later Phase A slice once a DOM-free
  shape is proven).
- Changing drag/drop/sortable semantics.
- Changing the published `dnd_kit_core` public types' existing meaning (this is
  additive to core).
