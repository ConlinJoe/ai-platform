# Grok Build

Official: [overview](https://docs.x.ai/build/overview),
[AGENTS.md / project rules](https://docs.x.ai/build/features/project-rules),
[skills](https://docs.x.ai/build/features/skills-plugins-marketplaces),
[MCP](https://docs.x.ai/build/features/mcp-servers).

| Mechanism | Location | Notes |
| --- | --- | --- |
| Project instructions | `AGENTS.md` (also `CLAUDE.md`) | Loaded in full; keep `AGENTS.md` short |
| Cursor compat | `.cursor/rules/` | Grok reads this directory for compatibility. Glob/`alwaysApply` semantics may not match Cursor |
| Skills | `./.grok/skills/` (walked to repo root); `~/.grok/skills/`; `~/.agents/skills/` | Project `.agents/skills/` is **not** listed as a Grok discovery path |
| MCP | `~/.grok/config.toml`; project `.grok/config.toml` (`--scope project`); also merges `.cursor/mcp.json` and `.mcp.json` | Bootstrap does not write these |
| Verify | `grok inspect` | Lists discovered rules, skills, MCP |

Bootstrap links `AGENTS.md` (shared with Codex) and symlinks
`.grok/skills/<name>` → `.agents/skills/<name>`.

Identity and safety reach Grok through `AGENTS.md` and, additionally,
compatibility loading of `.cursor/rules/`. On Laravel apps, Boost may
own `AGENTS.md`; Grok still loads Cursor rules. Prefer
`.ai/guidelines/ai-platform.md` so generated `AGENTS.md` also includes
the portable core.

Claude Code skills/rules are also read with zero extra Grok config.
