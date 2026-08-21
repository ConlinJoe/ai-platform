# MCP guidance

The AI Platform documents MCP **ownership**. It does not ship a global MCP
server catalog into every project and does **not** install Cursor
user-global MCP servers during clone or bootstrap.

| Server | Scope | Owner |
| --- | --- | --- |
| Laravel Boost (`laravel-boost`) | Project | Laravel app via `php artisan boost:install` |
| Playwright MCP | User-global | You configure Cursor (`~/.cursor/mcp.json`) |
| BrowserMCP (`browsermcp`) | User-global (typical) | You configure Cursor; platform does not install it |
| GitKraken or other SCM MCPs | User-global (optional) | You configure Cursor; **not** owned or required here |
| Superdesign | Not an MCP server | Agent **skill** plus on-demand CLI; see README |

Authoritative contracts:

- Boost: `docs/contracts/features/laravel-boost.md`
- Browser QA: `docs/contracts/features/browser-qa.md`
- Playwright MCP setup: `mcp/playwright/README.md`

Agent invocation of Playwright / browser MCP is opt-in
(`.cursor/rules/60-browser-qa.mdc`). Availability is not authorization.

Do not add project-bound servers (Boost) to user-global MCP config.
Do not add user-global browser MCPs to a Laravel app's `.cursor/mcp.json`
just to satisfy platform policy — Boost's installer owns that file.

Per-agent MCP locations: `core/adapters/` (Cursor, Codex, Claude Code,
Grok Build, Hermes). Bootstrap does not write user-global MCP config.
