# Phase 25 — Coordinated Family Patch Release

After the `0.3.0` family release closed in Phase 22, the repository landed the
next additive package deltas across all three publishable packages:

- `dnd_kit` now owns the shared `DndAnnouncements` accessibility contract.
- `dnd_kit_flutter` added Flutter-native accessibility labels, hints, drag
  lifecycle announcements, and focus-stable keyboard drag behavior.
- `dnd_kit_jaspr` fixed the SSR handle-sync assertion and now reuses the shared
  announcement contract from `dnd_kit`.

Those changes shipped on the `0.3.1` line in package metadata and changelogs.
`US-073` added the coordinated release packet — mirroring `US-069` for `0.3.0` —
so version order, proof, and the publish act stay auditable. The family
published to pub.dev in dependency order on 2026-06-20.

## Principle

Release work in this phase must:

- publish in dependency order: `dnd_kit` -> `dnd_kit_flutter` ->
  `dnd_kit_jaspr`;
- keep the release scope limited to already-landed `0.3.1` package deltas;
- prove the release locally with workspace validation plus package dry-runs
  before any irreversible pub.dev publish;
- record the exact version line, publish order, and any remaining maintainer
  step.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-073** | Publish the current engine + Flutter + Jaspr patch line as coordinated stable `0.3.1` | No ADR (release execution under existing package topology and accessibility decisions) |

## Validation Ladder

- Workspace proof: `dart pub get` plus `fvm dart run melos run validate` stay
  green through the shared family-release verifier.
- Package proof: `dart pub publish --dry-run` passes for the three packages in
  dependency order, tolerating only the expected dirty-git-tree warning before
  commit/publish.
- Release proof: the story packet records the `0.3.1` versions, the three
  package changelog scopes, and the dependency-ordered publish that shipped on
  2026-06-20.
