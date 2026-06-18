# Design

## Domain Model

The current core contract is one-dimensional but encoded as vertical-specific
inputs (`y`, `height`). The selected direction is to keep the existing 2D
adapter inputs (`DndPoint` + `DndSize`) and add an axis discriminator rather
than replacing them with a scalar-only input object.

Chosen shared model:

- keep `DndAutoScrollOptions` as the shared threshold/velocity config;
- add a new additive enum such as `DndScrollAxis { vertical, horizontal }`;
- extend `dndAutoScrollVelocity(...)` with an optional `axis` argument that
  defaults to `DndScrollAxis.vertical`.

This keeps the return contract unchanged: logical pixels to scroll this frame,
preserves existing call sites by default, and still lets the function validate
that the pointer remains inside the viewport on both axes.

## Application Flow

Expected future flow if the feature is feasible:

1. Active drag updates provide a global pointer.
2. The adapter converts that pointer into viewport-local coordinates.
3. The adapter selects the horizontal or vertical axis inputs.
4. Shared core math returns a velocity for that axis.
5. The adapter applies the velocity to its platform scroll position.
6. If scrolling changed measured geometry, the adapter refreshes measurements
   and collision state through the existing drag runtime path.

## Interface Contract

Chosen contract direction:

1. Generalize `dndAutoScrollVelocity(...)` into an axis-aware contract.
   This keeps one shared curve and one test surface.
2. Keep current parameter types (`localPointer`, `viewportSize`, extents) and
   switch the primary axis internally based on `axis`.
3. Reuse the same `DndAutoScrollOptions`; horizontal does not introduce a
   second threshold or speed type.

Adapter-facing implications:

- Flutter should add an `axis` option on `DndAutoScroll` and
  `DndAutoScrollController`, defaulting to vertical. Horizontal execution maps
  to the existing `ScrollPosition` extents and `jumpTo(...)`.
- Jaspr should add an `axis` option on `DndAutoScroll`, defaulting to vertical.
  Horizontal execution maps to `scrollLeft`, `scrollWidth`, and `clientWidth`
  while preserving SSR safety and the existing measurement-refresh path.
- Document viewport horizontal support is deferred. The first library slice
  covers explicit container-wrapped auto-scroll only, matching the current
  component/widget surfaces.

## Data Model

No tables, persistence, or retained records change.

## UI / Platform Impact

- Flutter already has a working app-owned reference in the Kanban example. That
  behavior is a discovery aid, not a library contract, but it confirms the
  library can likely adopt the same axis behavior without inventing new product
  semantics.
- Jaspr must stay SSR-safe: no top-level DOM access and no adapter-only math
  forks.
- Nested scrollables, document-viewport horizontal scroll, and simultaneous
  two-axis movement are explicitly deferred. Each one adds policy questions the
  current vertical wrapper API does not answer.

## Observability

No new logs or metrics are required for discovery. The durable output is the
story packet plus ADR 0020, which records the accepted shared API direction.

## Alternatives Considered

1. Keep the library vertical-only and leave horizontal behavior app-owned.
   Rejected: Flutter already demonstrates real adopter need, and Jaspr would
   remain permanently behind for a behavior that can stay shared.
2. Add a sibling horizontal core helper instead of an axis parameter.
   Rejected: it duplicates contract surface while preserving the same curve.
3. Replace the existing API with a scalar-only input object.
   Rejected for now: more churn for current adapters without a clear payoff.
4. Add horizontal execution separately in each adapter.
   Rejected: violates the shared-runtime reuse posture.
5. Jump straight to simultaneous bi-directional auto-scroll.
   Rejected: scope expansion before single-axis parity is proven.
