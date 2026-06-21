# Overview

## Current Behavior

The current coordinated family release packet stops at `US-069`, which covered
the stable `0.3.0` publication line. Since then, the repository has landed the
next publishable patch deltas and already prepared package metadata for
`0.3.1`:

- `packages/dnd_kit` is versioned `0.3.1` and its changelog now records the
  shared `DndAnnouncements` accessibility contract.
- `packages/dnd_kit_flutter` is versioned `0.3.1`, depends on
  `dnd_kit: ^0.3.1`, and its changelog records Flutter accessibility
  hardening.
- `packages/dnd_kit_jaspr` is versioned `0.3.1`, depends on
  `dnd_kit: ^0.3.1`, and its changelog records the SSR handle-sync assertion
  fix plus reuse of the shared announcements contract.

Those release-facing deltas were created by `US-070`, `US-071`, and `US-072`,
but no dedicated high-risk story packet yet captures the coordinated `0.3.1`
family publication itself.

## Target Behavior

The package family is published as a coordinated stable patch release in
dependency order:

1. `dnd_kit 0.3.1`
2. `dnd_kit_flutter 0.3.1` depending on `dnd_kit: ^0.3.1`
3. `dnd_kit_jaspr 0.3.1` depending on `dnd_kit: ^0.3.1`

The release packet proves the prepared patch line with the shared family
verification command, keeps changelog truth aligned with the package versions,
and documents the remaining maintainer-run irreversible publish step without
introducing new runtime scope.

## Affected Users

- Maintainer publishing the package family to pub.dev.
- Pure-Dart consumers depending on `dnd_kit`.
- Flutter applications depending on `dnd_kit_flutter`.
- Jaspr applications depending on `dnd_kit_jaspr`.

## Affected Product Docs

- `docs/product/release-roadmap.md`
- `packages/dnd_kit/CHANGELOG.md`
- `packages/dnd_kit_flutter/CHANGELOG.md`
- `packages/dnd_kit_jaspr/CHANGELOG.md`
- `docs/stories/phase-21-jaspr-adapter-fixes/US-070-jaspr-ssr-handle-sync-assertion-fix.md`
- `docs/stories/phase-23-flutter-accessibility-hardening/US-071-flutter-accessibility-hardening.md`
- `docs/stories/phase-24-shared-accessibility-contract/US-072-share-dnd-announcements-between-adapters.md`

## Non-Goals

- Adding new runtime behavior beyond the already-landed `0.3.1` package deltas.
- Changing package topology, adapter boundaries, or accessibility design.
- Automating credentialed pub.dev publication inside the repository.
