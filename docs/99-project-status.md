---
status: active
last_reviewed: 2026-10-26
source_of_truth_for:
  - Current AI Platform implementation status and validation
depends_on:
  - 00-project-context.md
referenced_by: []
type: status
---

# AI Platform Status

Status documents are not architectural authority.

Working mode and agent continuation live in `docs/working-mode.md`.

## Current phase

Optional Deployer capability on the existing v1.2.x symlink/bootstrap
architecture. Version 1.3.0.

## Progress

- Shared Cursor rules, documentation contracts, and project bootstrap: in use
- Optional Deployer: capability-on-demand SSH/PHP deployment foundation
  for Laravel, Bedrock/Sage, Bedrock, and conventional WordPress.
  Bootstrap may prompt or honor `--with-deployer` / `--without-deployer`.
  Standalone installer: `scripts/install-deployer.sh`. Installing the
  stack does not deploy and does not authorize deployment. Canonical:
  `docs/contracts/features/deployer.md`, ADR 0007.
- Current-First Engineering and Framework-Native First: platform-wide in
  `00-platform.mdc`; Tailwind composition is the CSS specialization in
  `20-coding.mdc`
- Copy and Tailwind guardrails: generated public-facing copy must not
  use em dashes; Tailwind standard utilities/tokens are preferred over
  arbitrary values; project/platform rules outrank conflicting
  secondary skill/tool guidance. `scripts/check-guardrails.sh` is the
  mechanical DONE check for newly written or modified application
  sources (ADR 0006). Hallmark is not forked; its typography and CSS
  recipes do not reverse those rules.
- Roots/Radicle/Sage profile: Navi is the preferred navigation integration
  after Current-First verification. Greenfield baseline after Current-First
  verification: ACF Pro (structured fields, not a page builder), Keen
  Slider, and WPForms Lite as the default basic forms layer. Gravity
  Forms remains a valid project-specific choice, not the default.
  Page/menu provisioning is an explicit idempotent project-native
  operation driven by each project's contracts, not a universal sitemap.
- Roots upgrades and Roots security assessments use one procedure for
  every Bedrock, Sage, Radicle, Acorn, and Bud generation. Assessment
  is read-only until a stage is approved. The newest major is not the
  default target. Findings stay in the project's planning contract.
  Canonical: `docs/contracts/features/roots-upgrade.md`,
  `core/prompts/roots-upgrade.md`, ADR 0009.
- WordPress with Tailwind and `theme.json`: Tailwind tokens are the
  typography and color source of truth. `theme.json` presets alias
  those tokens. Editorial element styles stay scoped to the editor
  canvas and the published content region. Canonical rule:
  `.cursor/rules/36-wordpress-theme.mdc`. Roots/Radicle/Sage projects
  that use this combination follow that rule; it does not apply to
  other stacks.
- Two-layer browser QA policy: documented and wired into Laravel profile.
  Availability is not general authorization (`60-browser-qa`). Availability
  is also not justification for using a tool. Significant UI authorizes
  a bounded Mode B visual pass (`40-ui`). That pass is capability-aware:
  use the best available real-browser capability; do not report an
  interactive pass as Playwright execution. If Playwright is required
  but its browser binary is unavailable, report the gap instead of
  silently installing browsers or silently downgrading the claim.
  Meaningful motion receives
  proportionate review in that pass; it does not by itself authorize
  Mode A or performance profiling.
- Design stack: Impeccable and Hallmark are managed; `40-ui` routes UI
  work and loads one by default. Impeccable is primary for significant
  product/application UI. Hallmark is specialist expressive art
  direction. frontend-design, ui-ux-pro-max, and Superdesign remain
  retired. `40-ui` owns hard developer design constraints (no
  decorative sequential numbering, no em dashes in generated end-user
  copy, generous whitespace, product-specific hierarchy-driven design,
  task-first interaction, capable simplicity, and preserved user
  context) that outrank both skills. Cards are semantic containers that must earn
  grouping; unearned card grids remain prohibited. `40-ui` also covers
  purposeful imagery, art direction, responsive composition, and
  perceptible visual boundaries between adjacent semantic sections
  (not mechanical background alternation). Significant motion is a
  specialized UI concern, not a separate skill or harness animation
  dependency. Image generation for design exploration is owned by
  `40-ui`: settings are intentional and artifact-adaptive; generated
  images are references, not implementation truth; availability does
  not authorize use. A substantial redesign (major page or screen,
  multi-step flow, or substantial responsive refactor) requires an
  approved project-local review comp before application UI changes
  (`40-ui`, `core/prompts/ui-comp-approval.md`,
  `core/prompts/creative-direction.md`, ADR 0008). Creative discovery,
  including motion, happens before that comp. The agent infers
  established decisions and asks only when a consequential choice is
  still open. Subtle motion is the preferred recommendation when motion
  fits. The comp can carry the motion treatment and, when timing
  matters, a browser-openable preview. That is the same approval, not
  a second gate. GSAP and Higgsfield stay optional and are not harness
  dependencies. The comp is a review artifact. Creating it does not authorize deployment. Small
  polish, copy changes, and straightforward fixes do not use that gate.
- Capability-on-demand: external tools are not capability-by-default.
  Bootstrap does not install MCP servers or make additional MCPs
  required dependencies. Client-specific MCP configuration remains
  client-specific. Capability parity across agents is not the goal.
  Deployer follows the same principle: available, not required.
- Laravel Boost: diagnosed by bootstrap/doctor; not installed by the platform
- `doctor.sh`: implemented
- Existing-project reconciliation: bootstrap copies a draft
  `platform-reconciliation.md` for any existing project; Project
  Adoption (`core/prompts/project-adoption.md`) performs the analysis
  after bootstrap. Bootstrap does not analyze or migrate the app.
- First-time onboarding: `docs/getting-started.md` in the harness clone
  (clone → doctor → bootstrap → verify). Public landing: repository
  `README.md`. Adoption: `docs/adopting-projects.md`. LLM support seed:
  `docs/llm-support-prompt.md`. Public documentation is a landing page
  plus focused guides; `docs/README.md` remains the contract registry.
- Multi-agent adapters: `AGENTS.md` / `CLAUDE.md` point at
  `core/agent-core.md`; Cursor `.cursor/rules/` remains canonical.
  Hermes (Nous Research) consumes `AGENTS.md` and does not get
  `.hermes.md`. Capability matrix: `core/adapters/README.md`.
  Laravel Boost composition: `.ai/guidelines/ai-platform.md`.
- Work-item lifecycle: GitHub Issues, Pull Requests, and `gh` are the
  reference implementation of a provider-neutral capture-don't-expand
  workflow (`70-work-items`). `gh` is optional. Merge remains a
  developer approval boundary. Bootstrap does not install GitHub
  infrastructure or credentials.
- Agent continuation: `docs/working-mode.md` stores current working
  mode for fresh threads. Concise completion reporting is the default
  (`00-platform`, ADR 0005). Working mode is updated on mode
  transitions, not after every bounded task.
- Symlink architecture: unchanged in v1.3.0. Project-local `.ai/`
  portability remains deferred.
- Public submission protection: every project with a public contact,
  lead, quote, registration, comment, or similar endpoint includes
  server-side spam and abuse protection when that surface is built.
  Projects with no such surface record `not applicable`. Existing
  projects are inventoried during adoption and are not silently
  retrofitted. Canonical:
  `docs/contracts/features/spam-and-abuse-protection.md`. Bootstrap
  copies the project record and does not install protection.

## Validation

Run from the AI Platform repository:

```bash
scripts/doctor.sh
scripts/test-platform.sh
scripts/check-guardrails.sh
```

## Production readiness

- Existing Laravel apps still need a native Boost install (Composer approval)
  plus enabling `laravel-boost` in Cursor MCP settings
- Playwright Mode A remains a per-project implementation with dependency
  approval
- Optional Deployer remains unconfigured until the developer fills
  `deploy/hosts.yaml` and explicitly authorizes a deploy
- Re-running bootstrap on a newly bootstrapped project classifies it as
  existing because `docs/README.md` is present and may add a
  reconciliation draft. Documented limitation: `docs/maintaining.md`.
