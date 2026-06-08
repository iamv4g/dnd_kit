# US-009 Core Sensor Contracts

## Status

implemented

## Lane

normal

## Product Contract

`dnd_kit_core` must expose pure Dart sensor contracts so later Flutter pointer,
mouse, touch, long-press, keyboard, and custom sensors can share activation
metadata and lifecycle boundaries without depending on Flutter APIs.

## Relevant Product Docs

- `docs/product/overview.md`
- `docs/product/package-architecture.md`
- `docs/product/api-principles.md`
- `docs/product/release-roadmap.md`

## Acceptance Criteria

- `dnd_kit_core` exports sensor kind and activation event value objects.
- Sensor activation data carries a stable draggable ID, normalized position,
  input kind, and optional adapter-owned data without Flutter geometry types.
- Activation constraints support distance, delay, and pending movement tolerance.
- Sensor descriptors connect a sensor kind, input kind, activation constraint,
  and activator callback.
- Adapter-specific sensor runtimes have a core lifecycle interface for start,
  move, end, and cancel.
- Unit tests cover value behavior, constraint decisions, activator dispatch, and
  the lifecycle interface contract.

## Design Notes

- Commands: `fvm dart format .`, `fvm dart analyze`,
  `fvm dart test packages/dnd_kit_core`, and
  `scripts/bin/harness-cli story verify US-009`.
- Queries: `scripts/bin/harness-cli query matrix`.
- API: pure Dart sensor contracts only; no Flutter gesture recognizers, widget
  lifecycle, controller runtime, long-press timers, keyboard bindings, overlay,
  measuring, or sortable behavior in this story.
- Tables: none.
- Domain rules: applications own user data; sensor activation data carries only
  stable library metadata and optional opaque adapter data.
- UI surfaces: none.

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-009 --unit 1 --integration 0 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | `fvm dart test packages/dnd_kit_core` passes. |
| Integration | Not required; this story introduces only one package's pure Dart sensor model. |
| E2E | Not required; no user-facing UI exists. |
| Platform | Not required; no Flutter/platform code exists. |
| Release | `fvm dart analyze` passes from the repository root. |

## Harness Delta

- Adds the seventh Phase 1 story packet and durable matrix row.

## Evidence

- `fvm dart format .` completed with no changes needed after implementation.
- `fvm dart analyze` passed with no issues.
- `fvm dart test packages/dnd_kit_core` passed with 70 tests.
- `scripts/bin/harness-cli story verify US-009` passed with
  `fvm dart test packages/dnd_kit_core`.
