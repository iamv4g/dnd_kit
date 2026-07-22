# 0023 Repository-Centered Harness Workflow

Date: 2026-07-22

## Status

Accepted

## Context

This repository was created with an older Harness structure that required every
task to pass through intake, risk lanes, SQLite story state, proof flags, and a
recorded trace. The checked-in instructions still required
`scripts/bin/harness-cli`, but that compatibility binary and its local database
were not installed. As a result, the mandatory first command failed before
normal repository work could begin.

Upstream `repository-harness` now provides a smaller repository-centered core.
Its default source of truth is product documentation, architecture, plans when
durable memory is warranted, decisions, code, tests, runtime evidence, and Git.
The SQLite control plane remains supported only as an explicitly selected
compatibility profile.

## Decision

Adopt the repository-centered Harness core beginning with
`harness-v0.1.4`.

- `AGENTS.md` is a compact entrypoint to `docs/WORKFLOW.md` and project-specific
  authority.
- Bounded work uses an ephemeral plan and behavior-appropriate proof without
  mandatory control-plane writes.
- Complex work uses one evolving Git-native plan under `docs/plans/active/` and
  moves it to `docs/plans/completed/` only after validation.
- `docs/product/`, `docs/ARCHITECTURE.md`, `docs/decisions/`, code, tests, CI,
  and observable behavior remain the current contract.
- Existing `docs/stories/`, risk-lane, trace, test-matrix, backlog, and SQLite
  schema material is retained as historical evidence or optional compatibility
  reference. It is not the default task lifecycle.
- `.harness-core/` records the installed upstream base for safe three-way
  updates. The platform binary under `scripts/bin/` and timestamped recovery
  backups remain local ignored artifacts.

## Alternatives Considered

1. Install the complete SQLite compatibility profile and restore the old
   mandatory workflow. Rejected because upstream no longer treats it as the
   default and the project does not have an external orchestrator requiring it.
2. Delete all old story and compatibility documents. Rejected because they
   preserve useful delivery, validation, and design history for `dnd_kit`.
3. Copy the latest upstream repository wholesale. Rejected because upstream
   Harness product and architecture files must not replace consumer-owned
   `dnd_kit` truth.

## Consequences

Positive:

- Agents can begin bounded work without a missing database or CLI dependency.
- Work records scale with coordination and recovery needs instead of a single
  risk-lane process.
- Future core upgrades have explicit provenance, dry-run support, three-way
  merging, conflict stops, and local backups.
- Product and historical documentation is preserved.

Tradeoffs:

- Historical Harness documents describe commands that are unavailable unless
  the compatibility profile is explicitly installed.
- Existing story packets are no longer automatically updated for every new
  change.
- Core updates can report intentional consumer modifications because several
  managed templates are adapted to this repository.

## Follow-Up

- Run `scripts/bin/harness status` and `scripts/bin/harness doctor` when
  diagnosing core maintenance issues.
- Preview future core changes before activation and resolve any three-way merge
  conflicts without overwriting consumer-owned truth.
