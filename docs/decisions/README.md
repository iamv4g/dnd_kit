# Decisions

Decision records preserve lasting product, architecture, data, security,
compatibility, and validation choices that future work must inherit.

Use `docs/templates/decision.md` when adding a new decision.

Add a decision when:

- A locked technical choice changes.
- A product rule changes meaningfully.
- A validation requirement is added, removed, or weakened.
- Auth, authorization, data ownership, audit/security, or API behavior changes.
- The source-of-truth hierarchy changes.

Keep task-local choices in the active execution plan. The optional SQLite
compatibility layer is not required to make a Markdown decision durable.

The current Harness workflow transition is recorded in
`0023-repository-centered-harness-workflow.md`. Earlier Harness decisions remain
useful migration history; product and package decisions continue from `0007`.
