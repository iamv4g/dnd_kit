# 0015 Shared Drag Runtime Lives In dnd_kit_core

Date: 2026-06-15

## Status

Accepted

## Context

`dnd_kit_core` (0.1.0) owns the framework-neutral primitives (geometry, state,
events, collision, modifiers, registry, sensors, diagnostics), but the runtime
that wires them into a drag lifecycle lives in the Flutter adapter
(`DndController`) along with the measuring-cache contract
(`DndMeasuringRegistry`). Both are almost entirely pure Dart.

`SPEC_JASPR.md` adds a second adapter (`dnd_kit_jaspr`) and makes "one shared
runtime core, no second drag engine" a success criterion (§4.3, §10). ADR 0007
and ADR 0014 established the package layering and the multi-framework strategy;
this decision resolves *where the runtime belongs* under that strategy.

## Decision

`dnd_kit_core` owns the shared drag runtime and the measuring-cache contract:

- `DndRuntime` — pure-Dart drag state machine, collision orchestration, and
  modifier application, parameterized by an `onNotify` callback and an optional
  deferred-task scheduler. No Flutter or DOM types.
- `DndMeasuringRegistry` / `DndMeasurementStatus` — moved to core verbatim.

Adapters provide only framework wiring:

- `dnd_kit_flutter` keeps `DndController extends ChangeNotifier` as a thin
  wrapper over `DndRuntime` (forwarding `notifyListeners`) and retains the
  Flutter-only measurers `measureDndRect` / `DndMeasuredBox`. Moved types are
  re-exported so the Flutter public API does not change.
- `dnd_kit_jaspr` (future) builds on the same `DndRuntime`.

The runtime stays inside `dnd_kit_core` for now rather than a new pure-Dart
package (SPEC_JASPR Open Question 1 remains open; revisit if the core surface
grows too broad).

## Alternatives Considered

1. Duplicate the runtime in each adapter — rejected; violates the no-second-engine
   criterion.
2. New dedicated pure-Dart runtime package — deferred; not yet justified.
3. Flutter `DndController` subclasses a core base that is itself the notifier —
   rejected; `ChangeNotifier` is Flutter-specific, so composition keeps core
   framework-free.

## Consequences

Positive:

- One drag engine shared by Flutter and Jaspr; adapter code is limited to
  rendering, input, measuring, scrolling, accessibility.
- Shared business logic and contract tests target one runtime.
- No breaking change for existing `dnd_kit_flutter` / `dnd_kit` users.

Tradeoffs:

- `dnd_kit_core`'s public surface grows (now exposes runtime + measuring).
- Future `dnd_kit_core` releases must treat `DndRuntime` and the measuring
  contract as public API.

## Follow-Up

- Implemented under US-047: measuring registry, `DndRuntime`, sortable
  contract/strategy math, and auto-scroll edge/velocity math all moved to
  `dnd_kit_core` with the Flutter public API preserved via re-export.
- Remaining for Phase A→B: scaffold `dnd_kit_jaspr` on top of `DndRuntime`.
- Revisit the separate-package question if the core surface broadens further.
