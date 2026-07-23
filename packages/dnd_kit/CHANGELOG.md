# Changelog

## 0.6.0

Fixes four defaults reported by a production integration; see
`docs/decisions/0024-drag-defaults-match-what-users-see.md`.

- **Breaking behavior:** the active draggable is no longer a collision
  candidate. `DndCollisionInput.droppableRects` excludes the active id, so
  `overId` can never equal `activeId` and drops near the source slot commit
  instead of silently resolving to no move. Custom detectors no longer need to
  filter the active item themselves.
- **Breaking behavior:** `beginDrag` marks all measurements dirty, so a drag
  started in a scrolled viewport measures targets at their current positions
  instead of reusing rects captured at registration.
- Adds `SortableStrategies.dropOnOver`, which commits the move at the drop-over
  target so the drop lands where the `isOver` highlight is. The geometric
  strategies keep resolving from the dragged rect's center and now document
  that they can disagree with the highlight.
- Adds `DndRuntime.initialActiveRect`, the active rectangle measured at drag
  start and fixed for the session, so drag previews survive a collapsed source
  slot.

Live sortable feedback, added in the same line; see
`docs/decisions/0025-sortable-live-preview-and-offsets.md`.

- Adds `SortableDragContext` and `SortableResolutionPhase`, so a sortable
  strategy runs both while a drag moves (preview) and when it ends (commit)
  through one code path. The preview a UI shows and the move that is finally
  reported are therefore the same computation.
- **Deprecated:** `SortableStrategyInput.event` and
  `SortableMultiMoveInput.event`. Both are now getters that return null during
  a preview; use `context` instead. They will be removed in a future release.
- Adds `SortablePreview`, which reports where the active item would land if
  released now. It resolves lazily and caches per move, so reading it from
  every item in a list costs one resolution.
- Adds `SortableOffsetResolver`, `SortableOffsetInput`, and the
  `SortableOffsets.verticalList` / `horizontalList` / `none` built-ins, which
  report how far each item a move displaces should shift. `none` is the
  default: the library reports geometry and the application decides whether to
  animate it.
- Adds `SortableMultiOffsetResolver`, `SortableMultiOffsetInput`, and the
  `SortableMultiOffsets.verticalLists` / `horizontalLists` / `none` built-ins
  for boards: a same-container move matches the single-list result, and a
  cross-container move closes the source column and opens the target column.
  See `docs/decisions/0026-cross-container-sortable-offsets.md`.


## 0.5.0

- Adds `DndCollisionInput.activeId`: the id of the draggable being moved is now
  passed to collision detectors, so a custom detector can scope candidates to
  the active item's kind (e.g. two nested sortable contexts sharing one
  controller that must ignore each other's droppables).


## 0.4.0

- Graduates multi-container from a helper-only contract into a supported shared
  engine feature for the common board/list case.
- `SortableMultiContainer` now owns the default collision detector and
  move-intent resolution policy, including empty-container drops and adaptive
  before/after insertion around an over-item target.
- Adds `SortableMultiMoveInput` and `SortableMultiMoveResolver` so adapters and
  advanced consumers can override the default policy without forking the whole
  feature.
- Adds the experimental multi-container helper contract to the shared engine:
  `SortableContainer` and `SortableMultiContainer` now live in
  `package:dnd_kit/dnd_kit.dart` so Flutter and Jaspr apps compute the same
  cross-container move intent over one pure-Dart source of truth.

## 0.3.2

- Updates the pub.dev homepage metadata to the hosted project website while
  keeping repository and issue tracker links on GitHub.
- Refreshes the package links for the repository transfer to
  `iamv4g/dnd_kit`.

## 0.3.1

- Adds `DndAnnouncements` to the shared engine as a framework-neutral
  accessibility contract for drag start/over/end/cancel announcements.
- Flutter and Jaspr adapters now reuse the shared contract from `dnd_kit`
  instead of maintaining duplicate pure-Dart announcement builders.

## 0.3.0

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
- Adds additive axis-aware shared auto-scroll math via `DndScrollAxis` and an
  `axis` parameter on `dndAutoScrollVelocity(...)`. Vertical behavior remains the
  default; both the Flutter and Jaspr adapters now execute against this contract.

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
