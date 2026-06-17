# 0017 The dnd_kit Brand Name Is The Pure Dart Core

Date: 2026-06-17

## Status

Accepted (supersedes ADR 0014)

## Context

ADR 0013 split the toolkit into `dnd_kit_core` (pure Dart engine),
`dnd_kit_flutter` (Flutter adapter), a `dnd_kit` Flutter umbrella that
re-exported the adapter, and `dnd_kit_jaspr`. ADR 0014 then decided the brand
name `dnd_kit` should be the *Flutter umbrella* (stable-only), on the premise
that "the bare name `dnd_kit` is Flutter-only by nature."

That premise no longer matches the family we want. After shipping the
shared-runtime extraction (ADR 0015) and the first public Jaspr release
(US-059), three things were true:

1. The engine — not the Flutter widgets — is the conceptual center of the
   project. Both adapters are thin layers over `dnd_kit_core`.
2. The `dnd_kit` umbrella carried no code of its own and duplicated the
   `dnd_kit_flutter` surface, adding a fourth published package whose only job
   was a shorter Flutter import.
3. The owner wants the brand name on the foundation, accepting that Flutter
   users import `dnd_kit_flutter` (the `flutter_bloc` / `bloc` convention, where
   the bare brand name is the engine and `flutter_*` is the binding).

`dnd_kit_core`, `dnd_kit_flutter`, and `dnd_kit` were already published at
`0.1.0`, and the shared-runtime dev line (`dnd_kit_core`/`dnd_kit_flutter`
`0.2.0-dev.0`, first public `dnd_kit_jaspr 0.2.0-dev.0`) shipped under US-059
before this decision.

## Decision

The bare brand name `dnd_kit` is the pure Dart core engine; the umbrella is
removed.

1. Rename the engine package `dnd_kit_core` → `dnd_kit`. The library entry point
   becomes `package:dnd_kit/dnd_kit.dart`. The API surface is unchanged from
   `dnd_kit_core 0.2.0-dev.0`.
2. The previous `dnd_kit` Flutter umbrella is discontinued. Flutter apps depend
   on `dnd_kit_flutter` and import
   `package:dnd_kit_flutter/dnd_kit_flutter.dart`. There is no umbrella that
   re-exports the Flutter adapter under the bare name.
3. `dnd_kit_flutter` and `dnd_kit_jaspr` depend on `dnd_kit` (the engine). No
   adapter depends on another adapter.
4. `dnd_kit_core` is discontinued on pub.dev (its published `0.1.0` and
   `0.2.0-dev.0` versions remain resolvable but receive no further releases).
   `dnd_kit_jaspr 0.2.0-dev.0`, already published against `dnd_kit_core`,
   continues to resolve; the next adapter dev releases move to `dnd_kit`.
5. The family advances on a coordinated `0.3.0-dev.0` line: `dnd_kit`,
   `dnd_kit_flutter`, and `dnd_kit_jaspr` all publish `0.3.0-dev.0`. The
   `dnd_kit` package skips `0.2.x` because `0.1.x` was the Flutter umbrella;
   `0.3.0-dev.0` is the first engine release under the `dnd_kit` name.
6. Stability still solidifies bottom-up: cut `dnd_kit` 1.0 first, then the
   adapter 1.0 releases. No stable package may depend on a `0.x`/pre-release
   dependency.

This reverses ADR 0014 Decisions 1's umbrella role, 3, and 6, and its
Alternative 2 rejection ("`dnd_kit` re-exports only the engine"). The
Flutter-SDK constraint that ADR 0014 identified still holds and is *why* the
adapters stay separate: a single package cannot depend on both Flutter and a
non-Flutter Jaspr adapter. Making `dnd_kit` the framework-neutral engine is
fully compatible with that constraint — the engine has no Flutter dependency, so
both adapters can build on it.

## Consequences

Positive:

- The brand name sits on the foundation, matching the `bloc`/`flutter_bloc`
  convention and the project's engine-first architecture.
- One fewer published package; the redundant umbrella is gone.
- The Jaspr-without-Flutter boundary is preserved: `dnd_kit` is pure Dart.

Tradeoffs / breaking changes:

- Breaking for `dnd_kit 0.1.x` users: `package:dnd_kit/dnd_kit.dart` no longer
  provides Flutter widgets. They migrate to `dnd_kit_flutter`. Mitigated by the
  pre-1.0 stage, changelog migration notes, and README guidance.
- `dnd_kit` on pub.dev changes identity (Flutter umbrella → pure Dart engine)
  across the `0.1.x` → `0.3.0-dev.0` boundary. The changelog documents this.
- `dnd_kit_core` keeps two published versions on pub.dev forever (discontinue,
  not unpublish).

## Follow-Up

- US-060: execute the rename with maximal git history preservation, repoint the
  Flutter examples off the old umbrella onto `dnd_kit_flutter`, update package
  docs and the architecture doc, and validate with `melos run validate` plus
  `pub publish --dry-run` for `dnd_kit`, `dnd_kit_flutter`, and `dnd_kit_jaspr`.
- Discontinue `dnd_kit_core` on pub.dev and publish the `0.3.0-dev.0` line after
  human go-ahead (irreversible; deferred from the implementation story).
