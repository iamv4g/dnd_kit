# Changelog

## 0.1.0-dev.2

- Fixed active drag geometry so overlays and collision detection stay aligned
  with the pointer when a scrollable ancestor moves during the drag.

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
