# US-034 Performance Baseline Smoke Benchmark For Drag And Sortable Flows

## Status

implemented

## Lane

normal

## Product Contract

The repository provides a repeatable smoke benchmark that exercises sortable
strategy computation and representative Flutter drag/sortable widget flows with
generous regression thresholds. The benchmark is intended to catch accidental
performance cliffs during routine validation, not to publish device-specific
performance guarantees.

## Relevant Product Docs

- `docs/product/release-roadmap.md`
- `docs/product/package-architecture.md`
- `docs/TEST_MATRIX.md`

## Acceptance Criteria

- A focused benchmark smoke test exists for sortable strategy computation over a
  larger item set.
- A focused benchmark smoke test exists for repeated Flutter sortable drag
  gestures.
- The smoke tests use generous thresholds and print measured timings so future
  agents can compare local baseline changes.
- The benchmark command is recorded in the durable story row and can be run
  independently from the full workspace validation.

## Design Notes

- Commands: `fvm flutter test packages/dnd_kit_sortable/test/src/performance_smoke_test.dart`
- Queries: `scripts/bin/harness-cli query matrix`
- API: no public API changes
- Tables: story row `US-034`
- Domain rules: sortable order remains application-owned; benchmark tests only
  verify move intent and drag/drop smoke behavior.
- UI surfaces: no production UI changes

## Validation

When updating durable proof status, use numeric booleans:
`scripts/bin/harness-cli story update --id US-034 --unit 1 --integration 1 --e2e 0 --platform 0`.

| Layer | Expected proof |
| --- | --- |
| Unit | Sortable strategy smoke benchmark passes for a large in-memory list. |
| Integration | Flutter sortable drag smoke benchmark passes through widget gesture flow. |
| E2E | Not required; no browser or app-level journey changes. |
| Platform | Not required; this is widget/runtime proof rather than native shell proof. |
| Release | Covered by `melos run validate` because sortable package tests are included. |

## Harness Delta

No Harness tool changes are required. Benchmark ingestion remains a future
Harness capability rather than part of this story.

## Evidence

- `fvm flutter test packages/dnd_kit_sortable/test/src/performance_smoke_test.dart`
  passed. Observed local baseline: sortable strategy 122ms for 2000 runs over
  240 items; widget drag 171ms for 12 drag gestures over 24 items.
- `fvm flutter test packages/dnd_kit_sortable` passed with the new smoke
  benchmark included. Observed local package-run baseline: sortable strategy
  115ms for 2000 runs over 240 items; widget drag 167ms for 12 drag gestures
  over 24 items.
- `fvm dart analyze` passed with no issues.
- `scripts/bin/harness-cli story verify US-034` passed, running the focused
  smoke benchmark through the durable verify command.
- `fvm dart run melos run validate` passed, covering format, workspace analyze,
  core tests, Flutter adapter tests, sortable tests with the new smoke
  benchmark, and the Kanban example widget tests.
