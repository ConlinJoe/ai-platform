# Agent adapters

Thin entrypoints so coding agents consume **one** canonical AI Platform
without duplicated rule sets.

```text
core/agent-core.md          always-on portable core (identity, safety)
.cursor/rules/*.mdc         canonical detailed rules (Cursor reference)
.agents/skills/             canonical managed skills, plus the optional
                            harness-owned video-production skill
AGENTS.md                   Codex / Grok / Hermes (and AGENTS.md-compatible agents)
CLAUDE.md                   Claude Code (@AGENTS.md)
.claude/skills/             symlinks → .agents/skills/
.grok/skills/               symlinks → .agents/skills/
```

Do not add `.hermes.md`. Hermes consumes the shared `AGENTS.md`.
Do not copy `.cursor/rules/` into adapter docs.

Substantial-redesign approval lives in `.cursor/rules/40-ui.mdc`.
`core/agent-core.md` points every agent at that gate. Do not restate the
procedure in an adapter doc.

| Agent | Doc |
| --- | --- |
| Cursor (reference) | `cursor.md` |
| Grok Build | `grok-build.md` |
| OpenAI Codex / Codex CLI | `codex.md` |
| Claude Code | `claude-code.md` |
| Nous Research Hermes Agent | `hermes.md` |

Bootstrap installs safe lightweight adapters automatically. It does not
detect which agents are installed and does not ask. A project may use
more than one agent.

The optional video-production skill is harness-owned. It is not in
`skills-lock.json`. After a project opts in, the installer links it
from `.agents/skills/video-production` and from the Claude and Grok
skill directories. Cursor, Codex, and Hermes read `.agents/skills/`.
Claude Code and Grok follow those links. The same skill text is the
procedure for every adapter. It does not add an MCP server.

MCP configuration is client-specific. Do not force identical MCP
setups across agents merely for parity. Capability parity is not the goal;
reliable workflow behavior is. Additional MCPs are not bootstrap
dependencies. External tools are capability-on-demand
(`.cursor/rules/00-platform.mdc`, `mcp/README.md`).

## Capability matrix

Verified against current official agent documentation. Blank or
"partial" means the capability is not equivalent to Cursor.

| Capability | Cursor | Grok Build | Codex | Claude Code | Hermes |
| --- | --- | --- | --- | --- | --- |
| Portable core (`AGENTS.md` → `core/agent-core.md`) | Yes (also always-on `AGENTS.md`) | Yes | Yes | Via `CLAUDE.md` `@AGENTS.md` | Yes (do not add `.hermes.md`) |
| Detailed rules (`.cursor/rules/*.mdc`) | Native glob / alwaysApply | Compat load; globs may not apply | Not auto-loaded; follow tables in core | Not auto-attached; read when files match | Fallback only if no `AGENTS.md` |
| Project identity | `00-platform.mdc` + core | Core + Cursor rules | Core via `AGENTS.md` | Core via `CLAUDE.md` | Core via `AGENTS.md` |
| Skills | `.agents/skills/` | `.grok/skills/` → canonical | `.agents/skills/` | `.claude/skills/` → canonical | `.agents/skills/` after `hermes skills trust` |
| MCP | User-global / project Boost | User or project `.grok/config.toml` | `~/.codex/config.toml` | User or `.mcp.json` | `~/.hermes/config.yaml` |
| Adoption | Same prompt | Same prompt | Same prompt | Same prompt | Same prompt |

Laravel Boost may own generated `AGENTS.md` / `CLAUDE.md`. Composition:
`.ai/guidelines/ai-platform.md` → `core/agent-core.md`, then
`php artisan boost:install` or `boost:update`. Until that runs, Codex and
Hermes may see Boost instructions without the portable core. Cursor still
loads `.cursor/rules/00-platform.mdc`. Grok still loads Cursor rules for
compatibility.
