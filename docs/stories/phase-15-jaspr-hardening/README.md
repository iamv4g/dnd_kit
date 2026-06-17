# Phase 15 — Jaspr Adapter Hardening

This phase hardens `dnd_kit_jaspr` after the Phase 14 foundation
(`docs/stories/phase-14-jaspr-foundation/README.md`). It adds the
browser-specific behavior that turns the generic drag/drop surface into a
production-usable adapter: auto-scroll execution, a full keyboard/accessibility
story, and diagnostics aligned with Flutter. Source spec: `SPEC_JASPR.md` §6.4,
§7, §4.6, §9 Phase C. Architecture decision:
`docs/decisions/0016-jaspr-adapter-scope-and-runtime-model.md`.

## Principle

Hardening must keep the same reuse posture as Phases A/B: the shared engine,
edge/velocity math, and diagnostics contract stay in `dnd_kit_core`. Jaspr only
adds browser execution — DOM scroll, focus, ARIA/live-region announcements — and
must stay SSR-safe (all DOM access via `package:universal_web` guarded by
`kIsWeb`, no `dart:js_interop` at top level). No second drag engine and no
adapter-only re-implementation of math that can live DOM-free in core.

## Delivery Sequence

This mirrors the SPEC_JASPR §9 Phase C list and the Flutter adapter build order.

| Story | Scope | SPEC |
| --- | --- | --- |
| **US-056** | Browser auto-scroll execution for scroll containers + viewport, reusing core `dndAutoScrollVelocity` | §6.4 |
| US-057 | Keyboard + accessibility hardening: focus management, labels, announcement hooks | §7 |
| US-058 | Diagnostics alignment with Flutter (duplicate/unstable id parity, deferred check) | §4.6 |

Phase D (stable sortable presets: vertical/horizontal/grid) follows once the
adapter is hardened. Example-app and documentation updates ride along in each
story's Release proof layer rather than a separate ceremony story.

## Follow-up

Phase C now closes with US-059 as well, but the release plan was corrected
after checking pub.dev: the already-published `dnd_kit_core 0.1.0` and
`dnd_kit_flutter 0.1.0` artifacts predate the shared-runtime extraction, so the
first public Jaspr release must ride a new coordinated dev line
(`dnd_kit_core 0.2.0-dev.0` -> `dnd_kit_flutter 0.2.0-dev.0` ->
`dnd_kit_jaspr 0.2.0-dev.0`). The next selected implementation work still moves
to Phase D (stable sortable presets: vertical list, horizontal list, and grid)
once that publication timing is chosen.

## Validation Ladder

- Shared contract proof: pure-Dart `dart test` reusing `dnd_kit_core`
  (auto-scroll velocity math, diagnostics contract) — no DOM.
- Adapter proof: `jaspr_test` component tests + Chrome browser integration
  (`fvm dart test -p chrome`) for scroll execution, focus/announcement, and
  diagnostics surfacing.
- Cross-adapter parity: auto-scroll thresholds, keyboard drag intent, and
  diagnostics messages behave the same in Flutter and Jaspr (behavioral, not
  pixel, parity).
