---
status: active
last_reviewed: 2026-08-21
source_of_truth_for:
  - Current AI Platform implementation status and validation
depends_on:
  - 00-project-context.md
referenced_by: []
type: status
---

# AI Platform Status

Status documents are not architectural authority.

## Current phase

Platform promotion of two-layer browser QA and Laravel Boost capability
enforcement (bootstrap + doctor). Version 1.1.1.

## Progress

- Shared Cursor rules, documentation contracts, and project bootstrap: in use
- Current-First Engineering and Framework-Native First: platform-wide in
  `00-platform.mdc`; Tailwind composition is the CSS specialization in
  `20-coding.mdc`
- Roots/Radicle/Sage profile: Navi is the preferred navigation integration
  after Current-First verification. Greenfield baseline after Current-First
  verification: ACF Pro (structured fields, not a page builder), Keen
  Slider, and WPForms Lite as the default basic forms layer. Gravity
  Forms remains a valid project-specific choice, not the default.
  Page/menu provisioning is an explicit idempotent project-native
  operation driven by each project's contracts, not a universal sitemap.
- Two-layer browser QA policy: documented and wired into Laravel profile.
  Agent invocation of Playwright/browser automation is opt-in
  (`60-browser-qa`); availability is not authorization.
- Laravel Boost: diagnosed by bootstrap/doctor; not installed by the platform
- `doctor.sh`: implemented
- Existing-project reconciliation: bootstrap copies a draft
  `platform-reconciliation.md` for any existing project; Project
  Adoption (`core/prompts/project-adoption.md`) performs the analysis
  after bootstrap. Bootstrap does not analyze or migrate the app.
- First-time onboarding: repository `README.md` (AI Development Harness:
  clone → prerequisites → verify → bootstrap → preferred agent → adopt)
- Multi-agent adapters: `AGENTS.md` / `CLAUDE.md` point at
  `core/agent-core.md`; Cursor `.cursor/rules/` remains canonical.
  Hermes (Nous Research) consumes `AGENTS.md` and does not get
  `.hermes.md`. Capability matrix: `core/adapters/README.md`.
  Laravel Boost composition: `.ai/guidelines/ai-platform.md`.

## Validation

Run from the AI Platform repository:

```bash
scripts/doctor.sh
scripts/test-platform.sh
```

## Production readiness

- Existing Laravel apps still need a native Boost install (Composer approval)
  plus enabling `laravel-boost` in Cursor MCP settings
- Playwright Mode A remains a per-project implementation with dependency
  approval
