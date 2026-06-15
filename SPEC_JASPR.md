# `dnd_kit_jaspr` — Product & Technical SPEC v0.1

## 1. Product Summary

`dnd_kit_jaspr` is a Jaspr adapter for the `dnd_kit` family. It brings the
shared drag-and-drop engine to Jaspr applications while keeping the core
contract framework-agnostic and maximizing code reuse with the Flutter adapter.

The main goal is not to create a separate drag-and-drop system for Jaspr. The
goal is to extend the existing `dnd_kit` architecture so Flutter and Jaspr
share the same domain model, drag lifecycle, collision logic, modifier logic,
sortable math, diagnostics, and as much controller/runtime code as possible.

`dnd_kit_jaspr` targets browser-driven Jaspr UIs such as:

- basic drag and drop;
- sortable lists;
- sortable grids;
- Kanban-style boards;
- page and form builders;
- dashboard and admin UIs;
- web editors and block-based composition UIs.

The first release should focus on a stable generic drag-and-drop foundation for
Jaspr. Sortable presets should build on top of the same shared contracts after
the base adapter is proven.

---

# 2. Product Goals

## 2.1 Goals

`dnd_kit_jaspr` must satisfy the following goals:

1. **Common contract first, framework adapters second**
   Flutter and Jaspr must behave like peer adapters over one shared engine, not
   like two loosely related libraries.

2. **Maximize shared code**
   Any logic that can compile without Flutter, Jaspr, `dart:html`, or browser
   DOM types must live in a shared package, preferably `dnd_kit_core`.

3. **Keep adapter boundaries honest**
   Flutter-specific concepts stay in `dnd_kit_flutter`. DOM, browser, and Jaspr
   concepts stay in `dnd_kit_jaspr`. Geometry, state, events, collision,
   modifiers, diagnostics, and reusable runtime logic stay shared.

4. **Preserve the existing mental model**
   A user who knows `DndScope`, `DndDraggable`, `DndDroppable`,
   `DndDragOverlay`, and `SortableItem` in Flutter should recognize the same
   concepts in Jaspr with equivalent callback payloads and lifecycle rules.

5. **Pure Jaspr compatibility**
   A Jaspr app must be able to depend on `dnd_kit_jaspr` and `dnd_kit_core`
   without pulling in the Flutter SDK.

6. **Browser-first behavior**
   The Jaspr adapter must support pointer, mouse, touch, keyboard, measuring,
   overlay, collision, and auto-scroll behavior appropriate for browser UIs.

7. **User data ownership**
   Like the Flutter adapter, `dnd_kit_jaspr` must report intent and state
   changes, but must never mutate user collections or application state.

8. **Progressive parity**
   The project should pursue parity where the contract is portable, while
   accepting that some UX details are adapter-specific.

9. **Contract testability**
   The shared contract must be provable with reusable tests so Flutter and Jaspr
   can be checked against the same drag/drop behavior expectations.

---

## 2.2 Non-goals

This spec does **not** include the following:

- multi-container sortable;
- nested sortable;
- full virtualized variable-height sortable lists;
- native OS drag and drop;
- cross-window or cross-app drag and drop;
- dragging files between the browser and the operating system;
- a combined `dnd_kit` package that exposes both Flutter and Jaspr entry
  points;
- dependency on app state-management frameworks.

This spec also does not require full feature parity with every current Flutter
detail in the first Jaspr release if that parity would force a poor browser API
or duplicate shared logic.

---

# 3. Package Architecture

The package family should evolve toward this layout:

```text
packages/
  dnd_kit_core/     # pure Dart engine and shared runtime contracts
  dnd_kit_flutter/  # Flutter adapter
  dnd_kit_jaspr/    # Jaspr adapter
  dnd_kit/          # stable Flutter umbrella re-export
examples/
  basic_drag_drop/
  example_gallery/
  jaspr_basic_drag_drop/
  jaspr_sortable_list/
docs/
```

## 3.1 `dnd_kit_core`

`dnd_kit_core` remains the framework-agnostic foundation and should grow to
hold more reusable runtime code extracted from the Flutter adapter when that
code has no Flutter dependency.

### Owns

```text
- DndId
- DndPoint
- DndSize
- DndRect
- DndTransform
- DndState
- DndDragSession
- DndCollision
- DndCollisionDetector
- DndModifier
- DndRegistry
- DndDiagnosticsConfig
- DndSensorDescriptor and activation constraints
- base sortable math
- shared measuring cache contracts
- shared controller/runtime base logic
- shared adapter contract-test fixtures
```

### Must not own

```text
- Flutter Widget / BuildContext / RenderBox
- Jaspr Component / DOM Element / browser Event
- OverlayEntry / portal mounting
- GestureRecognizer / browser event listeners
- semantics or ARIA implementation details
```

## 3.2 `dnd_kit_flutter`

`dnd_kit_flutter` remains the Flutter adapter. It should depend on shared core
runtime contracts instead of owning duplicate controller or measuring logic when
that logic can be framework-neutral.

### Owns

```text
- Flutter widget API
- Flutter sensors and gesture integration
- Flutter measuring and geometry conversion
- Flutter overlay rendering
- Flutter auto-scroll execution
- semantics and haptic integration
- stable Flutter sortable widgets
```

## 3.3 `dnd_kit_jaspr`

`dnd_kit_jaspr` is a new adapter package for Jaspr/browser UIs.

### Owns

```text
- Jaspr component API
- browser pointer/mouse/touch/keyboard integration
- DOM measuring and coordinate normalization
- DOM/portal overlay rendering
- browser auto-scroll execution
- accessibility and keyboard hooks for the web
- stable Jaspr sortable components when the base adapter is proven
```

### Depends on

```yaml
dependencies:
  dnd_kit_core: ^0.1.0
  jaspr: any
```

`dnd_kit_jaspr` must not depend on Flutter or on the `dnd_kit` umbrella.

## 3.4 `dnd_kit`

`dnd_kit` stays a Flutter-only umbrella package as defined by ADR 0014. It must
not attempt to combine Flutter and Jaspr entry points because the Flutter SDK
constraint would make the package unusable in pure Jaspr projects.

---

# 4. Shared Contract And Reuse Rules

## 4.1 Rule Of Extraction

When implementing Jaspr support, use this rule:

```text
If code can compile and make sense without Flutter or browser DOM types,
it belongs in shared code, not inside an adapter.
```

That means shared code should be extracted before duplicating logic in
`dnd_kit_jaspr`.

## 4.2 Shared Public Concepts

The following concepts must mean the same thing in Flutter and Jaspr:

- `DndId`
- `DndPoint`, `DndRect`, `DndTransform`
- `DndState`
- `DndDragSession`
- `DndDragStartEvent`, `DndDragMoveEvent`, `DndDragEndEvent`,
  `DndDragCancelEvent`
- `DndCollisionDetector`
- `DndModifier`
- `DndSensorDescriptor`
- sortable move details and strategy math

The callback payloads must stay portable so business logic can be shared across
apps and tests.

## 4.3 Shared Runtime Contracts

To maximize reuse, the shared layer should expose neutral runtime building
blocks such as:

- a controller/runtime base that owns drag state transitions;
- a shared measuring cache/invalidating registry using `DndRect`;
- collision execution and `overId` resolution;
- modifier composition and transform application;
- adapter-neutral diagnostics for duplicate or unstable ids.

The current Flutter `DndController` should be treated as a candidate for
extraction: its state machine, collision orchestration, modifier application,
and measurement-cache interactions are mostly pure Dart and should move into
shared code where possible. The Flutter adapter can then wrap that shared logic
with `ChangeNotifier`, widget lifecycle wiring, and Flutter-specific measuring.

The Jaspr adapter should build on the same extracted runtime instead of
re-implementing it.

## 4.4 Shared Measuring Contract

Both adapters must normalize layout into `DndRect` before it reaches collision
or modifier logic.

The shared measuring contract should define:

- draggable and droppable measurement caches keyed by `DndId`;
- dirty/clean/removed invalidation states;
- refresh hooks that call adapter-owned measurers;
- stable behavior when a source node is temporarily unmounted or re-mounted.

Only the act of measuring is adapter-specific. The cache semantics and
invalidation behavior should be shared.

## 4.5 Shared Sortable Contract

Sortable behavior must be layered on top of the same core drag/drop lifecycle.

The following should be shared between Flutter and Jaspr:

- sortable IDs and move details;
- strategy math for vertical, horizontal, and grid sorting;
- collision inputs and reorder intent rules;
- keyboard coordinate helpers when they do not depend on framework event types.

The following stay adapter-specific:

- item measurement and DOM/render-tree queries;
- visual transitions and styling hooks;
- focus and accessibility implementation details.

## 4.6 Shared Diagnostics Contract

Both adapters must surface consistent diagnostics for:

- duplicate IDs;
- empty or unstable IDs;
- conflicting ownership/registration;
- invalid lifecycle transitions;
- stale measurement or registration state when it can be detected.

The text of warnings may vary slightly by adapter, but the situations that
trigger them should be aligned.

---

# 5. Jaspr Adapter API Direction

The Jaspr adapter should preserve the family naming where practical:

- `DndScope`
- `DndController`
- `DndDraggable`
- `DndDroppable`
- `DndDragHandle`
- `DndDragOverlay`
- `SortableScope`
- `SortableItem`

The exact Jaspr component signatures may differ from Flutter widget
constructors, but the conceptual roles and callback payloads should match.

## 5.1 First Stable Surface

The first stable `dnd_kit_jaspr` surface should include:

- scope and controller foundation;
- draggable and droppable components;
- drag handles;
- pointer, mouse, touch, and keyboard activation;
- drag overlay;
- measuring and collision runtime;
- modifiers;
- auto-scroll for common browser scroll containers.

## 5.2 Sortable Surface

Sortable support should come after the generic foundation is proven.

The initial stable sortable scope for Jaspr should be limited to:

- vertical list;
- horizontal list;
- grid.

Everything else stays out of scope for this spec.

---

# 6. Jaspr Runtime Model

## 6.1 Event Model

`dnd_kit_jaspr` should use a custom pointer-driven runtime, not the native HTML
Drag and Drop API.

Reasons:

- the native browser drag/drop API is tied to `dataTransfer` behavior and
  browser-specific constraints;
- it behaves differently across browsers and input types;
- it is a poor fit for matching the existing `dnd_kit` custom drag session
  model;
- it would reduce shared logic with Flutter.

The adapter should instead normalize browser input into shared
`DndSensorActivationEvent` and drag-session updates.

## 6.2 Measuring

DOM elements should be measured via browser geometry APIs and converted into
`DndRect` in viewport coordinates.

The adapter must define clear rules for:

- when measurements are refreshed;
- how scrolling changes coordinates;
- how hidden or detached elements are handled;
- when a drag source can keep its last known rect during a drag.

## 6.3 Overlay

The drag overlay should render in a dedicated top-level DOM layer or portal-like
mount point so it can float independently from the source component subtree.

The overlay contract should match Flutter conceptually:

- it follows the active drag transform;
- it can render custom drag content;
- it should not force the source subtree to rebuild on every move.

## 6.4 Auto-scroll

Auto-scroll should be supported for common browser scroll containers and the
document viewport.

The scroll execution layer is adapter-specific, but edge-threshold and speed
calculation logic should be extracted to shared code if it can stay DOM-free.

---

# 7. Accessibility And Keyboard

Accessibility must be part of the adapter contract, but it should follow web
best practices instead of copying Flutter semantics literally.

The Jaspr adapter should support:

- keyboard activation and movement for drag flows that can be represented with
  focus-based interaction;
- focusable drag handles where applicable;
- configurable labels or announcement hooks;
- predictable focus behavior when drag starts, moves, and ends.

The spec does not require a one-to-one mapping between Flutter semantics and
web accessibility primitives. It requires equivalent user intent and a usable
keyboard story.

---

# 8. Validation Strategy

The project should validate `dnd_kit_jaspr` at three layers:

## 8.1 Shared Contract Proof

Pure Dart tests should verify shared runtime behavior such as:

- state transitions;
- collision selection;
- modifier application;
- measuring cache invalidation;
- sortable strategy math;
- duplicate registration diagnostics.

These tests should be reused by both adapters where possible.

## 8.2 Adapter Proof

Jaspr/browser integration tests should verify:

- pointer activation and drag movement;
- touch and mouse differences where applicable;
- keyboard drag flows;
- overlay positioning;
- collision updates while scrolling;
- auto-scroll behavior.

Flutter keeps its existing adapter proof path.

## 8.3 Cross-Adapter Parity Proof

The repository should add a portable contract matrix for scenarios that must
behave the same in Flutter and Jaspr, such as:

- drag start and cancel lifecycle;
- drop target resolution;
- modifier effects on transform;
- sortable reorder intent for the stable strategies.

The intent is not pixel parity. The intent is behavioral parity.

---

# 9. Delivery Plan

## Phase A - Shared Runtime Extraction

Before building a large Jaspr adapter surface, extract reusable runtime pieces
from `dnd_kit_flutter` into `dnd_kit_core`:

- controller/state orchestration;
- measurement cache contracts;
- any pure-Dart auto-scroll math;
- adapter contract-test helpers.

This phase is the key to avoiding duplicated behavior.

## Phase B - Jaspr Generic Drag/Drop Foundation

Implement:

- `DndScope`
- `DndController`
- `DndDraggable`
- `DndDroppable`
- `DndDragHandle`
- core sensors
- measuring
- overlay
- collision runtime

## Phase C - Jaspr Hardening

Add:

- keyboard support;
- accessibility hooks;
- auto-scroll;
- diagnostics alignment with Flutter;
- example apps and documentation.

## Phase D - Stable Sortable Presets

Add stable Jaspr sortable support for:

- vertical list;
- horizontal list;
- grid.

Advanced sortable modes remain out of scope for this spec.

---

# 10. Success Criteria

This spec is successful when it enables an implementation with the following
properties:

- `dnd_kit_jaspr` ships as a pure Jaspr adapter with no Flutter dependency.
- Flutter and Jaspr share one domain contract and one reusable runtime core
  wherever technically possible.
- Adapter-specific code is limited to rendering, input wiring, measuring,
  scrolling, and accessibility integration.
- Shared business logic and tests can target the same drag/drop concepts across
  both adapters.
- The implementation avoids introducing a second, duplicated drag engine.

---

# 11. Open Questions

- Should the extracted shared runtime stay inside `dnd_kit_core`, or does the
  repository eventually need a second pure-Dart package if the core surface
  becomes too broad?
- What is the minimum Jaspr/browser version matrix the first release should
  support?
- Which parts of keyboard sortable interaction can be kept identical to Flutter
  without creating awkward web semantics?
- Should the first Jaspr release include sortable presets immediately, or ship
  generic drag/drop first and add sortable in the next dev cycle?
