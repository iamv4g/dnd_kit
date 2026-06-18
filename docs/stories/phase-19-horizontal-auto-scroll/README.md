# Phase 19 — Cross-Adapter Horizontal Auto-Scroll

This phase explores the next parity gap after `US-062`: the shared auto-scroll
math and both adapter surfaces are still vertical-only, even though the Flutter
Kanban example already contains app-owned horizontal board auto-scroll logic.

## Principle

Horizontal auto-scroll must follow the same reuse posture as the existing
vertical path:

- axis math belongs in `dnd_kit`;
- Flutter and Jaspr only execute scrolling on their own platforms;
- no adapter forks the edge-threshold or velocity curve;
- Jaspr stays SSR-safe.

The first selected story is discovery/design rather than implementation so the
repo can answer whether the feature is feasible, how the shared API should
change, and how to split the eventual implementation safely.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-063** | Feasibility and design for horizontal auto-scroll across `dnd_kit`, `dnd_kit_flutter`, and `dnd_kit_jaspr` | ADR 0020 |

## Follow-Up

If `US-063` concludes the feature is feasible, subsequent implementation work
should likely split along package boundaries:

- shared core axis-aware math and API;
- Flutter execution layer adoption;
- Jaspr execution layer adoption.

The story closes with those slices recommended and with these explicit deferrals:

- document-viewport horizontal auto-scroll;
- simultaneous bi-directional auto-scroll in one surface;
- nested-scroll policy.

Story ids for those follow-ups are intentionally not reserved until the design
work closes.

## Validation Ladder

- Discovery proof: current-code audit confirms where auto-scroll is vertical
  only, where app-owned horizontal logic already exists, and what the shared
  API would need to own.
- Design proof: the story packet records the recommended API shape, scope
  boundaries, and follow-up slices without weakening existing validation.
- Implementation proof remains a later phase concern and will add core, widget,
  and browser tests once the design is selected.
