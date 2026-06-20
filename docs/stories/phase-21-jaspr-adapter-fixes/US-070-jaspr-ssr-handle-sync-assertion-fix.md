# US-070 Jaspr SSR Handle-Sync Assertion Fix

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_jaspr` must pre-render cleanly under static/server rendering when a
`DndDraggable` contains a `DndDragHandle`. Registering a handle adjusts only
client-side interactivity (the draggable root's focusability and keyboard
wiring), so it must not schedule a deferred `setState` during server
pre-rendering, where there is no active build owner. The server markup and the
first client build must agree so hydration reuses the existing DOM instead of
replacing it.

## Relevant Product Docs

- `docs/product/package-architecture.md`
- `docs/ARCHITECTURE.md`
- `docs/decisions/0016-jaspr-adapter-scope-and-runtime-model.md`
- `docs/stories/phase-14-jaspr-foundation/US-051-jaspr-drag-handle.md`
- `docs/stories/phase-21-jaspr-adapter-fixes/US-068-jaspr-drag-overlay-controller-rebind-fix.md`

## Acceptance Criteria

- Server/static pre-rendering of a `DndDraggable` that wraps a `DndDragHandle`
  completes without throwing the framework assertion
  `owner._debugCurrentBuildTarget != null`.
- Client behavior is unchanged: on the web the handle-state sync still defers a
  rebuild via a microtask so the draggable root drops its own focus/keyboard
  wiring once a handle owns activation.
- The pre-rendered markup matches the first client build, so hydration reuses
  the draggable subtree rather than replacing it.
- A regression test exercises the server pre-render path so the assertion
  cannot return unnoticed.

## Design Notes

- Commands:
  `fvm dart test packages/dnd_kit_jaspr/test/src/widgets/draggable_ssr_test.dart`
  `fvm dart test packages/dnd_kit_jaspr`
  `fvm dart analyze packages/dnd_kit_jaspr`
- Queries:
  `scripts/bin/harness-cli query matrix`
  `rg -n "_scheduleHandleStateSync|registerHandle|kIsWeb" packages/dnd_kit_jaspr`
- API:
  `DndDraggable`
  `DndDragHandle`
- Domain rules:
  The fix stays adapter-local and does not change the shared runtime or the
  public draggable/handle API. `_scheduleHandleStateSync` now early-returns on
  `!kIsWeb`; the existing `_handleSyncScheduled`/`mounted` guards are unchanged.
- UI surfaces:
  Any Jaspr `DndDraggable` that uses a `DndDragHandle` under static/server
  rendering, such as the cross-column Kanban, reorderable feature cards, and
  nav pills in the `website` home page that first surfaced the assertion.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-070 --unit 1 --integration 0 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | `testServer` pre-renders a draggable with a handle and asserts a `200` response with no thrown assertion; full `dnd_kit_jaspr` suite stays green. |
| Integration | Not required; the regression is isolated to the server pre-render path with package-level proof. |
| E2E | Not required. |
| Platform | `fvm dart analyze packages/dnd_kit_jaspr` stays clean. |
| Release | `dnd_kit_jaspr` CHANGELOG records the fix and the package version is bumped to `0.3.1` for a later publish. |

## Harness Delta

No Harness process change. Closes the backlog candidate epic "Jaspr draggable
SSR handle-sync assertion (→ 0.3.1)" recorded earlier; the backlog row is marked
done pending `pub publish`.

## Evidence

- Surfaced 2026-06-20 by the `website` home page: every page load/reload logged
  `[SERVER] [ERROR] ... owner._debugCurrentBuildTarget != null` from
  `_DndDraggableState._scheduleHandleStateSync`, and the hero "drag a capability"
  area flickered as hydration replaced the island subtree.
- Root cause: `DndDragHandle` registration calls `_scheduleHandleStateSync`,
  which schedules a microtask `setState`. During server pre-render that
  microtask runs with no build owner, tripping the assertion; the server markup
  also stayed in the pre-registration state, diverging from the client.
- Fix: guard `_scheduleHandleStateSync` with `!kIsWeb` so the deferred rebuild
  is client-only. Server markup and the first client build now match.
- Regression proof added in
  `packages/dnd_kit_jaspr/test/src/widgets/draggable_ssr_test.dart` using
  `testServer` from `package:jaspr_test/server_test.dart`; confirmed to fail with
  the assertion when the guard is removed and pass with it in place.
- `fvm dart test packages/dnd_kit_jaspr` -> 38 passed.
- `fvm dart analyze packages/dnd_kit_jaspr` -> No issues found.
- `scripts/bin/harness-cli story verify US-070` -> pass.
