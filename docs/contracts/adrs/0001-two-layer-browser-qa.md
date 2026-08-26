---
status: accepted
last_reviewed: 2026-08-26
source_of_truth_for:
  - Decision to use a two-layer (Mode A / Mode B) browser QA model
  - Decision that Playwright is profile-applicable, not universal
  - Decision that Mode B uses the best available real-browser capability, not one vendor interface
depends_on:
  - ../features/browser-qa.md
referenced_by:
  - ../features/browser-qa.md
  - 0004-design-stack-and-ui-visual-verification.md
  - ../../../core/project-profiles/laravel-webapp.md
type: adr
---

# ADR-0001: Two-layer browser QA

## Status

Accepted

## Context

Browser-capable applications need regression coverage that PHPUnit/feature
tests cannot provide: real browser behavior, Livewire/UI synchronization,
history, validation repair, and operator-like exploration. A proven Laravel
Livewire implementation used two complementary layers. Playwright should not
be required of every repository (this platform, libraries, CLIs, API-only
apps).

## Decision

Browser-capable project profiles use a two-layer model:

- **Mode A** — project-owned deterministic Playwright regression.
- **Mode B** — agentic browser exploration with the best available
  real-browser capability in the current environment (IDE-integrated
  browser, browser MCP, or equivalent). Mode B is not Playwright
  execution.

A meaningful defect found in Mode B should normally become a Mode A
regression test.

Playwright Mode A is required only where a project profile says the project
is browser-capable. The Laravel web application profile is browser-capable.
The AI Platform repository itself is not.

When agents invoke Mode A or Mode B is an invocation policy owned by the
feature contract. Availability is not general authorization. Agents run
browser automation only when:

1. The current task explicitly authorizes Playwright/browser QA, or
2. `40-ui` classified the work as significant UI and a bounded Mode B
   visual pass of that UI is in scope (`0004-design-stack-and-ui-visual-verification.md`).

Significant UI does not authorize a Mode A suite or the full Mode A→B
loop. An interactive real-browser pass must not be reported as
Playwright execution. Policy details live in
`docs/contracts/features/browser-qa.md`.

## Consequences

### Positive

- Repeatable regression without treating agent exploration as the suite.
- Defects discovered interactively are not lost.
- Non-browser repositories are not forced onto Playwright.
- Visual verification can use the environment's available real-browser
  capability without pretending it ran Playwright.

### Negative

- Browser-capable projects take on Playwright as a project dependency when
  the suite is introduced (requires approval under Safety rules).

## Alternatives Considered

- Playwright for every repository — rejected; not all projects have a UI.
- Mode B only — rejected; exploration is not deterministic regression.
- Dusk as the platform default — rejected; the proven implementation used
  Playwright, and Mode B uses available real-browser capability rather
  than a Dusk-specific driver.
- Treat an IDE-integrated or manual browser pass as Playwright
  execution — rejected; verification claims must name the level that
  actually ran.
- Encode "open Chrome" as the universal fallback — rejected;
  environments differ, and an integrated browser may already provide
  equivalent interactive visual verification.
