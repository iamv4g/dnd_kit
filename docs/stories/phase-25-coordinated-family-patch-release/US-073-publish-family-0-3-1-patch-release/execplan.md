# Exec Plan

## Goal

Prepare and verify the coordinated stable `0.3.1` pub.dev release for
`dnd_kit`, `dnd_kit_flutter`, and `dnd_kit_jaspr`, then document the exact
publish order and the remaining human-gated irreversible publish step.

## Scope

In scope:

- Confirm the repository package metadata and changelogs already align on
  `0.3.1`.
- Reuse the shared family verifier to prove workspace validation and package
  dry-runs.
- Record the publish order and final publish outcome in the story evidence.
- Keep the release packet connected to the feature stories that prepared this
  patch line (`US-070`, `US-071`, and `US-072`).

Out of scope:

- New runtime features beyond the already-landed `0.3.1` changes.
- Publishing any superseded package topology or legacy package name.
- Running the irreversible credentialed pub.dev publish inside this task.

## Risk Classification

Risk flags:

- External systems.
- Public contracts.
- Existing behavior.

Hard gates:

- External provider behavior (`pub.dev` publish).

## Work Phases

1. Discovery.
2. Design.
3. Validation planning.
4. Implementation.
5. Verification.
6. Harness update.

## Stop Conditions

Pause for human confirmation if:

- Package version direction becomes ambiguous.
- Validation requirements need to be weakened.
- pub.dev account state or package ownership blocks publishing in a way local
  dry-runs cannot resolve.
- The irreversible final publish step is about to run.
