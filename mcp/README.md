# MCP guidance

The AI Platform documents MCP **ownership**. It does not ship a global MCP
server catalog into every project and does **not** install Cursor
user-global MCP servers during clone or bootstrap.

MCP servers are **capability-on-demand**, not capability-by-default.
See `.cursor/rules/00-platform.mdc`. An MCP being available does not
mean it should be enabled or used automatically.

**Tool availability is not authorization.**
**Tool availability is also not justification for using a tool.**

Each MCP server should have a clearly defined responsibility. Avoid
multiple MCPs that provide substantially overlapping capabilities.
Do not create arbitrary numerical limits such as a maximum server count.
The governing principle is **purpose and value**, not count.

Where practical:

- keep the default MCP footprint small
- prefer existing agent-native capabilities when equivalent
- prefer skills and rules for knowledge and reasoning that do not
  require live external access
- prefer MCPs for capabilities that require live interaction, external
  systems, browsers, or specialized runtime access
- invoke tools only when they materially help the bounded task

Bootstrap provisions only what the harness architecture intentionally
owns. Additional MCPs are not required bootstrap dependencies.
Client-specific MCP configuration remains client-specific. Do not force
identical MCP configurations across Cursor, Grok Build, Codex, Claude
Code, and Hermes merely for parity. Capability parity is not the goal;
reliable workflow behavior is.

Do not add an MCP simply because this documentation mentions one.
Project requirements drive tool selection.

| Server | Scope | Owner |
| --- | --- | --- |
| Laravel Boost (`laravel-boost`) | Project | Laravel app via `php artisan boost:install` |
| Playwright MCP | User-global | You configure Cursor (`~/.cursor/mcp.json`) |
| BrowserMCP (`browsermcp`) | User-global (typical) | You configure Cursor; platform does not install it |
| GitKraken or other SCM MCPs | User-global (optional) | You configure Cursor; **not** owned or required here |

Authoritative contracts:

- Boost: `docs/contracts/features/laravel-boost.md`
- Browser QA: `docs/contracts/features/browser-qa.md`
- Playwright MCP setup: `mcp/playwright/README.md`

Agent invocation of Playwright / browser MCP follows
`.cursor/rules/60-browser-qa.mdc`. Availability is not general
authorization. Availability is also not justification for using a
tool. Significant UI authorizes a bounded Mode B visual pass of that
UI only.

Do not add project-bound servers (Boost) to user-global MCP config.
Do not add user-global browser MCPs to a Laravel app's `.cursor/mcp.json`
just to satisfy platform policy — Boost's installer owns that file.

Per-agent MCP locations: `core/adapters/` (Cursor, Codex, Claude Code,
Grok Build, Hermes). Bootstrap does not write user-global MCP config.
