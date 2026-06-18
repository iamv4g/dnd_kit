# Overview

## Current Behavior

Auto-scroll is implemented today, but only for the vertical axis:

- `packages/dnd_kit/lib/src/auto_scroll.dart` exposes
  `dndAutoScrollVelocity(...)`, which computes velocity from `localPointer.y`
  and `viewportSize.height`.
- `packages/dnd_kit_flutter/lib/src/widgets/auto_scroll.dart` measures a
  `Scrollable` viewport and drives `ScrollPosition.jumpTo(...)` vertically.
  `US-024` explicitly deferred horizontal and nested-scroll policies.
- `packages/dnd_kit_jaspr/lib/src/widgets/auto_scroll.dart` measures a DOM
  viewport and drives `scrollTop` vertically. Its docs and source both state
  that horizontal auto-scroll is not yet supported, and `US-056` deferred it
  until the shared core owned a DOM-free horizontal axis.
- `examples/kanban_board/lib/horizontal_board_auto_scroll.dart` already
  contains app-owned horizontal board auto-scroll in Flutter, with local
  threshold/velocity math that is intentionally outside the shared library.

## Target Behavior

This story does not ship runtime changes yet. It produces a durable answer to
three questions:

1. Can horizontal auto-scroll be supported by extending shared core math rather
   than forking adapter logic?
2. What additive API shape should own that behavior?
3. How should implementation be split across core, Flutter, and Jaspr?

The answer is yes, with a deliberately additive shape:

- `dnd_kit` keeps one shared auto-scroll function and gains an axis selector
  rather than a second velocity curve API;
- Flutter and Jaspr add matching `axis` configuration to their execution
  surfaces, defaulting to vertical so current behavior stays source-compatible;
- first implementation scope remains one-axis-per-instance container
  auto-scroll only.

Follow-up implementation should add axis-aware shared math in `dnd_kit`,
preserve current vertical behavior, and let both adapters execute horizontal
scrolling over the same core contract.

## Affected Users

- Library maintainers.
- Flutter adopters building wide boards, canvases, or dashboard surfaces.
- Jaspr adopters building browser drag/drop layouts wider than one viewport.

## Affected Product Docs

- `docs/product/release-roadmap.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/stories/phase-5-overlay-visual-state-auto-scroll/US-024-flutter-auto-scroll-foundation.md`
- `docs/stories/phase-15-jaspr-hardening/US-056-jaspr-auto-scroll-execution.md`

## Non-Goals

- Shipping horizontal auto-scroll in this story.
- Re-tuning the existing vertical threshold or velocity curve.
- Supporting simultaneous two-axis auto-scroll in one container.
- Reworking Kanban collision behavior or sortable semantics.
