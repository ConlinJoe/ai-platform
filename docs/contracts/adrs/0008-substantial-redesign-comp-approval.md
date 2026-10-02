---
status: accepted
last_reviewed: 2026-10-02
source_of_truth_for:
  - Decision that a substantial UI redesign requires an approved project-local review comp before application UI changes
  - Decision that the comp is a review artifact and does not authorize deployment
  - Decision that the gate uses the existing shape/new-work router and does not fork vendor skills
depends_on:
  - 0004-design-stack-and-ui-visual-verification.md
  - ../features/browser-qa.md
referenced_by:
  - ../../../.cursor/rules/40-ui.mdc
  - ../../../.cursor/rules/60-browser-qa.mdc
  - ../../../.cursor/rules/00-platform.mdc
  - ../../../core/agent-core.md
  - ../../../core/prompts/ui-comp-approval.md
type: adr
---

# ADR-0008: Approve the comp before a substantial UI redesign

## Status

Accepted

## Context

`40-ui` already separates small UI from significant UI, routes
Impeccable and Hallmark, and authorizes a bounded Mode B pass after
implementation. Impeccable `shape` discovers a brief and stops before
code. `new-work` chooses a visual world only when one is actually open.
It may produce image comps under `.impeccable/mocks/`, or skip comps on
a code-led path.

Those mechanisms did not require a stable, browser-viewable review of
the key screens and states before application UI changed. A clear
direction, a temporary decision page, or a skill default could be
treated as permission to edit the product.

## Decision

A substantial redesign requires a project-local review comp and
explicit user approval before any application UI change.

Substantial means a major page or screen redesign, a new or reworked
multi-step flow, or a substantial responsive refactor. Small polish,
copy changes, straightforward fixes, and local additions that inherit
an established screen do not use this gate.

The procedure lives in `.cursor/rules/40-ui.mdc` (Substantial redesign).
The checklist is `core/prompts/ui-comp-approval.md`.

The gate uses the existing skill router and project design authority.
`shape` remains discovery. `new-work` remains the visual-world path
when that reference already applies. This decision does not add a
second design process, skill, or canvas. Do not encode the gate by
forking Impeccable or Hallmark.

The comp is a review artifact at `design-reviews/<slug>/index.html`
unless the project already names a review directory. It shows the key
screens and relevant states at mobile and desktop sizes, including
keyboard-open when the flow has it. It is not production source.
Generating it does not authorize deployment, a dependency change, or a
commit.

After approval, implementation and verification stay on the existing
path: framework-native implementation of the approved direction, then
the bounded Mode B pass and project checks.

An explicit user instruction to implement without a comp outranks this
gate. Skill defaults do not.

## Consequences

### Positive

- The user can review behavior at both sizes before application code changes
- The artifact stays in the project, outside the chat session
- Small UI stays on the existing cheap path

### Negative

- Substantial redesigns take an approval round before coding
- Agents must classify scope; a structural change that is hard to reverse uses the gate

## Alternatives considered

- Require the gate for every significant UI task. Rejected. Isolated
  components and token work do not need a multi-state review board.
- Treat Impeccable image comps or the code-led path as sufficient.
  Rejected. Those artifacts are not a stable review of states at both
  sizes, and code-led skips the visual stop.
- Fork `shape` or `new-work` to add the stop. Rejected. The workflow
  belongs in `40-ui`, which already outranks the skills.
- Host the comp only in an agent store or a temporary server. Rejected.
  The user needs a project path that opens in a regular browser.
