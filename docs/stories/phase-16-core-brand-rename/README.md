# Phase 16 — Core As Brand Rename

This phase makes the bare brand name `dnd_kit` the pure Dart core engine and
removes the Flutter umbrella, per ADR 0017 (which supersedes ADR 0014). It
follows the first public Jaspr dev release standardization (US-059) and the
shared-runtime extraction (US-047).

## Principle

The engine is the conceptual center of the toolkit, so it carries the brand
name — the `bloc` / `flutter_bloc` convention. Adapters (`dnd_kit_flutter`,
`dnd_kit_jaspr`) depend on `dnd_kit` directly; no adapter depends on another,
and the Jaspr-without-Flutter boundary is preserved because `dnd_kit` stays
pure Dart. Git history of the engine code must be preserved (whole-directory
`git mv`, not delete-and-recreate).

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-060** | Rename `dnd_kit_core` → `dnd_kit`; remove the umbrella; repoint adapters, examples, and docs; coordinate the `0.3.0-dev.0` line | ADR 0017 |

## Validation Ladder

- Workspace resolves: `dart pub get` after the rename and constraint updates.
- Full gate: `fvm dart run melos run validate` (format, analyze, core/jaspr
  `dart test`, Flutter adapter + example `flutter test`).
- Publish proof: `fvm dart pub publish --dry-run` from `packages/dnd_kit`,
  `packages/dnd_kit_flutter`, and `packages/dnd_kit_jaspr`.
- Release act (publish + discontinue `dnd_kit_core`) is deferred to explicit
  human go-ahead; it is irreversible.
