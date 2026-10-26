---
status: accepted
last_reviewed: 2026-10-26
source_of_truth_for:
  - Decision that a substantial UI redesign requires an approved project-local review comp before application UI changes
  - Decision that creative discovery happens before that comp and does not add a prose-brief approval
  - Decision that a proposed motion treatment is reviewed inside the existing comp and is not a second approval gate
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
  - ../../../core/prompts/creative-direction.md
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
The checklist is `core/prompts/ui-comp-approval.md`. Creative discovery
and motion planning live in `core/prompts/creative-direction.md`.

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

Before that comp, resolve open creative choices, including motion,
through the existing `shape` path and
`core/prompts/creative-direction.md`. Infer established brand and
design-system facts. Ask only when a consequential choice is still
unresolved. Do not ask again once a direction is established. Small
UI does not use this discovery. Do not add a prose-brief approval.

When meaningful motion is proposed, the same review artifact carries
a concise motion treatment. A simple CSS entrance does not need its
own prototype. When timing or easing would materially change the
decision, the review experience includes a browser-openable preview
that does not modify application UI and does not add a project
dependency. Approval of the review comp includes the motion treatment
represented there. If the user approves the stills and rejects the
motion, revise only that treatment and obtain approval before
implementing the motion. That revision is not a second gate.

After approval, implementation and verification stay on the existing
path: framework-native implementation of the approved direction, then
the bounded Mode B pass and project checks. When motion is part of
the approved direction, that pass observes it. A static screenshot
does not prove motion quality.

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
- Add a mandatory creative-brief approval before the comp. Rejected.
  The comp is the decision the developer can see.
- Require a separate motion-approval document. Rejected. Timing that
  matters belongs in the same review experience.
- Require a motion prototype for every transition. Rejected. A simple
  CSS entrance can be described on the comp.
