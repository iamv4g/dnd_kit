# Changelog

## 0.2.0-dev.0

- Starts the shared-runtime development line for `dnd_kit_core`.
- Adds `DndRuntime` as the framework-neutral drag engine shared by the Flutter
  and Jaspr adapters.
- Moves `DndMeasuringRegistry` and its measurement-status contract into core so
  adapters can share the same measuring cache model.
- Moves `DndPointerSensor` to core on top of `DndRuntime`, preserving the
  pointer-activation state machine across adapters.
- Brings the shared sortable move/strategy math and auto-scroll edge/velocity
  math into core for reuse outside Flutter.

## 0.1.0

- First public release of the pure Dart engine: stable
  identifiers, geometry, drag state and events, collision detectors, modifiers,
  sensor and registry contracts, and diagnostics.
- `DndRegistry.registerDraggable`/`registerDroppable` and their unregister
  counterparts accept an optional `owner`. Owner-aware registration is
  last-wins and lets a new owner take over an id without tripping duplicate
  detection — required so draggables in a lazy `ListView.builder` survive the
  list rebuilding a keyed entry (new element mounts before the old is disposed).
  A departing owner can no longer remove a registration that a newer owner
  already took over.
- Owner-aware entries now also keep per-id owner claims and emit a deferred
  duplicate warning when multiple owners still claim the same id after
  reconciliation. This restores actionable duplicate diagnostics for
  owner-registered entries without reintroducing the lazy-list remount crash.
- Calls without `owner` keep the strict duplicate-id debug assertion and
  immediate warning behavior for direct `DndRegistry` usage.

## 0.1.0-dev.1

- Added a package-local `example/example.md` so pub.dev can render a compact
  illustrative pure Dart example for the package.

## 0.1.0-dev.0

- Initial development release of the pure Dart `dnd_kit_core` package.
- Includes stable ID, geometry, drag state, drag event, collision detector,
  modifier, sensor, registry, and diagnostics primitives.
- Keeps Flutter, `dart:ui`, widget, render object, gesture, overlay, and app
  state-management dependencies out of the core package.
