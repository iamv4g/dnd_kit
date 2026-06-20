# Release Roadmap

This roadmap captures the major product phases that shaped the current
`dnd_kit` family. Durable implementation/proof status lives in
`scripts/bin/harness-cli query matrix`.

## Phase 0 - Repo Foundation And Architecture Freeze

Set up the monorepo, package structure, coding conventions, API direction, and
basic validation commands.

First story: `docs/stories/phase-0-foundation/US-001-repository-foundation.md`.

## Phase 1 - Core Engine

Build the pure Dart foundation:

- stable IDs;
- geometry types;
- drag state machine;
- event models;
- collision detectors;
- modifier contracts;
- registry contracts;
- sensor contracts.

## Phase 2 - Basic Flutter Adapter

Create the first Flutter adapter surface:

- `DndScope`;
- `DndController`;
- `DndDraggable`;
- `DndDroppable`;
- Flutter registry integration;
- basic measuring;
- drag event lifecycle.

## Phase 3 - Sensors And Activation

Support pointer, mouse, touch, long press, drag handles, and keyboard input.

## Phase 4 - Measuring, Collision Runtime, And Modifiers

Harden coordinate-space measuring, collision runtime behavior, custom collision
detectors, modifier composition, and cached measuring.

## Phase 5 - Overlay, Visual State, And Auto-Scroll

Complete drag overlay, draggable/droppable visual state, and common auto-scroll
behavior.

## Phase 6 - Stable Sortable Preset

Provide sortable vertical list, horizontal list, and grid APIs.

## Phase 7 - Kanban Showcase And Experimental Multi-Container

Use Kanban as a realistic proof that the generic engine supports complex UIs.

## Phase 8 - Production Hardening

Add diagnostics, performance baselines, cross-platform verification, docs, and
release-quality checks.

First story: `docs/stories/phase-8-production-hardening/US-031-release-quality-workspace-validation.md`.

Package polish before release also collapses the old umbrella-only `dnd_kit`
role into the primary Flutter package through
`docs/stories/phase-8-production-hardening/US-035-main-package-rename-and-umbrella-collapse.md`.

## Phase 9 - V1 Release Readiness

Prepare the renamed package for external review and publication:

- package-facing README and changelog;
- public API documentation polish;
- stale example documentation cleanup;
- publish dry-run and release metadata checks.

First story: `docs/stories/phase-9-release-readiness/US-036-docs-api-polish-before-release.md`.

## Phase 10 - Post-Publish Adoption

Improve the package after the first pub.dev publication by closing package
score gaps, keeping release metadata verifiable, and making adoption paths
clear for users.

First story: `docs/stories/phase-10-post-publish-adoption/US-037-pubdev-quality-package-example-pass.md`.

Adoption hardening also makes draggables and sortables work inside scrollables
and lazy `ListView.builder` lists through
`docs/stories/phase-10-post-publish-adoption/US-040-drag-inside-scrollable-and-lazy-lists/`
(see `docs/decisions/0010-draggable-arena-gesture.md`).

## Phase 11 - First Public Release

Cut the first stable public release line for the original engine, Flutter
adapter, and umbrella topology.

First story: `docs/stories/phase-11-first-public-release/US-046-publish-core-and-flutter-0-1-0.md`.

## Phase 12 - Multi-Framework Foundation

Prepare the package family for multiple adapters:

- rename the Flutter adapter package to `dnd_kit_flutter`;
- keep `dnd_kit` as the Flutter umbrella during the transitional topology;
- clarify family cross-links and package-selection guidance.

Key stories:

- `docs/stories/phase-12-multi-framework-foundation/US-043-rename-flutter-package-for-multi-framework.md`
- `docs/stories/phase-12-multi-framework-foundation/US-045-clarify-dnd-kit-scope-and-cross-link-family.md`

## Phase 13 - Shared Runtime Extraction

Move the framework-neutral drag runtime and measuring-cache contract into the
pure Dart engine so multiple adapters can share one drag engine.

Key story:

- `docs/stories/phase-13-shared-runtime-extraction/US-047-extract-shared-drag-runtime/overview.md`

## Phase 14 - Jaspr Adapter Foundation

Establish `dnd_kit_jaspr` as a browser/Jaspr peer adapter over the shared
engine:

- package scaffold;
- scope/controller;
- draggable/droppable;
- drag handle;
- drag overlay;
- browser modifier wiring and example proof.

Phase README: `docs/stories/phase-14-jaspr-foundation/README.md`.

## Phase 15 - Jaspr Adapter Hardening

Harden the Jaspr adapter for production browser behavior:

- browser auto-scroll execution;
- keyboard and accessibility support;
- diagnostics alignment with Flutter;
- first public Jaspr dev-release standardization.

Phase README: `docs/stories/phase-15-jaspr-hardening/README.md`.

## Phase 16 - Core As Brand Rename

Make the bare brand name `dnd_kit` the pure Dart engine, remove the Flutter
umbrella, and repoint both adapters to the renamed engine package.

Phase README: `docs/stories/phase-16-core-brand-rename/README.md`.

## Phase 17 - Flutter Upgrade And Workspace Unification

Upgrade the development Flutter SDK to 3.44.2 and fold the Jaspr example into
the shared workspace so the repository resolves as one package graph.

Phase README: `docs/stories/phase-17-flutter-upgrade-workspace/README.md`.

## Phase 18 - Jaspr Sortable Preset

Give `dnd_kit_jaspr` a sortable preset at parity with the Flutter adapter
(`SortableScope`, `SortableItem`) over the shared engine reorder math, so both
adapters compute identical move intent. Additive and adapter-local;
`dnd_kit_jaspr` bumps to `0.3.0-dev.1`.

Phase README: `docs/stories/phase-18-jaspr-sortable/README.md`.

## Phase 19 - Cross-Adapter Horizontal Auto-Scroll

Deliver horizontal auto-scroll for the shared engine and both adapters without
forking the edge-threshold or velocity math:

- discovery and design for one axis-aware core contract;
- Flutter execution adoption against the existing Kanban board reference;
- Jaspr execution adoption while preserving SSR safety and component-owned
  browser execution.

Phase README: `docs/stories/phase-19-horizontal-auto-scroll/README.md`.

## Phase 20 - Jaspr Example Feature Gallery

Expand the runnable Jaspr example into one tabbed feature gallery that
demonstrates the adapter's supported public surface in a real browser:

- generic drag/drop with handle + overlay;
- sortable preset;
- drag-driven auto-scroll;
- keyboard + live-region accessibility;
- shared-runtime modifiers.

Phase README: `docs/stories/phase-20-jaspr-example-gallery/README.md`.

## Phase 21 - Jaspr Adapter Fixes

Capture bounded adapter regressions found by the expanded browser gallery
without turning them into example-only work:

- keep the shared runtime as the single drag engine;
- land the smallest adapter-local contract fix;
- strengthen focused package/browser proof around the reproduced bug.

Phase README: `docs/stories/phase-21-jaspr-adapter-fixes/README.md`.

## Phase 22 - Coordinated Family Release Publication

Promote the `0.3.0-dev` line to a coordinated stable `0.3.0` pub.dev release
across the current package family:

- publish the `dnd_kit 0.3.0` engine release first;
- publish the matching `dnd_kit_flutter 0.3.0` adapter release second;
- publish the `dnd_kit_jaspr 0.3.0` adapter release third;
- keep changelog, dependency constraints, and proof aligned with the published
  order.

First story:
`docs/stories/phase-22-coordinated-family-release/US-069-publish-current-family-dev-line/overview.md`.

## Phase 23 - Flutter Accessibility Hardening

Close the remaining adapter accessibility gap after Jaspr's Phase 15 hardening
by giving `dnd_kit_flutter` a first-class Flutter-native accessibility story
for the next package patch release:

- configurable semantics labels and usage instructions for draggables and drag
  handles;
- optional assistive-technology announcements for drag lifecycle changes;
- focus-stable keyboard dragging with adapter-local execution over the shared
  runtime;
- package docs and changelog preparation for `dnd_kit_flutter 0.3.1`.

Phase README: `docs/stories/phase-23-flutter-accessibility-hardening/README.md`.

## Current State

The repository has implemented work through `US-071`. The Flutter adapter, the
pure Dart engine, and the Jaspr adapter share the `dnd_kit` brand family under
the post-US-060 topology, the workspace is unified under the Phase 17 toolchain,
and both adapters now ship a sortable preset over the shared engine. Phase 19
has now closed its discovery slice, its shared-core implementation slice, and
both adapter execution slices: horizontal auto-scroll is considered feasible
through an additive shared-core axis selector, `dnd_kit` exposes axis-aware
shared auto-scroll math, `dnd_kit_flutter` plus the Kanban example use that
shared contract for horizontal container auto-scroll, and `dnd_kit_jaspr`
mirrors the same contract for horizontal browser scroll containers while
keeping its auto-scroll execution component-owned. Phase 20 closes the runnable
Jaspr example gap with `examples/jaspr_example_gallery`, a tabbed feature
gallery covering drag/drop, sortable, auto-scroll, accessibility, and
modifiers over the shared runtime. Phase 21 then closes the next gallery-found
adapter regressions by restoring `DndDragOverlay` rebinding after a controlled
`DndScope` controller swap and fixing the Jaspr SSR handle-sync assertion.
Phase 23 then closes Flutter accessibility hardening by adding semantics
labels/hints, handle accessibility, and lifecycle announcements in the
`dnd_kit_flutter 0.3.1` line. Future work should extend this roadmap through
new product docs, story packets, and decisions rather than by reviving the old
umbrella/core topology from the historical specs.
