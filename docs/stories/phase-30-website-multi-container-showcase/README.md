# Phase 30 - Website Multi-Container Showcase

Phase 29 made multi-container a supported cross-adapter feature, but the
hosted Jaspr homepage still demonstrates the older app-owned assembly path in
its Kanban centerpiece. That leaves the public website behind the supported
surface even though `dnd_kit_jaspr` now ships a first-class multi-container
API.

This phase upgrades the homepage showcase so the live website demonstrates the
supported Jaspr board/list contract directly:

- refactor the website Kanban showcase to use `SortableMultiScope`,
  `SortableMultiContainerArea`, and `SortableMultiItem`;
- keep the homepage's visual design, telemetry HUD, and app-owned state
  mutation intact;
- align website copy and proof with the production-ready multi-container
  contract shipped in Phase 29.

## Principle

Website showcase work in this phase must:

- present the supported Jaspr multi-container surface, not a stale lower-level
  workaround;
- keep marketing-site visuals and content app-owned;
- preserve SSR-safe website build and hydration behavior;
- prove the homepage still builds and the multi-container showcase still works
  as a real browser-facing adoption surface.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-078** | Upgrade the website Kanban showcase to the supported Jaspr multi-container surface and align copy/proof | No ADR (website/demo adoption under the existing Phase 29 contract) |

## Validation Ladder

- Adapter proof: the existing Jaspr multi-container package/browser coverage
  remains the library contract proof.
- Website proof: homepage source analyzes cleanly and `website/` still produces
  a release `jaspr build`.
- Product proof: website copy and roadmap now describe the hosted Kanban as a
  supported multi-container showcase instead of a generic app-owned workaround.
