# 0020 Axis-Aware Auto-Scroll Stays One Shared Core Contract

Date: 2026-06-18

## Status

Accepted

## Context

`dnd_kit` already owns the shared auto-scroll threshold and velocity curve, but
the current contract is vertical-only:

- `packages/dnd_kit/lib/src/auto_scroll.dart` computes velocity from
  `localPointer.y` and `viewportSize.height`.
- `dnd_kit_flutter` and `dnd_kit_jaspr` both delegate to that function and only
  execute platform scrolling.
- `examples/kanban_board/lib/horizontal_board_auto_scroll.dart` already carries
  app-owned horizontal Flutter auto-scroll logic, which duplicates threshold and
  velocity math outside the shared core.

After `US-062`, horizontal auto-scroll is the next parity gap between the two
adapters. Before implementation, the repo needed one durable answer to these
questions:

1. Should horizontal support stay shared or adapter-local?
2. If shared, should core grow one axis-aware contract or two sibling helpers?
3. What should remain out of scope for the first implementation slice?

## Decision

1. **Keep one shared core auto-scroll function.** Horizontal auto-scroll stays
   in `dnd_kit` alongside the existing vertical curve; neither adapter may fork
   edge-threshold or velocity math.
2. **Make the shared contract axis-aware additively.** The preferred direction
   is a new enum such as `DndScrollAxis { vertical, horizontal }` plus an
   optional `axis` parameter on `dndAutoScrollVelocity(...)`, defaulting to
   `vertical` so current call sites remain source-compatible.
3. **Keep current input shapes.** The function should continue to accept
   `DndPoint localPointer` and `DndSize viewportSize` rather than replacing the
   contract with a scalar-only input object. The function can select primary and
   cross-axis coordinates internally.
4. **Adapters mirror the axis selection, not the math.**
   - `dnd_kit_flutter` adds an `axis` option on its auto-scroll surfaces and
     maps horizontal execution to the existing `ScrollPosition` extents.
   - `dnd_kit_jaspr` adds an `axis` option on its auto-scroll component and
     maps horizontal execution to `scrollLeft`, `scrollWidth`, and
     `clientWidth`, preserving SSR safety and the existing measurement refresh
     path.
5. **First implementation scope is single-axis container auto-scroll only.**
   The initial library slice deliberately defers:
   - document-viewport horizontal auto-scroll;
   - simultaneous two-axis auto-scroll in one surface;
   - nested-scrollable policy.

## Alternatives Considered

1. Keep the library vertical-only and leave horizontal behavior app-owned.
   Rejected: it preserves the current parity gap and leaves shared math
   duplicated in adopter code.
2. Add a second horizontal core helper instead of an axis parameter.
   Rejected: it duplicates public contract surface for the same curve.
3. Replace the current API with a scalar-only input object.
   Rejected for now: more churn for both adapters without a clear benefit over
   the existing `DndPoint`/`DndSize` inputs.
4. Let each adapter implement horizontal behavior independently.
   Rejected: violates the shared-runtime reuse posture already established by
   ADR 0015 and ADR 0016.
5. Support simultaneous bi-directional auto-scroll in the first slice.
   Rejected: scope expansion before single-axis parity is proven.

## Consequences

Positive:

- One shared velocity curve remains the source of truth for both adapters.
- Current vertical behavior stays source-compatible through a defaulted axis.
- The Kanban board's horizontal reference can migrate toward library APIs
  without inventing new product semantics.

Tradeoffs:

- The core public API grows by at least one new enum/parameter.
- Document viewport horizontal support and nested-scroll behavior remain open
  follow-up questions rather than being solved in the first pass.

## Follow-Up

- Implement the shared `axis` support in `dnd_kit` first.
- Add Flutter auto-scroll axis adoption next.
- Add Jaspr auto-scroll axis adoption after the core contract lands.
- Keep any broader scroll-policy decisions out of those first implementation
  slices unless a later story selects them explicitly.
