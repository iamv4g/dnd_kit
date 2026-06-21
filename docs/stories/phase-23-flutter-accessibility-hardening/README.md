# Phase 23 — Flutter Accessibility Hardening

This phase closes the next adapter-level parity gap after the Jaspr hardening
work in Phase 15. `dnd_kit_flutter` already supports keyboard pickup/move/drop
and a baseline semantics hint from `US-017`, but it does not yet offer the
same first-class accessibility surface that `dnd_kit_jaspr` now exposes for
labels, usage instructions, and drag lifecycle announcements.

The goal is not to copy ARIA or DOM concepts into Flutter. The goal is to
deliver equivalent accessibility outcomes on Flutter's own platform model so
screen-reader and keyboard users can understand, operate, and track drag state
without relying on pointer-only cues. This phase targets the next additive
adapter release, `dnd_kit_flutter 0.3.1`.

## Principle

Flutter accessibility hardening in this phase must:

- preserve `dnd_kit` as the only drag runtime and derive any announcements from
  shared controller/runtime state transitions;
- use Flutter-native accessibility primitives (`Semantics`, `Focus`, and
  announcement APIs) rather than copying Jaspr's ARIA/live-region surface
  literally;
- keep the API additive and backward-compatible for existing draggables,
  handles, and sortable flows;
- aim for cross-adapter behavioral parity where it is portable, while allowing
  framework-specific implementation details and naming.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-071** | Add Flutter-native accessibility labels, instructions, handle semantics, and drag lifecycle announcements for `dnd_kit_flutter` | No ADR (adapter-local additive hardening) |

## Validation Ladder

- Widget proof: `flutter test` covers semantics labels/hints, focus retention,
  handle behavior, disabled behavior, and lifecycle announcement hooks.
- Package proof: `dart analyze packages/dnd_kit_flutter` stays clean.
- Release proof: package docs and `CHANGELOG.md` record the new accessibility
  surface and the package version bump to `0.3.1`.
