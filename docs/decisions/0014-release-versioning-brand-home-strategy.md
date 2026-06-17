# 0014 Release, Versioning, And Brand Home Strategy

Date: 2026-06-15

## Status

Superseded by ADR 0017

Decisions 1 (umbrella role), 3, and 6 below — that the bare name `dnd_kit` is
the stable Flutter umbrella — are reversed by ADR 0017, which makes `dnd_kit`
the pure Dart core engine and removes the umbrella. The Flutter-SDK constraint
that kept the adapters separate still holds.

## Context

After ADR 0013 split the toolkit into `dnd_kit_core` (pure Dart engine),
`dnd_kit_flutter` (Flutter adapter), a `dnd_kit` re-export umbrella, and a
planned `dnd_kit_jaspr` adapter, we needed a coherent answer to three coupled
questions:

1. Which packages iterate fast (dev releases) and which publish stable?
2. Can a single `dnd_kit` package expose both a Flutter and a Jaspr entry point?
3. Where does the neutral, framework-agnostic project "home" live?

Two hard constraints shaped the decision:

- `dnd_kit_flutter` requires the Flutter SDK (`flutter: sdk: flutter`,
  `environment: flutter: ">=3.24.0"`). Any package that depends on it becomes
  Flutter-only, and pubspec dependencies cannot be made conditional. So a single
  package cannot depend on both `dnd_kit_flutter` and a non-Flutter
  `dnd_kit_jaspr`: a pure Jaspr (Dart web/server) project would fail `pub get`.
- The umbrella `dnd_kit` has no code of its own; it cannot iterate features
  faster than the adapter it re-exports, because every feature lives in the
  adapter/core below it.

## Decision

1. Per-platform adapters stay separate packages. Do not build a package that
   combines Flutter and Jaspr entry points; the Flutter SDK constraint makes it
   unusable by pure Jaspr projects. This follows the Dart ecosystem norm
   (`flutter_bloc` and `angular_bloc` are separate, with no combining package).

2. Fast dev iteration lives where the code is: `dnd_kit_core`,
   `dnd_kit_flutter`, and `dnd_kit_jaspr` publish both dev and stable releases.
   Early adopters depend on these directly during `0.x`.

3. `dnd_kit` is the Flutter umbrella and publishes stable releases only. It is
   the "production-ready Flutter entry point" that re-exports `dnd_kit_flutter`.
   It never carries dev releases.

4. Stability solidifies bottom-up: cut `dnd_kit_core` 1.0 first, then adapter
   1.0 releases, then the `dnd_kit` umbrella 1.0. A stable adapter must depend on
   a stable core; no stable package may depend on a `0.x`/pre-release dependency.
   Adapters may reach stability on independent timelines (Flutter before Jaspr)
   as long as each sits on a sufficiently stable `dnd_kit_core`.

5. The neutral brand "home" is the GitHub repository README plus the GitHub
   Pages site (`https://vanvixi.github.io/dnd_kit/`), not a pub package. We do
   not publish a code-less landing package: it would break existing `dnd_kit`
   users, mislead `pub add dnd_kit` (install yields nothing usable), and score
   poorly on pub.dev.

6. Because the bare name `dnd_kit` is Flutter-only by nature, its pubspec
   `description` and README must state plainly that it is the Flutter entry
   point and direct Jaspr users to `dnd_kit_jaspr`. Every package README
   cross-links the family and the home site.

## Alternatives Considered

1. One `dnd_kit` package with `flutter.dart` and `jaspr.dart` libraries.
   Rejected: depending on both adapters forces the Flutter SDK on the whole
   package, so `package:dnd_kit/jaspr.dart` is unusable in pure Jaspr projects;
   pubspec dependencies cannot be conditional.
2. `dnd_kit` re-exports only `dnd_kit_core`. Rejected: it duplicates the existing
   `dnd_kit_core` package (two names for the same engine) and breaks current
   Flutter users who import the full toolkit from `package:dnd_kit/dnd_kit.dart`.
3. `dnd_kit` as a docs-only landing package. Rejected: breaks existing users,
   confuses `pub add`, and misuses pub.dev as a website host.
4. `dnd_kit` ships dev fast while adapters stay frozen-stable. Rejected as
   internally inconsistent: the umbrella has no independent code, so it cannot
   ship new features unless the adapter also changes.

## Consequences

Positive:

- Clear, non-breaking roles: `dnd_kit` = stable Flutter entry point; adapters and
  core = fast-moving dev surface.
- The multi-framework family is mechanically sound; Jaspr support can ship as a
  separate adapter without disturbing Flutter users.
- The neutral home lives on the web, where landing pages belong.

Tradeoffs:

- Asymmetry: the bare `dnd_kit` name leans Flutter; Jaspr users use
  `dnd_kit_jaspr`. Mitigated by description/README wording and cross-links.
- Releasing the `dnd_kit` umbrella requires publishing `dnd_kit_flutter` first
  (dependency order).
- A "neutral brand pub package" does not exist by design; the brand is held on
  pub.dev only through the useful Flutter umbrella.

## Follow-Up

- US-045: clarify the `dnd_kit` Flutter scope and cross-link all package READMEs
  and the home site.
- When the API freezes, cut stable releases bottom-up (core, then adapters, then
  umbrella) under a separate release story.
- Track `dnd_kit_jaspr` as its own adapter story/initiative on `dnd_kit_core`.
