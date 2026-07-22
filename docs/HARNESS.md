# Harness

Harness makes this repository legible and operable to coding agents while
keeping `dnd_kit` product truth in the repository itself. The installed core is
based on upstream `repository-harness` release `harness-v0.1.4`.

The canonical task flow is in `docs/WORKFLOW.md`.

## Mental Model

```text
human intent
  -> compact repository map
  -> relevant product and architecture truth
  -> implementation inside documented boundaries
  -> executable or observable validation
  -> Git-visible result and lasting decisions when warranted
```

The goal is reliable execution with minimal process overhead. A Harness record
is useful only when it improves understanding, coordination, proof, or
recovery.

## Core Responsibilities

### Repository Map

`AGENTS.md` is the stable entrypoint. It points to the workflow and
project-specific authority without duplicating the full repository manual.

### Repository Knowledge

Retrieve knowledge progressively:

- current product behavior: `README.md` and `docs/product/`;
- package boundaries: `docs/ARCHITECTURE.md`;
- lasting choices: `docs/decisions/`;
- complex work in progress or retained history: `docs/plans/`;
- implementation truth: packages, examples, website, tests, CI, and runtime
  signals; and
- maintenance commands: `scripts/README.md`.

Historical specifications and story packets can explain why code exists, but
current product docs and executable behavior take precedence when they differ.

### Application Legibility

Validation should exercise the actual affected behavior. Use focused Dart,
Flutter, or Jaspr tests while developing and the Melos validation lanes for
workspace-wide claims. Do not invent generic commands or treat manually filled
process fields as product proof.

### Mechanical Invariants

Keep important repeatable boundaries in code, tests, analyzers, and CI. In this
repository those include the pure-Dart core boundary, peer Flutter/Jaspr
adapters, framework-free shared contracts, package API tests, and release
validation.

### Durable Planning

Bounded single-session work uses an ephemeral plan. Create one evolving file
under `docs/plans/active/` when work spans sessions, coordinates contributors,
has meaningful ordering or dependencies, needs explicit recovery, or would be
unsafe to resume from a final diff alone.

Keep progress, task-local decisions, risks, recovery, and validation in that
one file. Move it to `docs/plans/completed/` only after recording the verified
result. Promote a choice into `docs/decisions/` only when future work must
inherit it independently.

## Default Request Flows

### Read-Only

Answers, explanations, reviews, diagnoses, plans, and status reports inspect
only the material needed for an evidence-backed response. Discovery does not
authorize repository or Harness mutation.

### Bounded Change

Restate the observable outcome, inspect relevant truth and existing proof, make
the smallest coherent change, run behavior-appropriate validation, and report
the result. No database, intake row, story row, proof flag, or trace is
required.

### Durable Planned Change

Create or resume one active plan, update it as evidence changes the approach,
implement in coherent groups, validate the outcome, promote lasting decisions,
and move the completed plan to history.

### Human Judgment

Pause before edits when externally observable policy lacks repository
authority, materially different product choices remain open, the action is
difficult to recover, validation would be weakened, or the request does not
authorize the needed action.

## Source Hierarchy

```text
explicit user intent and accepted product direction
  -> current product contract
  -> current architecture and durable decisions
  -> active execution plan for complex work
  -> implementation, tests, CI, and observable runtime behavior
  -> completed plans, stories, and historical evidence
```

When sources conflict, prefer current accepted behavior and executable evidence
over historical planning material. Correct or clearly demote stale material
instead of creating another parallel source of truth.

## Core Maintenance

The repository tracks core provenance and the exact upstream base under
`.harness-core/`. The local platform binary at `scripts/bin/harness` supports:

```bash
scripts/bin/harness --version
scripts/bin/harness status
scripts/bin/harness doctor
scripts/bin/harness update --dry-run
scripts/bin/harness update
```

Core updates use a three-way merge between the installed upstream base,
consumer changes, and the new upstream payload. They stop without writes on
conflict and create recovery backups before activation. Re-run the reviewed,
immutable upstream installer to replace the maintenance binary when adopting a
new release.

## Optional Compatibility Material

The earlier SQLite control plane is retained for historical state and for an
external orchestrator that explicitly selects it. Its references include:

- `docs/FEATURE_INTAKE.md`;
- `docs/CONTEXT_RULES.md`;
- `docs/TEST_MATRIX.md`;
- `docs/TRACE_SPEC.md`;
- `docs/HARNESS_BACKLOG.md`;
- `docs/HARNESS_COMPONENTS.md`;
- `docs/HARNESS_MATURITY.md`;
- `docs/stories/`; and
- `scripts/schema/`.

Those documents do not make SQLite intake, story, matrix, trace, score, audit,
or proposal operations mandatory. The default core profile deliberately does
not install `scripts/bin/harness-cli` or initialize `harness.db`.

## Completion

A change is complete only when the requested result exists or the blocker is
explicit, relevant repository truth remains current, behavior-appropriate proof
has passed or its absence is disclosed, and any required active plan records
the outcome. Final reports separate verified facts, limitations, and work not
attempted.

## Consumer Boundary

Harness does not choose the application stack or replace consumer-owned truth.
The `dnd_kit` package architecture, product contract, validation commands, and
historical decisions remain owned by this repository.
