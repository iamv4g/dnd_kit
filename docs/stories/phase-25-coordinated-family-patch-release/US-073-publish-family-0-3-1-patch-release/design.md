# Design

## Domain Model

The release unit is the same three-package family already established by the
post-US-060 topology:

- `dnd_kit`: pure Dart engine and dependency root.
- `dnd_kit_flutter`: Flutter adapter that depends on `dnd_kit`.
- `dnd_kit_jaspr`: Jaspr adapter that depends on `dnd_kit`.

This story closes the prepared `0.3.1` patch line as one coordinated publish
act so dependency constraints, changelog truth, and release proof stay aligned.

## Application Flow

1. Confirm the repository package metadata and changelogs already align on
   `0.3.1`.
2. Run `dart pub get` and the shared family validation command.
3. Run package publish dry-runs in dependency order through the verifier.
4. Record the exact publish order and the remaining maintainer-run irreversible
   step.

## Interface Contract

No new public API is introduced by this story. The published contracts are the
already-landed `0.3.1` deltas:

- `dnd_kit` exports the shared `DndAnnouncements` contract.
- `dnd_kit_flutter` exports additive Flutter accessibility labels, hints, and
  lifecycle announcement support.
- `dnd_kit_jaspr` exports the SSR-safe drag-handle sync behavior and reuses the
  shared announcements contract from `dnd_kit`.

The release contract is therefore versioning and proof, not new behavior.

## Data Model

No application data model changes. Durable Harness state adds an intake row, a
story row, and a trace for the coordinated release packet.

## UI / Platform Impact

Platform impact is consumer-facing through package publication:

- Pure-Dart consumers receive the shared accessibility contract in `dnd_kit`.
- Flutter consumers receive the `0.3.1` accessibility hardening release.
- Jaspr consumers receive the `0.3.1` SSR fix and the shared-announcements
  dependency alignment.

## Observability

Proof is release-oriented:

- shared family verification via `fvm dart run tool/verify_family_release.dart`;
- package dry-run output in dependency order;
- Harness intake/story/trace records capturing versions, publish order, and any
  blocker.

## Alternatives Considered

1. Publish only `dnd_kit_flutter` and `dnd_kit_jaspr`.
   Rejected because both adapters are already versioned against
   `dnd_kit: ^0.3.1`, so the engine release must be part of the same publish
   packet.
2. Publish only `dnd_kit_jaspr 0.3.1` for the SSR fix.
   Rejected because the repository already prepared a coordinated `0.3.1` line
   across all three packages, and splitting that line would make changelog and
   dependency truth harder to audit.
3. Hold the prepared patch line for a later minor/dev release.
   Rejected because the package metadata and changelogs already declare
   `0.3.1`; the next safe step is to verify and publish that prepared line.
