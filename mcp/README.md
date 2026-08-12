# MCP guidance

The AI Platform documents MCP **ownership**. It does not ship a global MCP
server catalog into every project.

| Server | Scope | Owner |
| --- | --- | --- |
| Laravel Boost (`laravel-boost`) | Project | Laravel app via `php artisan boost:install` |
| Playwright MCP | User-global (typical) | Cursor user MCP — Mode B exploration |
| browsermcp | User-global (typical) | Cursor user MCP — Mode B exploration |

Authoritative contracts:

- Boost: `docs/contracts/features/laravel-boost.md`
- Browser QA: `docs/contracts/features/browser-qa.md`

Do not add project-bound servers (Boost) to `~/.cursor/mcp.json`.
Do not add user-global browser MCPs to a Laravel app's `.cursor/mcp.json`
just to satisfy platform policy — Boost's installer owns that file.
