# Laravel Web Application Profile

## Purpose

This profile applies to standard Laravel web applications built using
the preferred development stack. It does not apply to Roots/Radicle/Sage
WordPress projects (`roots-radicle`).

## Technology Stack

Preferred stack (unversioned; subordinate to Current-First Engineering
in `00-platform` — establish installed or current stable versions before
implementation):

-   Laravel
-   Livewire
-   Blade
-   Tailwind CSS
-   Alpine.js
-   MariaDB

## Architecture

-   Follow Laravel conventions for the installed or intentionally
    selected ecosystem (Current-First Engineering in `00-platform`).
-   Follow Framework-Native First in `00-platform`.
-   Keep controllers thin.
-   Blade views render prepared data. Queries and data preparation belong
    outside the template (`21-stack-architecture`).
-   Place business logic in services or domain classes.
-   Keep models focused on persistence and relationships.
-   Prefer dependency injection.
-   Prefer existing patterns over introducing new ones when those
    patterns correctly use the installed stack.

## Development Principles

-   Keep solutions simple and maintainable.
-   Avoid unnecessary abstractions. Follow Framework-Native First
    before introducing wrappers or extra packages.
-   Make focused changes.
-   Do not perform unrelated refactoring.

## Laravel Boost

Laravel web applications are expected to use Laravel Boost.

- Install with Laravel's native flow: `composer require laravel/boost --dev`
  then `php artisan boost:install` (Composer changes need approval).
- Boost owns `.cursor/mcp.json` for the `laravel-boost` server. The AI
  Platform does not write that file and does not put Boost in user-global
  MCP.
- When Boost is available, use it as the primary source for framework
  guidance (search-docs, application-aware tools).
- When Boost is missing, diagnose it (see `docs/contracts/features/laravel-boost.md`)
  and continue with Current-First official docs — do not pretend Boost is
  present.

## Browser QA

This profile is **browser-capable**. Capability is not authorization.
Agent invocation of Mode A/B is not generally authorized by tool
availability. Significant UI authorizes a bounded Mode B visual pass of
that UI only (`40-ui`, `60-browser-qa`). Use the best available
real-browser capability for that pass; do not treat it as Playwright
execution. Do not run Playwright or
browser automation otherwise unless the current task explicitly
authorizes it.

When authorized, follow platform policy in
`docs/contracts/features/browser-qa.md` and the loop in
`core/prompts/browser-qa-loop.md`.

Maintain a project-owned `docs/contracts/features/browser-qa.md` for
commands, coverage, and data naming.

### Livewire and Blade

- Browser tests must account for Livewire synchronization. A generic
  `fill()` often does not update `wire:model`; prefer events that Livewire
  observes (then assert UI/state).
- Choose one validation boundary. HTML5 constraint validation can block
  Livewire-owned validation from running. If Livewire is the source of
  truth, do not let native browser validation swallow the flow.
- Validation errors must clear or update correctly as the user repairs
  fields.
- Browser-history resubmission is a real duplicate-creation path on create
  workflows; cover it in Mode A when the flow exists.
- Test status transitions and lifecycle workflows, not only CRUD.

### Data and queues

- Name disposable records so tests can find and delete only their own data.
- Cleanup must not touch seeded/demo rows.
- Preserve rich local/demo databases during development.
- Do not drain shared development queues. Process only test-owned jobs.
- Dashboard and list assertions must identify test-owned records, not
  global aggregate counts.
- Fake or stub external integrations (mail, CRMs, HTTP APIs) in browser
  tests.

### Selectors

Prefer semantic role/label selectors. Add `data-testid` only where those
are unreliable or a stable automation contract is valuable.

## Public submissions

When this application exposes a public submission surface, use Laravel
validation and rate limiting, and follow
`docs/contracts/features/spam-and-abuse-protection.md`.
Record applicability in `docs/contracts/features/public-submissions.md`.

## Documentation

Follow the `10-documentation` project rule.

Use contract-based documentation with `docs/README.md` as the dependency
graph. Maintain `docs/00-project-context.md` for ChatGPT context. Export
project AI context via `scripts/export-chatgpt-context.sh`.

## Optional Deployer

This profile may receive the harness-managed Deployer stack when the
developer selects it at bootstrap or runs `scripts/install-deployer.sh`.
That install is not a deploy. See
`docs/contracts/features/deployer.md` in the harness clone.
