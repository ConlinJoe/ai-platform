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
defect→regression, isolation principles) lives in the AI Platform:
`docs/contracts/features/browser-qa.md`.

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

Agentic exploration with available browser MCP. Do not replay Mode A.
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
