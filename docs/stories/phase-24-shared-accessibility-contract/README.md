# Phase 24 — Shared Accessibility Contract

Phase 23 closed the Flutter adapter's missing accessibility surface, but it did
so by introducing a second copy of `DndAnnouncements` next to the existing
Jaspr copy. The message builders and announcement contract are framework-neutral
pure Dart, so they belong in `dnd_kit` instead of living twice across peer
adapters.

This phase extracts only the portable accessibility contract into the shared
engine while keeping all platform execution local to each adapter:

- Flutter continues to emit platform announcements through semantics APIs.
- Jaspr continues to emit browser announcements through `DndLiveRegion`.
- `dnd_kit` owns the shared announcement builders and defaults.

## Principle

Shared accessibility work in this phase must:

- move only pure-Dart contract surface into `dnd_kit`;
- avoid introducing Flutter, Jaspr, DOM, or semantics execution dependencies
  into the core package;
- preserve additive public API behavior for both adapters;
- reduce duplicate adapter code without weakening adapter-specific validation.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-072** | Move `DndAnnouncements` into `dnd_kit` and rewire both adapters to reuse the shared contract while keeping execution adapter-local | No ADR (shared pure-Dart extraction under existing package boundaries) |

## Validation Ladder

- Core proof: `dart test packages/dnd_kit` covers default and custom
  announcement builders from the shared package.
- Adapter proof: Flutter and Jaspr package tests still pass after rewiring to
  the shared contract.
- Platform proof: `dart analyze` stays clean for `dnd_kit`,
  `dnd_kit_flutter`, and `dnd_kit_jaspr`.
