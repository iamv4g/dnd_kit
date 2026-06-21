# US-071 Flutter Accessibility Hardening

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_flutter` must provide a first-class, Flutter-native accessibility
story for drag and drop. Beyond the existing keyboard movement baseline, the
adapter should let applications expose accessible labels and usage
instructions, give drag handles their own semantics surface, keep keyboard
focus predictable during a drag, and optionally announce drag lifecycle
changes to assistive technologies. The implementation should match Jaspr's
user-facing accessibility outcomes where Flutter platform semantics allow,
without copying ARIA or live-region APIs literally. This work is intended to
ship in `dnd_kit_flutter 0.3.1`.

## Relevant Product Docs

- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`
- `docs/stories/phase-3-sensors-activation/US-017-flutter-keyboard-drag-activation.md`
- `docs/stories/phase-15-jaspr-hardening/US-057-jaspr-keyboard-accessibility.md`

## Acceptance Criteria

- `DndDraggable` supports additive, configurable accessibility naming and
  instructions through Flutter semantics without breaking current defaults.
- `DndDragHandle` exposes an explicit accessibility surface appropriate for
  Flutter instead of remaining pointer-only infrastructure.
- A Flutter-native announcement hook or configuration surface can announce drag
  start, drag-over target changes, drop, and cancel from shared controller
  state transitions for keyboard and pointer drags alike.
- Keyboard drags keep focus on the activator through pickup, movement, drop,
  and cancel flows.
- The shared `dnd_kit` runtime and drag math stay unchanged; all a11y execution
  remains adapter-local to `dnd_kit_flutter`.
- Widget tests cover semantics output, handle accessibility, disabled behavior,
  focus retention, and lifecycle announcement behavior.
- Package-facing docs and `CHANGELOG.md` describe the accessibility surface,
  and the implementation prepares the `dnd_kit_flutter 0.3.1` release line.

## Design Notes

- Commands:
  `scripts/bin/harness-cli query matrix`
  `fvm flutter test packages/dnd_kit_flutter`
  `fvm dart analyze packages/dnd_kit_flutter`
- Queries:
  `rg -n "Semantics|Focus|SemanticsService|announce" packages/dnd_kit_flutter`
  `rg -n "label|hint|announce|aria|live region" docs/stories/phase-15-jaspr-hardening/US-057-jaspr-keyboard-accessibility.md packages/dnd_kit_jaspr`
- API:
  Candidate additive surfaces may include `DndDraggable` semantics
  label/instruction fields, `DndDragHandle` semantics fields, and a
  Flutter-native announcements configuration surface on `DndScope` or another
  adapter-local type.
- Tables:
  none.
- Domain rules:
  Announcements and semantics must derive from controller/runtime state and
  application-owned item identity. Applications still own data mutation and
  spoken copy customization.
- UI surfaces:
  Flutter semantics tree, focus behavior during keyboard drag, and optional
  assistive-technology announcements.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-071 --unit 1 --integration 1 --e2e 0 --platform 1`.

| Layer | Expected proof |
| --- | --- |
| Unit | Pure-Dart tests for default/custom announcement message builders if the final API introduces a standalone value type; otherwise widget-level proof may carry the message expectations. |
| Integration | `fvm flutter test packages/dnd_kit_flutter` proves semantics labels/hints, handle accessibility, focus retention, disabled behavior, and lifecycle announcement triggering. |
| E2E | Not required; adapter-local accessibility hardening should be provable through widget tests in this slice. |
| Platform | `fvm dart analyze packages/dnd_kit_flutter` stays clean with no cross-adapter dependency leaks. |
| Release | `packages/dnd_kit_flutter/README.md` and `CHANGELOG.md` document the new accessibility surface, and the package release line is prepared for `0.3.1`. |

## Harness Delta

Creates the first Phase 23 story packet for planned Flutter accessibility
hardening and gives the `0.3.1` accessibility slice a durable matrix entry.

## Evidence

- Created 2026-06-20 from a user-approved change request to open a dedicated
  Flutter accessibility hardening/parity story instead of folding the work into
  ad hoc notes.
- Implemented 2026-06-20:
  - Added `DndAnnouncements` to `dnd_kit_flutter` and exposed
    `DndScope(announcements: ...)` as an opt-in Flutter-native accessibility
    announcement surface.
  - `DndDraggable` now supports semantics `label` and `hint`, while preserving
    the default keyboard usage hint when no custom hint is provided.
  - `DndDragHandle` now exposes its own semantics `label` and `hint` surface
    instead of remaining pointer-only infrastructure.
  - Accessibility announcements are derived from shared controller state
    transitions and emitted through Flutter announcement APIs, not through a
    second runtime or a copied web live-region model.
  - Keyboard-drag focus retention is covered through pickup, movement, drop,
    and cancel flows.
- Proof:
  - `fvm flutter test packages/dnd_kit_flutter` -> pass (`110` tests).
  - `fvm dart analyze packages/dnd_kit_flutter` -> No issues found.
  - `packages/dnd_kit_flutter/pubspec.yaml` bumped to `0.3.1`.
  - `README.md` and `CHANGELOG.md` updated for the accessibility surface.
