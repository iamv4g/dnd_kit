# Execution Plan: Upgrade Harness To v0.1.4

Date: 2026-07-22

## Status

Completed

## Outcome

Upgrade this repository from the legacy mandatory SQLite Harness workflow to
the repository-centered Harness core at `harness-v0.1.4` without replacing
`dnd_kit` product truth or historical delivery evidence.

## Context

- Upstream release: `hoangnb24/repository-harness` tag `harness-v0.1.4`.
- Local authority: `AGENTS.md`, `README.md`, `docs/ARCHITECTURE.md`, and
  `docs/product/`.
- Legacy compatibility material: `docs/FEATURE_INTAKE.md`,
  `docs/CONTEXT_RULES.md`, `docs/TEST_MATRIX.md`, `docs/TRACE_SPEC.md`,
  `docs/stories/`, and `scripts/schema/`.

## Scope

In scope:

- Install the checksum-verified Harness core maintenance binary and its
  versioned three-way-update provenance.
- Adopt the compact agent shim and repository-centered workflow.
- Align local Harness, documentation-map, maintenance-command, and root README
  guidance with the new default workflow.
- Preserve product docs, architecture, decisions, stories, schemas, and all
  application code.

Out of scope:

- Installing or initializing the optional SQLite compatibility CLI/database.
- Rewriting historical product stories into execution plans.
- Changing `dnd_kit` product behavior or release validation.

## Approach

1. Preview and install the immutable `harness-v0.1.4` core in merge mode.
2. Adapt consumer-owned authority docs and record the workflow decision.
3. Validate provenance, diagnostics, update behavior, documentation links, and
   the final diff.

## Risks And Recovery

- Risk: upstream templates overwrite project-specific truth. Mitigation: use
  merge mode; the installer adopts existing files and only creates missing
  core files.
- Risk: old mandatory control-plane instructions remain authoritative.
  Mitigation: update the repository entrypoint and documentation map while
  labeling legacy surfaces as optional compatibility/history.
- Recovery: restore the installer-created `AGENTS.md` backup and revert the
  Git-visible core/docs changes. No product code or database is mutated.

## Progress

- [x] Confirm latest immutable upstream release and inspect its workflow.
- [x] Run a no-write installation preview.
- [x] Install the v0.1.4 core in merge mode.
- [x] Align local repository authority and compatibility boundaries.
- [x] Run focused validation and complete this plan.

## Decisions

- 2026-07-22: Use the default repository-centered core profile. Retain the old
  SQLite/story/trace material as optional compatibility and historical evidence
  rather than installing a new local control-plane database.
- 2026-07-22: Pin installation inputs to `harness-v0.1.4` instead of consuming
  mutable `main` content during the upgrade.

## Validation

- Focused proof: `scripts/bin/harness --version` reported `0.1.4`; `status`
  reported the core current with no missing managed files; `doctor` passed all
  provenance, transaction, merge, and path checks; `update --dry-run` preserved
  every managed path with no conflicts.
- Integration or end-to-end proof: not applicable because product behavior is
  unchanged.
- Repository-required checks: current authority contains no stale mandatory
  `harness-cli` guidance, all relative Markdown links in the changed authority
  documents resolve, and `git diff --check` passes.

## Result

Harness core `0.1.4` is installed with versioned three-way-update provenance and
the compact agent shim. The repository now uses the repository-centered
workflow and Git-native execution plans while preserving all `dnd_kit` product
docs, code, decisions, schemas, and historical story evidence. The SQLite
compatibility profile was intentionally not installed, and no product test was
run because no product source or behavior changed.
