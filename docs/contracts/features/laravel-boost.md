---
status: active
last_reviewed: 2026-08-14
source_of_truth_for:
  - Laravel Boost capability policy for the AI Platform
  - Boost detection levels used by bootstrap and doctor
  - New vs existing Laravel bootstrap behavior for Boost
depends_on:
  - ../adrs/0002-laravel-boost-ownership.md
referenced_by:
  - ../adrs/0002-laravel-boost-ownership.md
  - ../../../core/project-profiles/laravel-webapp.md
  - ../../../mcp/laravel-boost/README.md
  - ../../../mcp/README.md
type: feature
---

# Laravel Boost capability

The AI Platform requires Laravel Boost for Laravel web applications and
refuses to own Boost's MCP configuration.

Authoritative installer behavior: installed `laravel/boost` package and
[Laravel Boost docs](https://laravel.com/docs/boost).

## Ownership

| Concern | Owner |
| --- | --- |
| Composer package `laravel/boost` | The Laravel project (`--dev`) |
| MCP server registration | `php artisan boost:install` → `.cursor/mcp.json` |
| Guidelines / skills (`AGENTS.md`, `.cursor/skills`) | Boost installer / `boost:update` |
| Capability expectation and diagnosis | AI Platform (profile, bootstrap, doctor) |
| User-global Cursor MCP | Browser tools only — never Boost |

Do not hand-write a platform copy of Boost's MCP entry. Do not add Boost to
`~/.cursor/mcp.json`.

## Detection levels

`doctor.sh` and bootstrap report these independently:

| Level | Meaning |
| --- | --- |
| Declared | `laravel/boost` in `composer.json` (`require` or `require-dev`) |
| Installed | `vendor/laravel/boost` present |
| Configured | `.cursor/mcp.json` or `.mcp.json` contains `laravel-boost` |
| Artisan-discoverable | `artisan` exists and Boost is installed (command `boost:mcp`) |

Cursor's MCP enable-toggle is not filesystem-detectable. After configuration,
the developer must enable `laravel-boost` in Cursor MCP settings.

## Diagnosis

| State | Doctor | Action |
| --- | --- | --- |
| Not Laravel | Skip | — |
| Package missing | FAIL | `composer require laravel/boost --dev` then `php artisan boost:install` (approval required for Composer) |
| Declared, vendor missing | FAIL | `composer install` |
| Installed, MCP missing | FAIL | `php artisan boost:install --mcp` |
| Declared + installed + configured | OK | Enable in Cursor if toggled off |

## New-project bootstrap

After linking platform rules into a new Laravel app:

1. Detect Laravel via `composer.json`.
2. Do **not** run Composer or `boost:install` (dependency + native installer).
3. Report Boost as missing with the native install steps.
4. Continue bootstrap of rules, docs templates, and skills.

## Existing-project bootstrap

Same detection. Do not silently install Boost. Do not overwrite Boost-owned
files (`AGENTS.md`, `.cursor/mcp.json`, `.cursor/skills` published by Boost).

Record the gap in the bootstrap report and, when creating
`docs/contracts/foundational/platform-reconciliation.md`, list missing Boost
as an open deviation — not as an accepted difference.

## Relationship to browser QA

Boost MCP is not Mode A and not a substitute for Playwright. When Mode B
is explicitly authorized, it may use Boost's `browser-logs` tool when
Boost is available, in addition to Playwright MCP / browsermcp. Do not
use those tools unless the current task authorizes browser QA.
