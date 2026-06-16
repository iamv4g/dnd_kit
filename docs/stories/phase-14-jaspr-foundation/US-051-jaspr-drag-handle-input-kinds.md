# US-051 Jaspr DndDragHandle And Input Activation Kinds

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_jaspr` must expose a first `DndDragHandle` component and differentiate
mouse, touch, and keyboard activation in `DndDraggable` so the Jaspr adapter
keeps the same family mental model as Flutter while staying browser-native.

## Relevant Product Docs

- `docs/product/api-principles.md`
- `docs/ARCHITECTURE.md`
- `docs/decisions/0016-jaspr-adapter-scope-and-runtime-model.md`
- `SPEC_JASPR.md`

## Acceptance Criteria

- `dnd_kit_jaspr` exports `DndDragHandle` as the explicit handle surface for
  `DndDraggable`.
- When a draggable contains one or more handles, pointer drags start only from
  a handle; dragging from the body is ignored.
- Default pointer activation differentiates browser input kinds: mouse starts
  immediately, touch/pen wait for a hold unless an explicit activation
  constraint is provided.
- `DndDraggable` supports keyboard pickup, movement, drop, and cancel flows,
  and reports `DndInputKind.keyboard` through the shared runtime callbacks.
- Jaspr tests prove handle gating, touch-vs-mouse activation behavior, and
  keyboard drag flows. Broad example/browser proof remains deferred to US-053.

## Design Notes

- Commands:
  `fvm dart test packages/dnd_kit_jaspr`
  `cd packages/dnd_kit_jaspr && fvm dart test -p chrome test/draggable_browser_test.dart`
  `cd packages/dnd_kit_jaspr && fvm dart analyze`
- Queries:
  `scripts/bin/harness-cli query matrix`
- API:
  `DndDragHandle`
  `DndDraggable.keyboardDragStep`
- Domain rules:
  The adapter still reports intent only; applications continue owning data.
  Keyboard movement updates the shared `DndRuntime` instead of creating a
  Jaspr-only drag state machine.
- UI surfaces:
  Jaspr component tree under `DndScope`; focusable browser drag handles.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id <id> --unit 1 --integration 1 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | Shared runtime keyboard/pointer state continues to flow through `DndRuntime` and existing pure-Dart core tests. |
| Integration | Jaspr tests prove handle-gated pointer activation and keyboard drag callbacks/state. |
| E2E | Deferred to US-053 example/browser scenario proof. |
| Platform | `dart analyze` is clean for `packages/dnd_kit_jaspr`, and focused browser tests pass in Chrome. |
| Release | Public exports, README, and changelog mention the new surface. |

## Harness Delta

No Harness process change expected; this story extends the Phase 14 Jaspr
adapter surface and story trail only.

## Evidence

- Verified 2026-06-16.
- `fvm dart test packages/dnd_kit_jaspr` -> 11 passed.
- `cd packages/dnd_kit_jaspr && fvm dart test -p chrome test/draggable_browser_test.dart` -> 3 passed
  covering handle-only pointer activation, touch hold-vs-mouse immediate behavior,
  and keyboard pickup/move/drop.
- `cd packages/dnd_kit_jaspr && fvm dart analyze` -> No issues found.
- Public package surface updated in `packages/dnd_kit_jaspr/lib/dnd_kit_jaspr.dart`,
  `README.md`, and `CHANGELOG.md`.
