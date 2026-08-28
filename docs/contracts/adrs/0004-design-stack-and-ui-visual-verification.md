---
status: accepted
last_reviewed: 2026-08-28
source_of_truth_for:
  - Decision that Hallmark is the only managed design skill
  - Decision that 40-ui is the UI router and always-on design floor
  - Decision that significant UI authorizes a bounded Mode B visual pass
  - Decision that Mode B visual verification uses the best available real-browser capability, not Playwright specifically
  - Decision that developer design constraints live in 40-ui and outrank Hallmark
  - Decision that significant motion is a specialized UI concern with proportionate review, not a separate skill or Mode A authorization
depends_on:
  - 0001-two-layer-browser-qa.md
  - ../features/browser-qa.md
referenced_by:
  - ../features/browser-qa.md
  - 0006-instruction-precedence-and-mechanical-guardrails.md
  - ../../../.cursor/rules/40-ui.mdc
  - ../../../.cursor/rules/60-browser-qa.mdc
type: adr
---

# ADR-0004: Hallmark-only design stack and bounded UI visual verification

## Status

Accepted

## Context

The harness previously loaded overlapping design skills (Hallmark,
frontend-design, ui-ux-pro-max, Superdesign) from `40-ui`, while
browser QA invocation forbade rendered inspection unless the developer
explicitly said to run Playwright. That produced conflicting taste
guidance and allowed significant UI to be declared complete from source.

Superdesign was a skill plus hosted CLI/canvas, not an MCP. It is not
part of the supported harness.

## Decision

Managed design intelligence is **Hallmark only**.

Canonical ownership:

1. `40-ui` — UI principles, scope routing, reference protocol, review
   and accessibility floors
2. Hallmark — on-demand design intelligence for significant UI
3. Framework/project rules — implementation
4. Mode B — bounded rendered visual verification for significant UI,
   using the best available real-browser capability in the current
   environment (IDE-integrated browser, browser MCP, or equivalent).
   This is not Playwright execution.
5. Playwright Mode A — workflow/regression testing when separately
   authorized

Small UI does not automatically load Hallmark or run Playwright.
Significant UI authorizes a **bounded Mode B visual pass of that UI
only**. That pass is not Mode A, not the full Mode A→B loop, and not
general browser QA. Tool availability remains insufficient for unrelated
browser automation. Tool availability is also not justification for
using a tool the bounded task does not need.

Meaningful motion and animation are a specialized concern within
significant UI. They receive proportionate motion and performance
review when they are part of the work. They do not add a motion skill,
animation dependency, or MCP to the harness. Simple hover/focus
transitions do not trigger an expanded motion review. Significant
motion does not by itself authorize Mode A tests or formal performance
profiling.

Project-owned design systems (tokens, theme, components, design
contracts, `design.md`) are authoritative over Hallmark. Exploration
uses written directions, not a hosted canvas.

Do not install `ux-ui-agent-skills` or restore the removed skills.

Developer design constraints are owned by `40-ui`, not by Hallmark.
They outrank Hallmark. Do not fork Hallmark vendor content to encode
them. Mechanical checks for generated-copy em dashes and unnecessary
Tailwind arbitrary values live in
`../features/copy-and-tailwind-guardrails.md` (ADR 0006). Hallmark
typography or CSS recipes do not authorize reversing those rules.

Design philosophy: product-specific, spacious, hierarchy-driven design.
Avoid recognizable AI/template conventions.

Hard constraints in `40-ui` include: no decorative sequential numbering
as a visual device; no em dashes in generated end-user copy; no generic
AI/template decoration used only because it is familiar. Generous
whitespace is an intentional tool, not an AI-design tell. Prefer
typography, spacing, scale, alignment, composition, contrast, and
content hierarchy before unearned cards, borders, dividers, badges,
icons, numbers, gradients, or decorative graphics.
Cards are semantic containers, not a prohibited pattern; they must earn grouping.
Imagery and responsive composition guidance also live in `40-ui`.
Adjacent semantic sections must remain visually distinguishable;
semantic section boundaries should also be perceptible visual
boundaries. This is not a mechanical alternating-background rule.
Significant motion follows the same product-specific philosophy as
static UI; decorative AI/template motion is challenged in `40-ui`.

## Consequences

### Positive

- One taste system instead of several overlapping ones
- Significant UI is checked against rendered pixels
- Small UI stays cheap
- Multi-agent skill adapters expose only Hallmark

### Negative

- Agents must classify UI scope; borderline cases need judgment
- Visual verification still depends on an available real-browser
  capability; environments differ, and agents must report which
  verification level actually occurred

## Alternatives considered

- Keep Superdesign as opt-in canvas — rejected; not MCP, hosted, and
  not a supported harness tool
- Auto-load multiple design skills — rejected; conflicting context
- Require explicit “run Playwright” for all visual checks — rejected;
  significant UI was completing from source alone
