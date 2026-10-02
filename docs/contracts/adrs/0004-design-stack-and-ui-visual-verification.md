---
status: accepted
last_reviewed: 2026-09-14
source_of_truth_for:
  - Decision that Impeccable and Hallmark are the managed design skills
  - Decision that Impeccable is primary for product/application UI and Hallmark is specialist art direction
  - Decision that 40-ui is the UI router and always-on design floor
  - Decision that significant UI authorizes a bounded Mode B visual pass
  - Decision that Mode B visual verification uses the best available real-browser capability, not Playwright specifically
  - Decision that developer design constraints live in 40-ui and outrank managed design skills
  - Decision that significant motion is a specialized UI concern with proportionate review, not a separate skill or Mode A authorization
  - Decision that generated design images are exploration/reference artifacts, not implementation truth
depends_on:
  - 0001-two-layer-browser-qa.md
  - ../features/browser-qa.md
referenced_by:
  - ../features/browser-qa.md
  - 0006-instruction-precedence-and-mechanical-guardrails.md
  - 0008-substantial-redesign-comp-approval.md
  - ../../../.cursor/rules/40-ui.mdc
  - ../../../.cursor/rules/60-browser-qa.mdc
type: adr
---

# ADR-0004: Routed design-skill stack and bounded UI visual verification

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

The September 2026 review evaluated the official Impeccable 4.3.1 skill.
Its Operate mode, product/design context separation, responsive and
hardening workflows, critique/audit/polish commands, and deterministic
detector materially exceed the former generalist stack for application
UI. Its expressive direction overlaps Hallmark, so explicit routing is
required.

## Decision

Managed design intelligence is **Impeccable plus Hallmark**, routed by
task. Do not load both by default.

Canonical ownership:

1. `40-ui` — UI principles, scope routing, reference protocol, review
   and accessibility floors
2. Impeccable — primary product/application UI shaping, implementation,
   critique, adaptation, hardening, polish, and technical audit
3. Hallmark — specialist expressive marketing, campaign/editorial,
   reference-study, and alternate art-direction work
4. Framework/project rules — implementation
5. Mode B — bounded rendered visual verification for significant UI,
   using the best available real-browser capability in the current
   environment (IDE-integrated browser, browser MCP, or equivalent).
   This is not Playwright execution.
6. Playwright Mode A — workflow/regression testing when separately
   authorized

Small UI does not automatically load a design skill or run Playwright.
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
contracts, approved briefs and visual references) are authoritative over
both skills. Impeccable's `PRODUCT.md`, `DESIGN.md`, and `.impeccable/`
records are optional focused design artifacts, not replacements for
project documentation contracts.

Do not restore `frontend-design`, `ui-ux-pro-max`, Superdesign, or
`ux-ui-agent-skills`. Impeccable subsumes the application workflow and
most useful reference guidance from those skills; Hallmark retains the
distinct art-direction role.

Developer design constraints are owned by `40-ui`, not by a skill.
They outrank Impeccable and Hallmark. Do not fork vendor content to
encode them. Mechanical checks for generated-copy em dashes and unnecessary
Tailwind arbitrary values live in
`../features/copy-and-tailwind-guardrails.md` (ADR 0006). Hallmark
typography or CSS recipes do not authorize reversing those rules.

Design philosophy: product-specific, spacious, hierarchy-driven,
task-first design. Avoid recognizable AI/template conventions. These
are usability and craft principles, not a native-platform imitation
guide.

Hard constraints in `40-ui` include: no decorative sequential numbering
as a visual device; no em dashes in generated end-user copy; no generic
AI/template decoration used only because it is familiar. Generous
whitespace is an intentional tool, not an AI-design tell. Prefer
typography, spacing, scale, alignment, grouping, composition, restrained
contrast, and content hierarchy before unearned cards, borders,
dividers, badges, icons, numbers, gradients, or decorative graphics.
Cards are semantic containers, not a prohibited pattern; they must earn grouping.
Simplicity is capable, not empty: remove unnecessary decisions, not
useful functionality. Interaction quality (progressive disclosure,
familiar patterns, preserved context, control proximity, and
touch-first targets where applicable) is part of the always-on floor.
Visual trends are not globally prescribed. Design skills may specialize
creative direction; they must not override project design systems,
approved visual references, accessibility, or these principles.
Imagery and responsive composition guidance also live in `40-ui`.
Adjacent semantic sections must remain visually distinguishable;
semantic section boundaries should also be perceptible visual
boundaries. This is not a mechanical alternating-background rule.
Significant motion follows the same product-specific philosophy as
static UI; decorative AI/template motion is challenged in `40-ui`.

Image generation for UI and product-design exploration is owned by
`40-ui`. It is not a new skill, MCP, or dependency. Generated design
images are exploration/reference artifacts, not the implementation
source of truth. The rendered product and the project's design system
remain authoritative. Image generation is capability-on-demand:
availability does not authorize or justify use. When it is used,
agents must choose settings intentionally and adapt them to the
artifact rather than relying on generic model defaults. Project design
decisions override generic image-model preferences. Image generation
must not replace framework-native implementation or the bounded Mode B
rendered-verification pass.

## Consequences

### Positive

- One primary application workflow and one distinct art-direction
  specialist instead of several overlapping generalists
- Significant UI is checked against rendered pixels
- Small UI stays cheap
- Multi-agent skill adapters expose the same two managed skills

### Negative

- Agents must classify UI scope; borderline cases need judgment
- The managed skill payload grows by about 2.1 MB
- Impeccable's launcher may download its pinned engine on first use;
  hooks and browser workflows remain separately authorized
- Visual verification still depends on an available real-browser
  capability; environments differ, and agents must report which
  verification level actually occurred

## Alternatives considered

- Keep Hallmark only — rejected; Impeccable adds a materially stronger
  product-UI workflow, persistent context model, hardening, critique,
  responsive adaptation, and deterministic detector
- Restore `frontend-design` and `ui-ux-pro-max` — rejected; their useful
  roles substantially overlap Impeccable and Hallmark, recreating
  conflicting instructions and avoidable context load
- Keep Superdesign as opt-in canvas — rejected; not MCP, hosted, and
  not a supported harness tool
- Auto-load multiple design skills — rejected; conflicting context
- Require explicit “run Playwright” for all visual checks — rejected;
  significant UI was completing from source alone
