---
status: active
last_reviewed: 2026-08-23
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

Design-stack simplification: Hallmark-only UI intelligence, `40-ui` scope
routing, and bounded significant-UI Mode B visual verification.
Version 1.2.0.

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
  Availability is not general authorization (`60-browser-qa`). Significant
  UI authorizes a bounded Mode B visual pass (`40-ui`).
- Design stack: Hallmark is the only managed design skill; `40-ui` routes
  UI work. frontend-design, ui-ux-pro-max, and Superdesign were removed
  from the harness.
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
- Work-item lifecycle: GitHub Issues, Pull Requests, and `gh` are the
  reference implementation of a provider-neutral capture-don't-expand
  workflow (`70-work-items`). `gh` is optional. Merge remains a
  developer approval boundary. Bootstrap does not install GitHub
  infrastructure or credentials.

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
