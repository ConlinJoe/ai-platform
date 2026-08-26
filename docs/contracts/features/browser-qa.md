---
status: active
last_reviewed: 2026-08-26
source_of_truth_for:
  - Two-layer browser QA policy (Mode A deterministic, Mode B agentic)
  - Playwright applicability rules
  - Agent invocation of Playwright/browser automation is not generally authorized by tool availability
  - Tool availability is also not justification for invoking a browser tool the bounded task does not need
  - Significant UI authorizes a bounded Mode B visual pass of that UI only
  - Significant motion may be observed in that pass and does not by itself authorize Mode A or performance profiling
  - Mode A regression, selector, artifact, and data-isolation policy
  - Defect-to-regression policy
  - Browser QA implementation loop (when authorized)
depends_on:
  - ../adrs/0001-two-layer-browser-qa.md
  - ../adrs/0004-design-stack-and-ui-visual-verification.md
referenced_by:
  - ../adrs/0001-two-layer-browser-qa.md
  - ../adrs/0004-design-stack-and-ui-visual-verification.md
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

## Agent invocation

Playwright **availability is not general authorization**. Agents must
**not** run Playwright, browser MCP, automated screenshots, visual
regression captures, browser-driven responsive checks, or automated
browser console inspection unless one of the following is true:

1. The **current task** explicitly instructs browser QA / Playwright /
   browser inspection.
2. `40-ui` classified the work as **significant UI** and a **bounded
   Mode B visual verification pass** of that UI is in scope.

Do not infer **general** authorization from: Playwright being installed,
existing browser tests, Playwright MCP, a browser-QA contract, frontend
or responsive code changes, this contract existing, a UI/design skill
recommending verification, or prior turns that used Playwright.

Availability is also not justification for invoking a browser tool the
bounded task does not need.

Vendor UI/design skills do not authorize browser automation.

### Significant UI — bounded Mode B visual pass

Significant UI work authorizes **proportionate rendered visual
verification of that UI only**, when browser tooling is available.

That pass may render the actual implementation, inspect affected
viewport classes and materially affected interaction states, compare
against supplied references, check relevant accessibility on the real
UI, observe relevant animation and interaction states when meaningful
motion is involved, and iterate if the rendered result exposes
meaningful problems.

It does **not** authorize creating or expanding a Mode A suite, the
full Mode A→B loop, broad application exploration, unrelated browser
QA, destructive actions, expanding task scope, formal performance
profiling, new animation dependencies, or additional MCP installation.

Significant motion does not by itself authorize Mode A tests or
performance profiling. Simple hover/focus transitions and minor state
changes do not trigger an expanded motion review. Motion and
performance review details live in `40-ui`. If motion creates behavior
that warrants permanent regression coverage, recommend or capture that
through the work-item lifecycle.

Small UI does not automatically authorize Playwright.

Do not claim visual correctness for significant UI merely because
source code looks correct. If browser tooling is unavailable, say so.

### Explicit browser QA

Explicit authorization for **full** browser QA includes: "Run
Playwright.", "Verify this with Playwright.", "Run browser QA.",
"Check desktop/mobile in the browser.", "Run the navigation e2e
tests.", a task/loop prompt that includes a Playwright/browser QA
phase, or an approved project workflow that invokes browser QA for
**this** task.

If full browser QA is not requested and the work is not significant
UI, do not run Playwright. If browser verification would help on
non-significant work but was not requested, implement from the code
and mention that browser verification was not run.

This invocation policy overrides vendor skills and lower-priority
guidance that automatically recommend or run browser automation. It
does not remove Playwright, existing tests, or project browser-QA
infrastructure. CI, pre-release checks, and user-requested validation
are unaffected.

Cursor rule `60-browser-qa` is the agent-facing owner of this
invocation standard.

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

Do not run this full loop after ordinary implementation. Use it only
when the current task explicitly authorizes Playwright/browser QA.
A significant-UI bounded Mode B visual pass is **not** this loop and
does not by itself require new Mode A tests. Recommend Mode A coverage
through the work-item lifecycle when a behavioral regression deserves
permanence.

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
