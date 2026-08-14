---
status: accepted
last_reviewed: 2026-08-14
source_of_truth_for:
  - Decision to use a two-layer (Mode A / Mode B) browser QA model
  - Decision that Playwright is profile-applicable, not universal
depends_on:
  - ../features/browser-qa.md
referenced_by:
  - ../features/browser-qa.md
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
- **Mode B** — agentic browser exploration with available browser MCP tooling.

A meaningful defect found in Mode B should normally become a Mode A
regression test.

Playwright Mode A is required only where a project profile says the project
is browser-capable. The Laravel web application profile is browser-capable.
The AI Platform repository itself is not.

When agents invoke Mode A or Mode B is an invocation policy owned by the
feature contract: opt-in unless the current task explicitly authorizes it.
Capability, installation, and MCP availability are not authorization.

Policy details live in `docs/contracts/features/browser-qa.md`.

## Consequences

### Positive

- Repeatable regression without treating agent exploration as the suite.
- Defects discovered interactively are not lost.
- Non-browser repositories are not forced onto Playwright.

### Negative

- Browser-capable projects take on Playwright as a project dependency when
  the suite is introduced (requires approval under Safety rules).

## Alternatives Considered

- Playwright for every repository — rejected; not all projects have a UI.
- Mode B only — rejected; exploration is not deterministic regression.
- Dusk as the platform default — rejected; the proven implementation used
  Playwright, and Mode B already uses Playwright-oriented browser tooling.
