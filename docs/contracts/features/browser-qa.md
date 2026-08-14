---
status: active
last_reviewed: 2026-08-14
source_of_truth_for:
  - Two-layer browser QA policy (Mode A deterministic, Mode B agentic)
  - Playwright applicability rules
  - Agent invocation of Playwright/browser automation is opt-in
  - Mode A regression, selector, artifact, and data-isolation policy
  - Defect-to-regression policy
  - Browser QA implementation loop (when authorized)
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

## Agent invocation (opt-in)

Playwright **availability is not authorization**. Agents must **not** run
Playwright, browser MCP, automated screenshots, visual regression
captures, browser-driven responsive checks, or automated browser console
inspection unless the **current task** explicitly instructs them to do so.

Do not infer authorization from: Playwright being installed, existing
browser tests, Playwright MCP, a browser-QA contract, frontend or
responsive code changes, this contract existing, a UI/design skill
recommending verification, or prior turns that used Playwright.

Explicit authorization includes: "Run Playwright.", "Verify this with
Playwright.", "Run browser QA.", "Check desktop/mobile in the browser.",
"Run the navigation e2e tests.", a task/loop prompt that includes a
Playwright/browser QA phase, or an approved project workflow that invokes
browser QA for **this** task.

If browser verification would help but was not requested, do not run it.
Implement from the code and briefly mention that browser verification was
not run. If the task cannot be completed correctly without browser
interaction, say so rather than silently invoking it.

This invocation policy overrides vendor skills and lower-priority
guidance that automatically recommend or run browser automation. It does
not remove Playwright, existing tests, or project browser-QA
infrastructure. CI, pre-release checks, and user-requested validation
are unaffected.

Cursor rule `60-browser-qa` is the agent-facing owner of this invocation
standard.

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

When authorized, the agent uses available browser tooling/MCP interactively
and behaves like a real operator rather than replaying Mode A.

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

## Core loop (when authorized)

Do not run this loop after ordinary implementation. Use it only when the
current task explicitly authorizes Playwright/browser QA.

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
