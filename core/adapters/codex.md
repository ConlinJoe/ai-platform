# OpenAI Codex / Codex CLI

Official: [AGENTS.md](https://developers.openai.com/codex/guides/agents-md),
[skills](https://developers.openai.com/codex/skills),
[config](https://developers.openai.com/codex/config-reference).

| Mechanism | Location | Notes |
| --- | --- | --- |
| Project instructions | `AGENTS.md` | Hierarchical; `AGENTS.override.md` wins at the same directory. Default combined cap **32 KiB** |
| Skills | `.agents/skills/` | Native. Same path the platform already uses |
| MCP | `~/.codex/config.toml`; trusted project `.codex/config.toml` | User/machine or trusted project. Not written by bootstrap |
| Global instructions | `~/.codex/AGENTS.md` | User-level; not provisioned by the platform |

Bootstrap links `AGENTS.md` → AI Platform `core/agent-core.md` when the
file is missing. It does **not** overwrite an existing `AGENTS.md`
(Laravel Boost often owns that file).

On Laravel apps, bootstrap also links
`.ai/guidelines/ai-platform.md` → `core/agent-core.md`. That is Boost's
official custom-guideline path. Run `php artisan boost:install` or
`boost:update` so generated `AGENTS.md` includes the portable core.
Do not paste the full rule set into `AGENTS.md`.

Codex does not load `.cursor/rules/*.mdc`. Identity and safety reach
Codex through `AGENTS.md` (platform symlink, or Boost-generated file
after the guideline is published).
