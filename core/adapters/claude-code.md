# Claude Code

Official: [CLAUDE.md](https://code.claude.com/docs/en/claude-md),
[skills](https://code.claude.com/docs/en/skills).

| Mechanism | Location | Notes |
| --- | --- | --- |
| Project instructions | `CLAUDE.md` or `.claude/CLAUDE.md` | Keep short. Claude does **not** read `AGENTS.md` natively |
| Import | `@AGENTS.md` | Official way to share one instruction file |
| Path-scoped rules | `.claude/rules/*.md` | Optional; YAML `paths:`. Not a copy of Cursor `.mdc` |
| Skills | `.claude/skills/` | Native project path. Bootstrap symlinks these to `.agents/skills/` |
| MCP | User settings or project `.mcp.json` | Do not put Playwright MCP in a Laravel `.cursor/mcp.json`. User-global preferred |
| Personal | `~/.claude/CLAUDE.md`, `CLAUDE.local.md` (gitignore) | Not provisioned |

Bootstrap copies `CLAUDE.md` from `templates/agents/CLAUDE.md` when
missing (`@AGENTS.md` plus a pointer to linked skills). If Laravel Boost
already wrote `CLAUDE.md`, bootstrap leaves it in place. Portable core
still ships as `.ai/guidelines/ai-platform.md` for the next
`boost:install` / `boost:update`.

Do not `@`-import the entire `.cursor/rules/` tree (always-loaded
context). Read matching Cursor rules when the files in play match.

Glob-scoped Cursor rules (Laravel, Roots, coding) are **not** auto-attached
the way they are in Cursor. Follow the tables in `AGENTS.md` / `core/agent-core.md`.
