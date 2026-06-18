# Exec Plan

## Goal

Determine whether horizontal auto-scroll can be added to `dnd_kit`,
`dnd_kit_flutter`, and `dnd_kit_jaspr` without forking the shared edge/velocity
math or regressing current vertical behavior, and leave behind the smallest
safe implementation plan if the answer is yes.

## Scope

In scope:

- Audit the current vertical-only auto-scroll math in `dnd_kit`.
- Audit the Flutter and Jaspr execution layers that currently consume that
  math.
- Compare the library gap against the app-owned Flutter reference in
  `examples/kanban_board/lib/horizontal_board_auto_scroll.dart`.
- Choose the preferred shared API direction for horizontal support.
- Define adapter-facing implications for Flutter and Jaspr.
- Document follow-up implementation slices and whether an ADR is required.

Out of scope:

- Shipping horizontal auto-scroll in any package.
- Final nested-scrollable or simultaneous two-axis behavior.
- Multi-container sortable work.
- Changing drag/drop semantics outside auto-scroll.

## Risk Classification

Risk flags:

- Public contracts.
- Cross-platform.
- Existing behavior.
- Weak proof.
- Multi-domain.

Hard gates:

- None.
  Five non-gate flags still place this work in the high-risk lane because it
  shapes shared API direction across core + Flutter + Jaspr.

## Work Phases

1. Discovery.
2. Design.
3. Validation planning.
4. Implementation slicing.
5. Verification planning.
6. Harness update.

## Stop Conditions

Pause for human confirmation if:

- The preferred shared API shape would require a breaking change instead of an
  additive one.
- Flutter and Jaspr need adapter-specific velocity math to behave acceptably.
- Horizontal document-viewport support or nested-scroll behavior introduces a
  product choice the current docs do not answer.
- Validation requirements would need to be weakened to make the feature viable.
