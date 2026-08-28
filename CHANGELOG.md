# Changelog

## Unreleased

Public documentation for broader adoption. The root README is a landing
page. Canonical procedures live in `docs/getting-started.md`,
`docs/how-it-works.md`, `docs/adopting-projects.md`,
`docs/maintaining.md`, and `docs/llm-support-prompt.md`.

Mechanical copy and Tailwind guardrails. Generated public-facing copy
must not use em dashes (`—`, `&mdash;`, equivalent entities). Tailwind
implementations must prefer the standard utility scale and project
tokens over arbitrary values. Project and platform rules outrank
conflicting secondary skill, MCP, plugin, vendor, and tool guidance;
clear conflicts follow the higher-authority rule without asking, and
genuine ambiguity stops for clarification. Consuming projects and
agents run `scripts/check-guardrails.sh` on changed application sources
before reporting DONE. Lint, tests, and build passing do not imply
that check ran. Hallmark is not forked. See ADR 0006.

Fresh agent threads resume from `docs/working-mode.md` instead of a
large kickoff prompt. That file stores current working mode and
continuation instructions only; project context, status, ADRs, and
contracts remain authoritative. Working mode is updated on mode
transitions, not after every bounded task. Concise completion
reporting is the default. Orientation-only sessions can follow
`core/prompts/resume.md`. See ADR 0005.

Browser verification is capability-aware. Significant-UI Mode B visual
verification uses the best available real-browser capability in the
current environment, including an IDE-integrated browser when it can
render, navigate, interact, and inspect responsive layouts. That pass
is not Playwright execution. Playwright remains Mode A for repeatable
automation, existing specs, regression, CI, and explicitly required
Playwright runs. If Playwright is installed but its browser binary is
unavailable, agents must not silently install large browser
dependencies or silently downgrade the verification claim; they should
use an available real-browser capability for visual checks when
appropriate and report which level actually ran. Do not encode opening
an external Chrome window as the fallback.

Formalized two refinements of the current v1.2.0 architecture.
External tools are capability-on-demand, not capability-by-default:
tool availability is not authorization, and availability is also not
justification for using a tool. MCP servers keep a small default
footprint with a defined responsibility; additional MCPs are not
bootstrap dependencies, and client-specific MCP configuration is not
forced to parity across agents.
Significant motion is a specialized significant-UI concern with
proportionate motion and performance review. It does not add a motion
skill or animation dependency, does not trigger expanded QA for trivial
transitions, and does not by itself authorize Mode A tests or formal
performance profiling.

Refined `40-ui` card, imagery, responsive-composition, and section-separation
guidance.
Cards remain allowed as semantic containers; unearned decorative cards
and generic AI/SaaS card grids remain prohibited. Agents should consider
purposeful, art-directed imagery and mobile visual pacing rather than
defaulting to stacked text-only UI.
Adjacent semantic sections must remain visually distinguishable.
Semantic section boundaries should also be perceptible visual
boundaries. This is not a mechanical alternating-background rule:
whitespace or other compositional delineation can suffice, and agents
must not manufacture separation with unearned boxes, bands, or cards.

## 1.2.0 — 2026-08-23

Simplified the UI/UX design stack. Hallmark is the only managed design
skill. `frontend-design`, `ui-ux-pro-max`, and Superdesign were removed
from the harness.

`40-ui` now classifies UI work as small, significant, or exploration.
Hallmark loads only when that classification warrants it. Significant UI
authorizes a bounded Playwright Mode B visual pass of that UI; Mode A
workflow/regression tests remain separately authorized. Small UI does
not automatically load Hallmark or start a browser QA loop.

Significant UI is reviewed against a WCAG 2.2 AA accessibility floor and
a short rendered design-review protocol. References (screenshots, URLs,
named aesthetics) supply design language; they do not override the
current product. Framework-native implementation and an established
project design system remain authoritative.

Claude and Grok adapters expose only Hallmark. Bootstrap prunes retired
managed skills on re-run, adds `.hallmark/` to project gitignores, and
keeps Cursor, Grok Build, Codex, Claude Code, and Hermes supported.
Doctor and platform tests cover the new stack.

`40-ui` now encodes hard developer constraints against decorative
sequential numbering and em dashes in generated end-user copy, plus
anti-AI-template heuristics, generous whitespace, and
hierarchy-before-decoration. These preferences outrank Hallmark and
apply to new work in adopted projects without silently restyling
existing interfaces.
