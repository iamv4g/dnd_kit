# Changelog

## 0.3.0-dev.0

- **Package identity change.** `dnd_kit` is now the pure Dart core engine of the
  toolkit — the package formerly published as `dnd_kit_core`. The API surface is
  unchanged from `dnd_kit_core 0.2.0-dev.0`; only the package name and import
  path changed (`package:dnd_kit_core/dnd_kit_core.dart` →
  `package:dnd_kit/dnd_kit.dart`).
- The earlier `dnd_kit` `0.1.x` releases were the Flutter umbrella that
  re-exported `dnd_kit_flutter`. That umbrella role is discontinued: Flutter apps
  now depend on `dnd_kit_flutter` and import
  `package:dnd_kit_flutter/dnd_kit_flutter.dart`; Jaspr apps depend on
  `dnd_kit_jaspr`. Both adapters build on this engine.
- `dnd_kit_core` is discontinued and superseded by this package. See ADR 0017
  for the rationale and the brand-as-core decision that supersedes ADR 0014.

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
