# Story Backlog

This backlog will be populated after a user provides a project spec or selects a
specific initiative.

Do not create every possible story packet up front. Create story packets when
the work is selected or when a product decision needs a durable place to land.

## Candidate Epics

| Epic | Description | Status |
| --- | --- | --- |
| Jaspr multi-container sortable | Bring `SortableContainer` / `SortableMultiContainer` to `dnd_kit_jaspr` for cross-container sorting parity with Flutter. These helpers are framework-neutral pure Dart but currently live only in `dnd_kit_flutter`; preferred path is hoisting them into the `dnd_kit` engine (engine + both adapters republish), per ADR 0019's remaining-gap note. Deferred from US-062. | unsliced |
| Jaspr draggable SSR handle-sync assertion (→ 0.3.1) | During static/SSR pre-render, `_DndDraggableState._scheduleHandleStateSync` (`packages/dnd_kit_jaspr/lib/src/widgets/draggable.dart` ~523) schedules a microtask `setState`, tripping the framework assertion `owner._debugCurrentBuildTarget != null`. Pre-rendered output is still complete and the client is unaffected (debug-only assert), but it is noisy and contradicts the "SSR-safe" guarantee. Fix: guard the handle-state sync to client-only (`if (!kIsWeb) return;` in `_scheduleHandleStateSync`), add a regression test + CHANGELOG, and **publish `dnd_kit_jaspr` 0.3.1**. Surfaced by `website/` (drag handles under Jaspr static mode). Fixed: `_scheduleHandleStateSync` now guards on `!kIsWeb`; regression test `draggable_ssr_test.dart` (server pre-render) + CHANGELOG + version bump landed. **Pending `pub publish` of `dnd_kit_jaspr` 0.3.1.** | done (unpublished) |
