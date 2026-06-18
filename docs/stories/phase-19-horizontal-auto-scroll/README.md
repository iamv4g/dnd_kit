# Phase 19 — Cross-Adapter Horizontal Auto-Scroll

This phase explores and closes the next parity gap after `US-062`: the shared
auto-scroll math is now axis-aware, the Flutter adapter now supports horizontal
container auto-scroll, and the remaining adapter gap is Jaspr execution-layer
adoption.

## Principle

Horizontal auto-scroll must follow the same reuse posture as the existing
vertical path:

- axis math belongs in `dnd_kit`;
- Flutter and Jaspr only execute scrolling on their own platforms;
- no adapter forks the edge-threshold or velocity curve;
- Jaspr stays SSR-safe.

The phase starts with discovery/design, then lands the implementation in thin
package slices so the shared API direction is proven before adapters adopt it.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-063** | Feasibility and design for horizontal auto-scroll across `dnd_kit`, `dnd_kit_flutter`, and `dnd_kit_jaspr` | ADR 0020 |
| **US-064** | Add axis-aware auto-scroll math to `dnd_kit`, preserving vertical default behavior | ADR 0020 |
| **US-065** | Adopt axis-aware auto-scroll in `dnd_kit_flutter` and replace the Kanban example's custom horizontal helper | ADR 0020 |
| **US-066** | Adopt axis-aware auto-scroll in `dnd_kit_jaspr` and decide whether Jaspr keeps component-owned execution or needs a dedicated controller surface | ADR 0020 |

## Follow-Up

With discovery, the shared-core contract slice, and the Flutter execution slice
now complete, subsequent implementation work should continue along package
boundaries:

- Jaspr execution layer adoption.

The discovery story closed with those slices recommended and with these
explicit deferrals:

- document-viewport horizontal auto-scroll;
- simultaneous bi-directional auto-scroll in one surface;
- nested-scroll policy.

## Validation Ladder

- Discovery proof: current-code audit confirms where auto-scroll is vertical
  only, where app-owned horizontal logic already exists, and what the shared
  API would need to own.
- Design proof: the story packet records the recommended API shape, scope
  boundaries, and follow-up slices without weakening existing validation.
- Core implementation proof now exists in `US-064` (`dart test` + `dart analyze`
  for `packages/dnd_kit`).
- Flutter implementation proof now exists in `US-065` (`flutter test` +
  `dart analyze` for `packages/dnd_kit_flutter`, plus Kanban example proof).
- `US-066` is the planned Jaspr execution slice, including the controller-shape
  decision for Jaspr auto-scroll ownership.
