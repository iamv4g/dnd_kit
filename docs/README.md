# Documentation Map

Start with the smallest current map. Retrieve historical or optional
compatibility material only when the task needs it.

## Current Authority

- `WORKFLOW.md`: canonical request, planning, judgment, validation, and
  completion flow.
- `HARNESS.md`: how the repository-centered Harness applies to `dnd_kit`.
- `ARCHITECTURE.md`: package layers and dependency boundaries.
- `product/`: current product behavior, API principles, examples standard, and
  release direction.
- `decisions/`: lasting product, architecture, compatibility, and validation
  choices.
- Project code, tests, CI, examples, website, and runtime signals: executable
  and observable truth.

## Working Memory

- `plans/active/`: one evolving plan for work that genuinely needs durable
  memory.
- `plans/completed/`: retained migration and execution history after proof.
- `templates/exec-plan.md`: durable-plan template.
- `templates/decision.md`: lasting-decision template.

Bounded work uses an ephemeral plan and does not require a story packet or
control-plane record.

## Product History

- `stories/`: delivery packets and validation notes from the earlier Harness
  workflow. They remain useful history but are not mandatory for new work.
- `SPEC.md` and `SPEC_JASPR.md`: original seed specifications. Current product
  docs and executable behavior take precedence.
- `decisions/0001` through `0006`: early Harness evolution history.
- `decisions/0007` onward: product, package, release, and current workflow
  decisions.

## Optional SQLite Compatibility

The following files describe the older control-plane workflow and are read only
when an external orchestrator or an explicit maintenance task selects it:

- `FEATURE_INTAKE.md`;
- `CONTEXT_RULES.md`;
- `TEST_MATRIX.md`;
- `TRACE_SPEC.md`;
- `HARNESS_BACKLOG.md`;
- `HARNESS_COMPONENTS.md`;
- `HARNESS_MATURITY.md`;
- `templates/story.md`, `templates/high-risk-story/`, and
  `templates/validation-report.md`; and
- `../scripts/schema/`.

The default Harness core does not install `scripts/bin/harness-cli` or create a
local database. These compatibility references cannot make their lifecycle
mandatory for an ordinary repository task.

## Core Installation State

- `.harness-core/manifest.json`: installed core version and managed-path
  hashes.
- `.harness-core/base/`: exact upstream bytes used for safe three-way updates.
- `../scripts/README.md`: maintenance commands and compatibility boundary.

The root README and architecture remain consumer-owned and are not replaced by
upstream Harness templates.
