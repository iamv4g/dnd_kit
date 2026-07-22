# Scripts

This directory contains project validation tools and Harness maintenance
artifacts.

## Harness Core Maintenance

The default Harness profile installs a checksum-verified, repository-local
maintenance binary at `scripts/bin/harness` on macOS/Linux or
`scripts/bin/harness.exe` on Windows. The binary is ignored by Git; its
versioned provenance and upstream base are tracked under `.harness-core/`.

```bash
scripts/bin/harness --version
scripts/bin/harness status
scripts/bin/harness doctor
scripts/bin/harness update --dry-run
scripts/bin/harness update
```

`status` reports the installed and embedded target versions plus intentionally
modified consumer files. `doctor` checks transaction recovery, three-way merge
support, provenance, and managed paths. Always preview an update before
activation.

To adopt a newer core release, review that immutable upstream release and rerun
its installer in merge mode with the agent shim refresh. The installer replaces
the local maintenance binary, invokes the binary's three-way update, stops
without writes on conflicts, and keeps timestamped recovery material under the
ignored `.harness-backup/` directory.

## Default Repository Workflow

`AGENTS.md` and `docs/WORKFLOW.md` define normal work. Questions and bounded
changes do not require a database, intake, story row, proof matrix, trace,
score, audit, or proposal. Use repository product docs, plans when needed,
decisions, code, tests, CI, and runtime evidence.

## Optional SQLite Compatibility

This repository retains the original `scripts/schema/` migrations and related
documents as historical or optional compatibility material. The default core
profile intentionally does not install `scripts/bin/harness-cli` or initialize
`harness.db`.

Only install and operate the compatibility profile when the user explicitly
requests it or an external orchestrator requires its versioned contract. Do
not infer that authority from the presence of old schemas, story packets, or
trace documents.

The upstream compatibility documentation and current installation instructions
live in the
[`repository-harness` project](https://github.com/hoangnb24/repository-harness).

## Project Validation

The `dnd_kit` workspace owns its executable proof:

```bash
dart run melos run validate
MELOS_DIFF=HEAD dart run melos run validate:affected
```

Use focused package tests while iterating. Use `MELOS_DIFF=origin/main` or
another shared base when the affected-only lane should compare against that
reference.
