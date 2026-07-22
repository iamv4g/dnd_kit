# Execution Plan: Sortable Live Preview And Offset Plug-In (0.6.0)

Date: 2026-07-22

## Status

Active

## Outcome

Applications can render live sortable feedback — neighbours moving aside, a gap
opening where the item will land — without re-deriving intent the engine
already computes, and without the library rendering or animating anything.

Two additive capabilities, shipping inside the 0.6.0 line:

1. **Live preview.** During a drag, the sortable layer publishes where the
   active item would land if released now (`previewIndex`,
   `previewContainerId`), instead of only resolving it at drag end.
2. **Offset plug-in.** An opt-in pure function (`SortableOffsetResolver`) maps
   the current preview to a per-item offset. `SortableItemDetails.offset`
   carries it to the builder; the application applies it with whatever
   animation primitive it wants.

Visual behavior is unchanged by default: with no resolver configured every
offset is zero, so an app that ignores the new surface looks exactly as it does
today.

## Context

- This ships **inside 0.6.0**, not a later line. 0.6.0 is neither merged to
  `main` nor published, so folding the new surface in means consumers adopt one
  breaking release instead of two.
- The 0.6.0 drag-default fixes are already complete on `release/0.6.0`
  (`docs/plans/completed/integration-feedback-fixes-0.6.0.md`, ADR 0024). That
  plan stays completed; this is additive work on the same unreleased line, and
  its changelog entries extend the existing 0.6.0 sections rather than opening
  a new version.
- `INTEGRATION_FEEDBACK.md` §3.5 is the demand signal: the integration
  hand-built a placeholder gap and noted it "has to re-derive the insert
  direction the reducer already knows".
- Repository authority that constrains the design:
  - `docs/product/api-principles.md`, Multi-Container Defaults: "Applications
    still own rendering, **animation**, and collection mutation." A
    library-owned animating widget would contradict this; returning geometry
    the application applies does not.
  - Users Own Data: the library reports intent and must not mutate user
    collections.
  - Shared Drag And Registry Principles: "Sortable strategies operate on the
    measured (visible) item subset" — the offset resolver must tolerate
    partially-measured lazy lists the same way.
  - Performance Principles: do not rebuild the whole app per pointer move; run
    collision at most once per frame.
  - Shared Family Naming: no React-shaped names; stay in the `Sortable*`
    family.
  - ADR 0022: `dnd_kit` owns default interaction semantics for the common
    board/list case; override hooks stay explicit and additive.
- Prior art: `@dnd-kit/sortable` computes a transform per item and the consumer
  applies it via `style`; it does not animate on the consumer's behalf. This
  plan follows that division of labour, not its package split — sortable is
  already bundled into `dnd_kit` plus the adapters here.

Two structural findings from the current code, both load-bearing:

- **The strategy only runs at drag end.** `SortableStrategyInput.event` is
  typed `DndDragEndEvent`, and `moveDetailsFor` is called from `onDragEnd`.
  Live preview needs the same computation from an active session, which is why
  the input contract is being generalized.
- **Applying an offset inside the builder cannot corrupt measurement.** In
  Flutter the measured `DndMeasuredBox` wraps the builder's output; in Jaspr the
  measured `div(key: _nodeKey)` is the parent of the builder's output. A
  transform applied by the builder therefore sits *below* the measured node in
  both adapters, so measured rects keep reporting unshifted positions and the
  shift → measure → collision → shift feedback loop does not form. This is what
  makes the feature safe by construction, and it holds only while the offset is
  delivered to (and applied by) the item builder.

## Scope

In scope:

- Live preview for `SortableScope` and `SortableMultiScope` (both use the same
  resolution path, so covering the board costs almost nothing).
- `SortableOffsetResolver` in `dnd_kit`, with `SortableOffsets.verticalList`,
  `SortableOffsets.horizontalList`, and `SortableOffsets.none` as the default.
- `SortableItemDetails.offset` on both adapters, defaulting to `DndPoint.zero`,
  wired for the **single-container** surface.
- Docs: how to apply the offset, the rule that it must be applied inside the
  item builder, an updated placeholder-gap recipe, and the performance note.
- ADR for the preview/offset contract and the "offsets are output, never input"
  rule, including a revisit of the ADR 0024 tradeoff.
- Extend the existing 0.6.0 changelog entries; no additional version bump.
- Align `docs/product/release-roadmap.md`, which is currently stale: its
  "Current State" claims work through `US-079` while later paragraphs describe
  through `US-088`, and it does not mention the 0.6.0 line at all.

Out of scope:

- **Cross-container offsets.** `SortableMultiScope` gets preview but not
  shifting; source-column-closes / target-column-opens geometry is the hardest
  part and must not hold up this line.
- **Any shifting-by-default behavior.** The mechanism ships; whether
  `SortableScope` should shift by default is a 1.0 question.
- Drop animation for `DndDragOverlay` (ghost flying to its landing slot). Same
  problem family, separate work.
- Grid offsets. Two-dimensional shifting has materially different visual
  expectations; add only after list shifting has shipped.
- Any change to primitives (`DndDraggable`, `DndDroppable`, `DndController`).
  They stay silent, per the agreed layering.

## Approach

Four groups, core first so both adapters inherit the same policy.

### Group 1 — `SortableDragContext`

Introduce a drag context (session, `overId`, item rects) that both the move
path and the drag-end path construct `SortableStrategyInput` from, carrying
which phase it is in so a strategy can distinguish preview from commit. Keep
`SortableStrategyInput.event` for this release and deprecate it.

Proof: core tests that a strategy produces identical results from a mid-drag
context and from the equivalent drag-end event.

### Group 2 — Live preview

Resolve the preview through the Group 1 context and publish `previewIndex` /
`previewContainerId` on scope data and `SortableItemDetails`.

Because preview is always available (decision 1), it must not cost anything for
apps that never read it: compute it **lazily and cache per move** rather than
eagerly on every controller notification. A getter that recomputes only when
the drag state has changed since the last read keeps the performance principle
intact while still behaving like always-on state.

The invariant worth testing explicitly: **the preview at the moment of release
equals the move that is committed.** If those diverge, the feature lies to the
UI — exactly the class of bug 0.6.0 fixed.

Proof: core/adapter tests for that invariant across the geometric strategies
and `dropOnOver`; preview is null when no drag is active; a test that reading
preview twice in one move resolves once.

### Group 3 — `SortableOffsetResolver`

Add the pure function type in `dnd_kit` — a fourth member of the plug-in family
alongside `DndCollisionDetector`, `DndModifier`, and `SortableStrategy` —
mapping (active id, item ids, measured item rects, from index, preview index)
to a per-item offset map. Ship the vertical and horizontal list built-ins plus
`none`.

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

`SortableItemDetails.offset` on Flutter and Jaspr; wire the resolver through
`SortableScope`.

Proof: Flutter widget test asserting the builder receives expected offsets; a
guard test that `overId` does not oscillate while offsets are applied; a Jaspr
browser test for the same, including an assertion that measured rects are
unchanged while offsets are non-zero (so a future refactor of the component
structure fails loudly); a gallery demo; website recipe update; ADR; changelog
extension; roadmap alignment.

## Risks And Recovery

- **Preview cost for everyone.** Decision 1 makes preview always-on, so without
  care the strategy would run on every move for every consumer, against the
  performance principle. Mitigation is structural, not incidental: lazy,
  cached-per-move resolution (Group 2). Add a test that proves it resolves once
  per move regardless of how many items read it.
- **Rebuild cost per move.** Every sortable item with a builder already rebuilds
  on each controller notification; offsets add per-item work on top. Mitigation:
  measure a large list before and after with the existing gallery; if the cost
  is material, narrow notification so only items whose offset actually changed
  rebuild. Treat a regression here as blocking, not cosmetic.
- **Environment-sensitive Jaspr browser test.** `auto_scroll_browser_test.dart`
  ("resolves horizontal collision against a target scrolled into view") asserts
  `controller.overId` is still null immediately after a pointermove, before
  auto-scroll brings the target into view. It fails with
  `Expected: null / Actual: DndId(drop-zone)`, meaning the target is already
  under the pointer — a layout/viewport condition, not drag logic.

  Established by control runs rather than inference: the same command fails 3/3
  on the current work, 3/3 on the Group 2 commit, and 3/3 on the untouched
  `release/0.6.0` baseline — yet all of those passed earlier the same day (the
  0.6.0 baseline 7/8, the Group 2 commit 9/9 including three under deliberate
  CPU load). The code is not the variable; the browser environment is. Earlier
  speculation in this plan about a stale compiled bundle was wrong.

  Not a blocker for this line, but the test encodes an assumption about the
  browser viewport that it does not control. It should either set an explicit
  viewport or drop the pre-scroll assertion.
- **Jaspr transform/measurement coupling.** CSS transforms do affect
  `getBoundingClientRect`. Safety depends on the offset being applied to a
  descendant of the measured node, which the current component structure gives
  us — hence the explicit browser assertion above.
- **Interaction with the 0.6.0 defaults.** ADR 0024 excluded the active item
  from collision candidates partly because nothing shifts today. Once items can
  shift, that tradeoff deserves re-evaluation, and `dropOnOver` becomes less
  necessary because the geometric strategies and the visuals agree by
  construction. Revisit explicitly in this plan's ADR rather than letting the
  reasoning go stale.
- **Deprecating `SortableStrategyInput.event` inside a release that already
  carries breaking behavior.** Acceptable because it is additive with a
  deprecation window, but the changelog must not bury it among the 0.6.0 fixes.
- Recovery: each group is a separate commit on `feat/sortable-live-offsets`,
  merged into `release/0.6.0` when green. The feature is inert until a resolver
  is configured, so reverting the visual behavior is a one-line change and
  reverting the feature is a clean commit revert.

## Progress

- [x] Branch `feat/sortable-live-offsets` created from `release/0.6.0`.
- [x] Open decisions 1–4 resolved (see below).
- [x] Group 1 — `SortableDragContext` + parity tests (`SortableDragContext`,
      `SortableResolutionPhase`, and `.commit`/`.preview` factories in core;
      `SortableStrategyInput.context` and `SortableMultiMoveInput.context`
      added with `event` demoted to a deprecated nullable getter;
      `resolveDetails` added beside `moveDetailsFor` on both adapters' scope
      data; core 149 / flutter 107 / jaspr VM 37 tests green and the full
      melos gate passes).
- [x] Group 2 — lazy cached live preview + the preview-equals-commit invariant
      (`SortablePreview` in core; a stateful preview host below `DndScope` on
      both adapters owns the instance and invalidates it on controller change;
      `SortableScopeData.preview` and `SortableItemDetails.previewIndex` /
      `previewContainerId`; core 149 / flutter 112 / jaspr VM 37 green, full
      melos gate green, Jaspr browser suites 23 green).
      Single-container only; multi-container preview is still open (see below).
- [x] Group 2b — multi-container preview (owner-aware area→strategy registry on
      the multi scope state; `SortableMultiContainerArea` is now stateful and
      publishes its strategy; preview resolves with the **source** container's
      strategy and is exposed through `SortableMultiScopeData.preview` and the
      same `SortableItemDetails.previewIndex`; flutter 115 tests green, full
      melos gate green). Decision 4 is now fully delivered.
- [ ] Group 3 — `SortableOffsetResolver` + built-ins + unit tests.
- [ ] Group 4 — adapter exposure, perf measurement, demo, docs, ADR, changelog
      extension, roadmap alignment.
- [ ] Full validation lane green; branch merged into `release/0.6.0`; plan moved
      to `docs/plans/completed/`.

## Decisions

- 2026-07-22: Follow `@dnd-kit/sortable`'s division of labour (library computes
  geometry, application applies it) but not its package split; sortable is
  already bundled here and a separate package would add versioning cost without
  a boundary benefit.
- 2026-07-22: Primitives stay silent. Nothing here touches `DndDraggable`,
  `DndDroppable`, or `DndController` behavior.
- 2026-07-22: Offsets are delivered to the item builder specifically because
  that position is below the measured node in both adapters, which removes the
  feedback loop by construction rather than by discipline.
- 2026-07-22: Ships inside the unreleased 0.6.0 line so consumers absorb one
  breaking release rather than two.
- 2026-07-22 (decision 1): **Preview always published, offsets opt-in.** Preview
  changes nothing visually and answers the original complaint (apps re-deriving
  insert direction); offsets default to `none` so no existing UI changes. Making
  shifting the default was rejected for this line — the mechanism has not
  soaked, and it would alter every consumer's visuals inside a release already
  carrying behavior changes.
- 2026-07-22 (decision 2): **Add `SortableDragContext`**, with
  `SortableStrategyInput.event` kept and deprecated for one release. A single
  code path serving both preview and commit is what makes the
  preview-equals-commit invariant enforceable; a nullable `event` would leave
  strategies unable to tell the phases apart, and a separate preview resolver
  would duplicate the resolution logic that must not drift.
- 2026-07-22 (decision 3): **`SortableOffsetResolver` / `SortableOffsets.*`,
  with `previewIndex` and `previewContainerId`.** Neutral about rendering, so it
  does not promise animation the library will not perform, and it stays in the
  `Sortable*` family per API principles. `SortableLayoutShift` implied the
  library moves things itself; `SortableTransformStrategy` collided too closely
  with the existing `SortableStrategy`.
- 2026-07-22 (decision 4): **Preview for both scopes, offsets single-container
  only.** The board gets correct preview state for labels and announcements at
  almost no cost, while cross-container shifting geometry stays out of this
  line.

- 2026-07-22 (Group 1): `SortableDragContext` carries drag facts only —
  session, phase, `overId`, and the end event — not measured geometry, even
  though the plan sketch mentioned item rects. Rectangles already live on
  `SortableStrategyInput` and `SortableMultiMoveInput`; holding them in two
  places would create two sources of truth for the same layout.
- 2026-07-22 (Group 1): the adapters keep `moveDetailsFor(DndDragEndEvent)` and
  gain `resolveDetails(SortableDragContext)`, with the former delegating to the
  latter. Existing call sites and consumer code keep working, and the commit
  path provably runs the same resolution the preview path will.

- 2026-07-22 (Group 2): the preview instance is owned by a stateful host placed
  *below* `DndScope`, not by `SortableScope` itself, because an uncontrolled
  scope only has a controller below that point. `SortableScopeData.preview` is
  excluded from `==` so live drag state cannot churn `InheritedWidget`
  notifications; the instance is stable for the scope's lifetime.
- 2026-07-22 (Group 2): decision 4's multi-container preview did not land with
  the single-container case. Multi resolution needs the active item's container
  strategy, which lives on the area widgets rather than the scope, so it needs
  a registry the scope does not have yet. Sequenced as Group 2b rather than
  dropped.
- 2026-07-22 (Group 2b): container areas publish their strategy to the scope
  through an owner-aware registry, mirroring how `DndRegistry` handles
  ownership, so a rebuilt area cannot unregister an entry a newer area already
  took over. The preview resolves with the strategy of the container the
  dragged item *came from*, not the one being hovered — that is the container
  whose ordering rules the move is subject to.
- 2026-07-22 (Group 2b): the multi scope needed no separate preview host; its
  state already owns the controller for both the controlled and uncontrolled
  cases, unlike `SortableScope`, which only reaches a controller below
  `DndScope`.

Promote the preview/offset contract and the "offsets are output, never input"
rule into `docs/decisions/` when Group 3 lands.

## Validation

- Focused proof: `dart test packages/dnd_kit` for the drag context, the
  preview-equals-commit invariant, single-resolution-per-move, and the offset
  resolvers; `flutter test packages/dnd_kit_flutter` for builder offsets and the
  no-oscillation guard; `dart test packages/dnd_kit_jaspr -p chrome` on the
  `@TestOn('browser')` files for the browser equivalent plus the
  measured-rects-unchanged assertion.
- Integration or end-to-end proof: a gallery demo showing a real placeholder gap
  on both adapters, driven only by the published offsets.
- Runtime measurement: rebuild/frame cost on a large list before and after,
  since a performance principle is directly at stake.
- Repository-required checks: `dart run melos run validate` before claiming
  completion; note that the melos lane does not run the Jaspr
  `@TestOn('browser')` files, so those must be run explicitly.

## Result

Complete after implementation.
