---
status: draft
last_reviewed: YYYY-MM-DD
source_of_truth_for:
  - This project's Playwright Mode A commands, coverage, and data naming
  - This project's Mode B notes and cleanup procedure
depends_on:
  - contracts/foundational/architecture.md
referenced_by: []
type: feature
---

# Browser QA

Project-owned browser QA contract. Platform policy (applicability, Mode A/B,
invocation, bounded significant-UI visual pass, defect→regression, isolation)
lives in the AI Platform: `docs/contracts/features/browser-qa.md`.

Agent invocation of the full Mode A/B loop is opt-in. Significant UI
work authorizes a bounded Mode B visual pass of that UI only
(`.cursor/rules/40-ui.mdc`, `.cursor/rules/60-browser-qa.mdc`). That
pass uses the best available real-browser capability and is not
Playwright execution. Do not
run Playwright or browser automation otherwise unless the current task
explicitly authorizes it. Meaningful motion may be observed in that
pass; it does not by itself authorize Mode A tests or performance
profiling.

Fill this file from **this** project's reality. Delete sections that do not
apply. Do not copy another application's specs, helpers, or domain coverage.

## Applicability

This project is browser-capable: yes / no.

If no, state why Mode A is not used and stop.

## Mode A

- Spec location:
- Command:
- Base URL / credentials (never production):

## Mode B

Agentic exploration with the best available real-browser capability
(IDE-integrated browser, browser MCP, or equivalent). Do not replay
Mode A. Do not report an interactive pass as Playwright execution.
Meaningful defects become Mode A coverage.

## Data isolation

- Test-owned record naming:
- Cleanup command or procedure (deletes **only** test-owned data):
- Seeded/demo data that must be preserved:
- Queue/job rule (do not drain unrelated work):

## Artifacts

Confirm gitignore includes Playwright output and generated auth state.

## Coverage

List workflows and lifecycle transitions this project actually owns — not
generic CRUD-only page loads.

## Laravel / Livewire (if applicable)

Follow `core/project-profiles/laravel-webapp.md` for Livewire sync,
validation boundaries, history resubmission, and selector guidance.
