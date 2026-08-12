---
status: active
last_reviewed: 2026-08-12
source_of_truth_for:
  - Two-layer browser QA policy (Mode A deterministic, Mode B agentic)
  - Playwright applicability rules
  - Mode A regression, selector, artifact, and data-isolation policy
  - Defect-to-regression policy
  - Browser QA implementation loop
depends_on:
  - ../adrs/0001-two-layer-browser-qa.md
referenced_by:
  - ../adrs/0001-two-layer-browser-qa.md
  - ../../../core/project-profiles/laravel-webapp.md
  - ../../../core/prompts/browser-qa-loop.md
  - ../../../.cursor/rules/60-browser-qa.mdc
  - ../../../mcp/playwright/README.md
type: feature
---

# Browser QA

Platform policy for browser-capable projects. Project-owned contracts
(commands, coverage lists, record-naming) belong in each application's
`docs/contracts/features/browser-qa.md`, using
`templates/docs/contracts/features/browser-qa.md`.

Laravel/Livewire specifics that are not universal browser policy live in
`core/project-profiles/laravel-webapp.md`.

## Applicability

Playwright Mode A is **expected** when the project matches a browser-capable
profile.

| Project kind | Playwright Mode A | Notes |
| --- | --- | --- |
| Laravel web application (`laravel-webapp`) | Expected | Browser UI is the product surface |
| AI Platform repository | Not applicable | No application UI |
| Libraries, CLIs, API-only services | Not applicable | No browser surface |
| Other stacks | Not required until a profile says so | Do not install Playwright indiscriminately |

`doctor.sh` warns when a Laravel web application lacks Playwright. It does
not require Playwright of other project types.

Mode B uses whatever browser MCP tooling is already available (typically
user-global Playwright MCP and/or browsermcp). Do not add those servers to
a project's `.cursor/mcp.json` merely to satisfy this policy.

## Two-layer model

### Mode A — deterministic Playwright regression

Project-owned Playwright specs. Repeatable browser workflows.

- Tests meaningful workflows and state transitions, not merely page loads.
- CRUD coverage is useful but insufficient by itself.
- Console and network failures are inspected.
- External integrations are safely faked or stubbed.
- Failures retain trace, screenshot, and video.
- Generated artifacts and auth state are gitignored.
- Prefer semantic role/label selectors. Add `data-testid` only where
  semantic selectors are unreliable or a stable automation contract is
  valuable. Do not litter production markup with test IDs.

### Mode B — agentic browser exploration

The agent uses available browser tooling/MCP interactively and behaves like
a real operator rather than replaying Mode A.

Explore realistic alternate paths, including:

- validation correction
- double submission
- browser Back
- cancel/reopen
- state transitions
- empty/sparse states
- failure/retry
- rerouting/reassignment where applicable
- unexpected navigation

Inspect console, network, and browser behavior.

## Defect → regression

A meaningful browser defect discovered by agentic QA should normally become
a deterministic Mode A regression test after it is fixed.

## Data isolation

- Identify test-owned records with deterministic, disposable naming.
- Clean up only test-owned data.
- Preserve rich seeded/demo development databases.
- Never wipe local/demo data to make tests pass.
- Dashboard and list assertions identify test-owned records; they must not
  rely on global seeded counts.
- Shared development queues must not be indiscriminately drained. Process
  only test-owned work.

## Core loop

```
IMPLEMENT
→ RUN APPLICATION TESTS
→ RUN MODE A
→ EXPLORE WITH MODE B
→ FIND DEFECTS
→ FIX
→ ADD REGRESSION COVERAGE
→ RE-RUN
→ REPEAT UNTIL GREEN
```

See `core/prompts/browser-qa-loop.md`.

## Artifacts to gitignore

When Mode A exists, ignore at least:

```
/test-results/
/playwright-report/
/blob-report/
/playwright/.cache/
```

Also ignore generated auth state (path is project-specific, commonly
`e2e/.auth/`).

## What this contract does not own

- Project spec files, helpers, and npm scripts
- Project-specific Artisan cleanup/fixture commands
- Domain coverage lists (CRM entities, etc.)
- Livewire/Flux helper implementations
