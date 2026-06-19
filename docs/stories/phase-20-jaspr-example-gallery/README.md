# Phase 20 — Jaspr Example Feature Gallery

With the `dnd_kit_jaspr` adapter now at Flutter parity through Phase 19, the
runnable Jaspr example still only exercises a slice of the public surface
(generic drag/drop, drag handle, drag overlay). This phase closes the
example-coverage gap so the published adapter ships a single runnable gallery
that demonstrates every supported surface.

## Principle

The gallery is example-only. It must:

- demonstrate each `dnd_kit_jaspr` public surface against the real shared
  runtime, not mock behavior;
- stay SSR-safe and client-runnable exactly like the existing example;
- not change any package, public API, or test infrastructure;
- preserve the in-browser drag proof posture (real pointer + keyboard drags on
  `http://localhost:8080`).

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-067** | Expand `examples/jaspr_example_gallery` into a tabbed feature gallery covering generic drag/drop + handle + overlay, sortable preset, auto-scroll, keyboard + a11y (live region/announcements), and modifiers | No ADR (example-only) |

## Follow-Up

- Multi-container sortable demo is deferred until the `SortableContainer` /
  `SortableMultiContainer` parity gap is closed in `dnd_kit_jaspr` (tracked in
  `docs/stories/backlog.md`).
