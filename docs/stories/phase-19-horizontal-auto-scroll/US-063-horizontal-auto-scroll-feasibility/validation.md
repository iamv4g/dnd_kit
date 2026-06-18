# Validation

## Proof Strategy

This is a discovery/design story. Proof comes from a code audit that captures
the current vertical-only contract, an implementation recommendation grounded in
that code, and a follow-up slice plan that preserves existing validation
requirements.

## Test Plan

| Layer | Cases |
| --- | --- |
| Unit | N/A for this story. Record the future core cases required if the feature proceeds: horizontal leading/trailing edges, extents clamping, and out-of-bounds neutral behavior. |
| Integration | N/A for this story. Record the future adapter cases required if the feature proceeds: Flutter widget auto-scroll on a horizontal `Scrollable`; Jaspr browser auto-scroll on `scrollLeft` plus post-scroll collision refresh. |
| E2E | N/A for this story. |
| Platform | Audit confirms all current library auto-scroll paths are vertical-only and the Kanban example's horizontal board behavior is app-owned reference code rather than a shared package API. |
| Performance | Future implementation must keep the current O(1) per-frame math shape and avoid adding new per-pointer burst work. |
| Logs/Audit | N/A. |

## Fixtures

- `packages/dnd_kit/lib/src/auto_scroll.dart`
- `packages/dnd_kit_flutter/lib/src/widgets/auto_scroll.dart`
- `packages/dnd_kit_jaspr/lib/src/widgets/auto_scroll.dart`
- `examples/kanban_board/lib/horizontal_board_auto_scroll.dart`
- Existing auto-scroll tests in Flutter and Jaspr.

## Commands

```text
scripts/bin/harness-cli query matrix --numeric
rg -n "dndAutoScrollVelocity|DndAutoScrollOptions|scrollTop|scrollLeft|maxScrollExtent|clientWidth|clientHeight" packages/dnd_kit packages/dnd_kit_flutter packages/dnd_kit_jaspr examples/kanban_board
```

## Acceptance Evidence

- Created 2026-06-18 as the selected follow-up after `US-062`, before any
  horizontal auto-scroll implementation work.
- Discovery completed 2026-06-18 from the current codebase:
  - `packages/dnd_kit/lib/src/auto_scroll.dart` is vertical-only in the shared
    math (`localPointer.y`, `viewportSize.height`) but otherwise already has the
    right adapter-independent inputs and extents for an additive axis selector.
  - `packages/dnd_kit_flutter/lib/src/widgets/auto_scroll.dart` delegates all
    edge/velocity math to the shared function, so horizontal support can stay a
    thin execution-layer change once the core contract gains an axis.
  - `packages/dnd_kit_jaspr/lib/src/widgets/auto_scroll.dart` has the same
    reuse posture and can map horizontal execution to `scrollLeft`,
    `scrollWidth`, and `clientWidth` without changing the measurement refresh
    model or SSR guardrails.
  - `examples/kanban_board/lib/horizontal_board_auto_scroll.dart` proves a
    real horizontal Flutter use case exists today, but it also shows that the
    current app-owned implementation duplicates threshold and velocity math that
    belongs in the shared core.
- Chosen direction:
  - the feature is feasible without adapter-specific math forks;
  - the preferred additive API shape is one shared `dndAutoScrollVelocity(...)`
    plus an axis enum/defaulted axis parameter;
  - the recommended follow-up slices are core math/API first, then Flutter
    execution adoption, then Jaspr execution adoption.
- Durable decision:
  - ADR 0020 records the accepted direction for the shared auto-scroll
    contract.
