# Cursor (reference implementation)

Official: [Cursor rules](https://cursor.com/docs/rules.md).

| Mechanism | Location | Notes |
| --- | --- | --- |
| Project rules | `.cursor/rules/*.mdc` | Canonical. `alwaysApply`, `globs`, `description` |
| AGENTS.md | repo root | Also read as always-on plain markdown |
| Skills | `.agents/skills/` | Platform lockfile; bootstrap copies into projects |
| MCP | `~/.cursor/mcp.json` (user-global); `.cursor/mcp.json` (project; Laravel Boost owns this on Laravel apps) | Bootstrap does not write MCP config |

Preserve symlink architecture from `scripts/bootstrap-project.sh`. Do
not replace `.mdc` rules with AGENTS.md.

Playwright MCP: `mcp/playwright/README.md`.
