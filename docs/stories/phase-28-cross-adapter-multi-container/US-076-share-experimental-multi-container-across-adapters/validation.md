# Validation

## Proof Strategy

The story is done only when the experimental multi-container helper semantics
live in `packages/dnd_kit`, both adapters still expose the contract cleanly,
and parity proof shows Flutter and Jaspr computing the same move intent from the
same shared helper.

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | `packages/dnd_kit` tests cover `SortableContainer` immutability/equality plus `SortableMultiContainer.moveDetailsFor` null cases, same-container no-op, cross-container item target, container-end target, and invalid-id handling. |
| Integration | Flutter package tests confirm compatibility re-exports keep existing imports working; Jaspr package tests confirm the shared helper is reachable from `package:dnd_kit_jaspr/dnd_kit_jaspr.dart` and produces the same `SortableMoveDetails` intent for equivalent container snapshots. |
| E2E | Flutter example proof covers dragging between containers in `examples/multi_container_sortable`; Jaspr browser proof covers one multi-container drag flow in a runnable example or browser test. |
| Platform | `fvm dart analyze packages/dnd_kit packages/dnd_kit_flutter packages/dnd_kit_jaspr`, `fvm dart test packages/dnd_kit`, `fvm flutter test packages/dnd_kit_flutter`, `fvm dart test packages/dnd_kit_jaspr`, and the selected example/browser commands all pass. |
| Performance | Not required unless the hoist changes helper complexity or example/browser proof reveals a regression. |
| Logs/Audit | Harness intake, story, and trace records capture the selected direction and any parity blockers. |

## Fixtures

- Existing Flutter multi-container demo state with more than one container.
- A Jaspr multi-container fixture or example state that mirrors the Flutter item
  layout closely enough to compare move intent.
- Deterministic `DndId` values for cross-container drag targets.

## Commands

```text
fvm dart analyze packages/dnd_kit packages/dnd_kit_flutter packages/dnd_kit_jaspr
fvm dart test packages/dnd_kit
fvm flutter test packages/dnd_kit_flutter
fvm dart test packages/dnd_kit_jaspr
cd examples/multi_container_sortable && fvm flutter test test/widget_test.dart
cd packages/dnd_kit_jaspr && fvm dart test -p chrome <targeted multi-container browser test>
```

## Acceptance Evidence

- Implemented 2026-06-23 by moving `SortableContainer` and
  `SortableMultiContainer` into `packages/dnd_kit/lib/src/sortable_container.dart`,
  exporting them from `package:dnd_kit/dnd_kit.dart`, and turning the old
  Flutter adapter file into a compatibility re-export shim.
- `fvm dart analyze packages/dnd_kit packages/dnd_kit_flutter packages/dnd_kit_jaspr`
  returned `No issues found!`.
- `fvm dart test packages/dnd_kit` passed with 130 tests, including the new
  core-owned multi-container helper coverage.
- `fvm flutter test packages/dnd_kit_flutter` passed with 103 tests, including
  Flutter barrel/shim compatibility coverage.
- `fvm dart test packages/dnd_kit_jaspr` passed with 35 tests, including Jaspr
  barrel reachability coverage for the shared helper.
- `cd packages/dnd_kit_jaspr && fvm dart test -p chrome test/multi_container_browser_test.dart`
  passed with 1 browser test proving a real Jaspr drag flow can feed the shared
  `SortableMultiContainer.moveDetailsFor(...)` contract.
- `cd examples/multi_container_sortable && fvm flutter test test/widget_test.dart`
  passed with 3 widget tests covering the Flutter example board's render,
  cross-column move, and same-column reorder flows.
- After `0.3.2` had already been published, the local family metadata for this
  post-publish feature line was advanced to `0.4.0` across
  `packages/dnd_kit/pubspec.yaml`, `packages/dnd_kit_flutter/pubspec.yaml`, and
  `packages/dnd_kit_jaspr/pubspec.yaml`, with adapter constraints updated to
  `dnd_kit: ^0.4.0`.
