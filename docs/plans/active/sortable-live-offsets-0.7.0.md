# Execution Plan: Sortable Live Preview And Offset Plug-In (0.7.0)

Date: 2026-07-22

## Status

Active — implementation blocked on the open decisions below.

## Outcome

Applications can render live sortable feedback — neighbours moving aside, a gap
opening where the item will land — without re-deriving intent the engine
already computes, and without the library rendering or animating anything.

Two additive capabilities:

1. **Live preview.** During a drag, the sortable layer publishes where the
   active item would land if released now (target index and container), instead
   of only resolving it at drag end.
2. **Offset plug-in.** An opt-in pure function maps the current preview to a
   per-item offset. `SortableItemDetails` carries that offset to the builder;
   the application applies it with whatever animation primitive it wants.

Default behavior is unchanged: with no plug-in configured, every offset is zero
and the library behaves exactly as 0.6.0.

## Context

- Design discussion followed the 0.6.0 integration fixes
  (`docs/plans/completed/integration-feedback-fixes-0.6.0.md`, ADR 0024), which
  deferred "opt-in animated sortable / expose the preview insert index" as
  needing its own design pass. This plan is that pass.
- `INTEGRATION_FEEDBACK.md` §3.5 is the demand signal: the integration
  hand-built a placeholder gap and noted it "has to re-derive the insert
  direction the reducer already knows".
- Repository authority that constrains the design:
  - `docs/product/api-principles.md`, Multi-Container Defaults: "Applications
    still own rendering, **animation**, and collection mutation." A
    library-owned animating widget would contradict this; returning geometry
    the application applies does not.
  - `docs/product/api-principles.md`, Users Own Data: the library reports
    intent and must not mutate user collections.
  - `docs/product/api-principles.md`, Shared Drag And Registry Principles:
    "Sortable strategies operate on the measured (visible) item subset" — the
    offset resolver must tolerate partially-measured lazy lists the same way.
  - `docs/product/api-principles.md`, Performance Principles: do not rebuild the
    whole app per pointer move; run collision at most once per frame.
  - `docs/product/api-principles.md`, Shared Family Naming: no React-shaped
    names (`useSortable`-style); stay in the `Sortable*` family.
  - ADR 0022: `dnd_kit` owns default interaction semantics for the common
    board/list case; override hooks stay explicit and additive.
- Prior art considered: `@dnd-kit/sortable` computes a transform per item and
  the consumer applies it via `style`; it does not animate on the consumer's
  behalf. This plan follows that division, not its package split — sortable is
  already bundled into `dnd_kit` plus the adapters here, and a separate pub
  package only for offset policy would add versioning cost without a boundary
  benefit.

Two structural findings from reading the current code, both load-bearing:

- **The strategy only runs at drag end.** `SortableStrategyInput.event` is
  typed `DndDragEndEvent`, and `moveDetailsFor` is called from `onDragEnd`.
  Live preview needs the same computation from an active session, so the input
  contract has to be generalized (see open decision 2).
- **Applying an offset inside the builder cannot corrupt measurement.** In
  Flutter the measured `DndMeasuredBox` wraps the builder's output; in Jaspr the
  measured `div(key: _nodeKey)` is the parent of the builder's output. A
  transform applied by the builder therefore sits *below* the measured node in
  both adapters, so measured rects keep reporting unshifted positions and the
  shift→measure→collision→shift feedback loop does not form. This is what makes
  the feature safe by construction, and it is only true while the offset is
  delivered to (and applied by) the item builder.

## Scope

In scope (0.7.0):

- Live preview state for the single-container sortable surface
  (`SortableScope` / `SortableItem`), published on every move.
- A pure-Dart offset resolver plug-in type in `dnd_kit`, with built-in vertical
  and horizontal list implementations plus the default no-op.
- `SortableItemDetails.offset` on both adapters, defaulting to zero.
- Docs: how to apply the offset (and the rule that it must be applied inside
  the item builder), a placeholder-gap recipe update, and the perf note.
- ADR for the preview/offset contract and the "offsets are output, never
  input" rule.
- Version 0.7.0 across the family.
- Align `docs/product/release-roadmap.md`, which is currently stale: its
  "Current State" claims work through `US-079` while later paragraphs describe
  through `US-088`, and it does not mention the 0.6.0 line at all.

Out of scope:

- Multi-container cross-container shifting (`SortableMultiScope`). Preview may
  be computed there, but offsets stay single-container until the simpler case
  has soaked. Revisit as a follow-up phase.
- Making any shifting behavior the default. This plan ships the mechanism only;
  whether `SortableScope` should shift by default is a 1.0 question (see open
  decision 1).
- Drop animation for `DndDragOverlay` (ghost flying to its landing slot). Same
  problem family, separate work.
- Grid offsets. `SortableStrategies.grid` exists, but two-dimensional shifting
  has materially different visual expectations; add only after list shipping.
- Any change to primitives (`DndDraggable`, `DndDroppable`, `DndController`).
  They stay silent, per the agreed layering.

## Approach

Four groups, core first so both adapters inherit the same policy.

### Group 1 — Generalize the strategy input

Introduce a drag context the strategy input can be built from during a move as
well as at drag end, so one code path serves preview and commit. Keep the
existing `SortableStrategyInput` fields; the change is how it is constructed
and what `event` becomes (open decision 2).

Proof: core tests that a strategy produces identical results from a mid-drag
context and from the equivalent drag-end event.

### Group 2 — Live preview

Compute the preview on controller change in the sortable scope and expose it:
the target index, the target container id, and the resolved `overId`. Publish
through scope data and `SortableItemDetails`.

The invariant worth testing explicitly: **the preview at the moment of release
equals the move that is committed.** If those two ever diverge, the feature is
lying to the UI, which is exactly the class of bug 0.6.0 fixed.

Proof: core/adapter tests for the invariant across the geometric strategies and
`dropOnOver`; preview is null when no drag is active.

### Group 3 — Offset resolver plug-in

Add a pure function type in `dnd_kit` — a fourth member of the existing
plug-in family alongside `DndCollisionDetector`, `DndModifier`, and
`SortableStrategy` — mapping (active id, item ids, measured item rects, from
index, preview index) to a per-item offset map. Ship built-ins for vertical and
horizontal lists and a `none` default.

Symmetry worth preserving in naming and docs: `DndModifier` transforms the
**active** item's transform; this transforms the **other** items' transforms.

Rules the implementation must hold:

- Pure and synchronous; no measurement, no side effects.
- Unmeasured (off-screen) items get no offset rather than a guessed one, per
  the visible-subset principle. This is visually sufficient because off-screen
  items are not seen.
- Offsets are output only. They must never be fed back into collision or
  measurement.

Proof: core unit tests — preview equal to from-index yields all-zero offsets;
items outside the moved range are untouched; unmeasured items are skipped;
direction reverses correctly for upward vs downward moves.

### Group 4 — Adapter exposure, docs, release

`SortableItemDetails.offset` on Flutter and Jaspr, defaulting to
`DndPoint.zero`. Wire the resolver through `SortableScope`.

Proof: Flutter widget test asserting the builder receives expected offsets; a
guard test that `overId` does not oscillate while offsets are applied; Jaspr
browser test for the same; a gallery demo; website recipe update; ADR;
changelogs; 0.7.0 bump; roadmap alignment.

## Risks And Recovery

- **Rebuild cost per move.** Every sortable item with a builder already rebuilds
  on each controller notification, and offsets add per-item work on top. This
  runs against the performance principle "do not rebuild the whole app on every
  pointer move". Mitigation: measure a 200-item list before and after with the
  existing gallery; if the cost is material, narrow notification so only items
  whose offset actually changed rebuild. Treat a regression here as blocking,
  not cosmetic.
- **Jaspr transform/measurement coupling.** CSS transforms do affect
  `getBoundingClientRect`. Safety depends on the offset being applied to a
  descendant of the measured node, which the current component structure gives
  us. Mitigation: a browser test that asserts measured rects are unchanged
  while offsets are non-zero, so a future refactor of that structure fails
  loudly.
- **Interaction with the 0.6.0 defaults.** ADR 0024 excluded the active item
  from collision candidates partly because nothing shifts today. Once items
  shift, that tradeoff should be re-evaluated, and `dropOnOver` becomes less
  necessary because the geometric strategies and the visuals agree by
  construction. Mitigation: revisit ADR 0024 explicitly in this plan's ADR
  rather than letting the reasoning go stale.
- **API surface growth pre-1.0.** A fourth plug-in type plus preview state is a
  meaningful public addition. Mitigation: keep every addition opt-in and
  additive; no primitive changes; one ADR recording the contract.
- Recovery: each group is a separate commit; the feature is inert until a
  resolver is configured, so reverting the default is a one-line change and
  reverting the feature is a clean commit revert.

## Progress

- [x] Branch `feat/sortable-live-offsets` created from `release/0.6.0`.
- [ ] Open decisions 1–4 resolved.
- [ ] Group 1 — generalized strategy input + parity tests.
- [ ] Group 2 — live preview + the preview-equals-commit invariant test.
- [ ] Group 3 — offset resolver plug-in + built-ins + unit tests.
- [ ] Group 4 — adapter exposure, perf measurement, demo, docs, ADR, 0.7.0 bump,
      roadmap alignment.
- [ ] Full validation lane green; plan moved to `docs/plans/completed/`.

## Decisions

- 2026-07-22: Follow `@dnd-kit/sortable`'s division of labour (library computes
  geometry, application applies it) but not its package split; sortable is
  already bundled here and a separate package would add versioning cost without
  a boundary benefit.
- 2026-07-22: Primitives stay silent. Nothing in this plan touches
  `DndDraggable`, `DndDroppable`, or `DndController` behavior.
- 2026-07-22: Offsets are delivered to the item builder specifically because
  that position is below the measured node in both adapters, which removes the
  feedback loop by construction rather than by discipline.

Open — implementation should not start before these are settled:

1. **Default posture.** Recommend shipping opt-in only in 0.7.0 (no resolver =
   today's behavior), and deferring "should `SortableScope` shift by default"
   to 1.0 once the preset has soaked. Materially different choice: make a
   built-in resolver the `SortableScope` default now, which changes every
   existing consumer's visuals.
2. **Strategy input generalization.** Recommend a new `SortableDragContext`
   that both the move path and the end path construct from, with
   `SortableStrategyInput.event` kept for one release and deprecated. Materially
   different choice: relax `event` to a nullable base event type, which is
   smaller but leaves strategies unable to tell preview from commit.
3. **Naming.** Recommend `SortableOffsetResolver` / `SortableOffsets` for the
   plug-in and `previewIndex` / `previewContainerId` for the state, staying in
   the `Sortable*` family per API principles. Alternatives worth one pass:
   `SortableLayoutShift`, `SortableTransformStrategy`.
4. **Multi-container in or out.** Recommend computing preview for
   `SortableMultiScope` (cheap, same code path) but shipping offsets only for
   the single-container case in 0.7.0.

Promote the preview/offset contract and the "offsets are output, never input"
rule into `docs/decisions/` when Group 3 lands.

## Validation

- Focused proof: `dart test packages/dnd_kit` for the generalized input, the
  preview-equals-commit invariant, and the offset resolvers;
  `flutter test packages/dnd_kit_flutter` for builder offsets and the
  no-oscillation guard; `dart test packages/dnd_kit_jaspr -p chrome` on the
  `@TestOn('browser')` files for the browser equivalent, including the measured
  rects-unchanged assertion.
- Integration or end-to-end proof: a gallery demo showing a real placeholder
  gap on both adapters, driven only by the published offsets.
- Runtime measurement: rebuild/frame cost on a large list before and after,
  since a performance principle is directly at stake.
- Repository-required checks: `dart run melos run validate` before claiming
  completion; note that the melos lane does not run the Jaspr
  `@TestOn('browser')` files, so those must be run explicitly.

## Result

Complete after implementation.
