---
status: accepted
last_reviewed: 2026-08-12
source_of_truth_for:
  - Decision that Laravel Boost is project-native, not platform-owned MCP config
  - Decision that Boost must not be installed as a user-global Cursor MCP server
depends_on:
  - ../features/laravel-boost.md
referenced_by:
  - ../features/laravel-boost.md
  - ../../../core/project-profiles/laravel-webapp.md
  - ../../../mcp/laravel-boost/README.md
type: adr
---

# ADR-0002: Laravel Boost is project-native

## Status

Accepted

## Context

Laravel Boost is an MCP server that runs `php artisan boost:mcp` against a
specific application. User-global Cursor MCP (`~/.cursor/mcp.json`) cannot
bind that command to the correct project. Boost's own installer writes
`.cursor/mcp.json` (and related agent files) via `php artisan boost:install`.

The AI Platform previously mentioned Boost only as "when available" and
never bootstrapped or detected it. Empty `mcp/laravel-boost/` placeholders
existed. A Laravel app bootstrapped through the platform therefore had no
Boost MCP server, while user-global MCP showed unrelated browser tools.

## Decision

- Laravel web applications are expected to have Laravel Boost.
- The Laravel project owns Boost: `composer require laravel/boost --dev`
  and `php artisan boost:install`.
- The AI Platform enforces the capability (profile, bootstrap diagnosis,
  `doctor.sh`) and does **not** write or duplicate Boost MCP configuration.
- Boost is **not** added to user-global Cursor MCP.
- Browser MCP tools used for Mode B (Playwright MCP, browsermcp) may remain
  user-global; they are not project-bound the way Boost is.

Current Boost/Cursor behavior is defined by the installed `laravel/boost`
package and [Laravel Boost documentation](https://laravel.com/docs/boost).

## Consequences

### Positive

- No competing MCP config between the platform and Boost.
- Each Laravel app gets application-aware Boost tools and versioned docs.
- Missing Boost is diagnosable instead of silently optional.

### Negative

- Existing Laravel apps need a one-time native Boost install (Composer
  approval + `boost:install` + enabling the server in Cursor).
- Bootstrap cannot make Boost appear without a dependency change.

## Alternatives Considered

- User-global Boost MCP — rejected; `artisan boost:mcp` is project-specific.
- Platform-written `.cursor/mcp.json` — rejected; fights Boost's installer
  and duplicates ownership.
- Keep Boost optional — rejected; it is part of the standard Laravel
  development environment this platform expects.
