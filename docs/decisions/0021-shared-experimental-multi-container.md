# 0021 Shared Experimental Multi-Container Contract Lives In dnd_kit

Date: 2026-06-23

## Status

Accepted

## Context

After `US-062`, the last sortable parity gap between the Flutter and Jaspr
adapters was the experimental multi-container helper surface:

- `SortableContainer`
- `SortableMultiContainer.moveDetailsFor(...)`

Those helpers already depended only on pure-Dart engine types
(`DndId`, `DndDragEndEvent`, `SortableMoveDetails`) but still lived in
`dnd_kit_flutter/src/sortable/sortable_container.dart`. Jaspr applications
could build cross-container movement by hand, yet they had no first-class
helper contract at parity with the Flutter example and adapter exports.

Before implementation, the repo needed one durable answer to these questions:

1. Should the helper contract be duplicated in Jaspr or hoisted into `dnd_kit`?
2. If hoisted, what compatibility guarantee does Flutter keep?
3. What stays adapter-local after the move?

## Decision

1. **Hoist the experimental multi-container helper contract into `dnd_kit`.**
   `SortableContainer` and `SortableMultiContainer` now belong to the shared
   engine because they are framework-neutral pure Dart.
2. **Keep Flutter source compatibility through re-export shims.**
   `dnd_kit_flutter` continues to expose the same symbols from its public barrel
   and keeps its old adapter-local file as a compatibility re-export.
3. **Expose the same shared helper contract from Jaspr.**
   `dnd_kit_jaspr` re-exports `package:dnd_kit/dnd_kit.dart`, so Jaspr apps can
   use the same experimental helper without adapter-local duplication.
4. **Keep scope plumbing adapter-local.**
   `SortableScope`, `SortableItem`, and each adapter's `SortableScopeData`
   remain in their framework packages. Only the pure-Dart multi-container move
   intent helper moves to core.
5. **Keep the feature experimental.**
   The move is about parity and boundary correctness, not API stabilization.

## Alternatives Considered

1. Duplicate the helper code in `dnd_kit_jaspr`.
   Rejected: it creates avoidable drift for a contract that already depends only
   on core types.
2. Leave the helper Flutter-only and tell Jaspr apps to hand-roll move intent.
   Rejected: it preserves the parity gap after the shared-runtime architecture
   was already established by ADR 0015 and ADR 0019.
3. Hoist `SortableScopeData` and adapter scope plumbing at the same time.
   Rejected for now: the helper contract is pure Dart, but the scope lookup and
   rendering integration still belong to adapter-local widget/component layers.

## Consequences

Positive:

- One pure-Dart source of truth now owns the experimental multi-container move
  intent helper for both adapters.
- Flutter keeps additive compatibility while Jaspr gains first-class parity.
- Core tests can own the helper semantics directly instead of proving them only
  through adapter-local suites.

Tradeoffs:

- `dnd_kit`'s public experimental surface grows.
- The feature remains intentionally unstable, so future stabilization still
  needs a separate decision.

## Follow-Up

- Add core tests for the multi-container helper semantics.
- Keep Flutter compatibility proof around the re-export shim.
- Add Jaspr package/browser proof that the shared helper works in a real drag
  flow.
