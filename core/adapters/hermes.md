# Nous Research Hermes Agent

Official: [Hermes Agent](https://github.com/NousResearch/hermes-agent),
[docs](https://hermes-agent.nousresearch.com/),
[context files](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files),
[skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills),
[MCP](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp),
[quickstart](https://hermes-agent.nousresearch.com/docs/getting-started/quickstart).

This adapter is **Nous Research Hermes Agent** only. Hermes is an
optional client. Installing it is not required to use the AI Platform
with Cursor, Grok Build, Codex, or Claude Code.

## Project instructions

Hermes loads **one** primary project context type per session (first
match wins):

`.hermes.md` / `HERMES.md` → `AGENTS.override.md` → `AGENTS.md` →
`CLAUDE.md` → `.cursorrules`

`.cursor/rules/*.mdc` are loaded as that project context **only when no
higher-priority file exists**.

The platform therefore:

- Links `AGENTS.md` → `core/agent-core.md` (shared with Codex and Grok)
- Does **not** create `.hermes.md` or `HERMES.md`

A `.hermes.md` would win and **replace** `AGENTS.md` instead of composing
with it. Do not add one unless a future Hermes-only requirement must
override the shared portable core.

Nested `AGENTS.md` files merge from git root to cwd. `SOUL.md` is
user-global (`~/.hermes/SOUL.md`), not project-owned.

## Skills

Hermes discovers **project** skills natively in:

- `.agents/skills/` (cross-tool convention — this is our canonical path)
- `.hermes/skills/` (Hermes-native; not provisioned, to avoid a second tree)

Bootstrap already copies locked skills into `.agents/skills/`. No extra
Hermes skill symlinks are required.

Project skills are **not** auto-loaded until the developer trusts the
repo (once):

```bash
hermes skills trust
```

Then: `hermes skills list` or `/skills` in a session. User-global skills
live in `~/.hermes/skills/`. Optional extra scan paths:
`skills.external_dirs` in `~/.hermes/config.yaml`. Bootstrap does not
write that file.

## MCP

User-global: `~/.hermes/config.yaml` under `mcp_servers`. Bootstrap does
not write it. Playwright is optional:

```yaml
mcp_servers:
  playwright:
    command: "npx"
    args: ["-y", "@playwright/mcp@latest"]
```

Apply with `/reload-mcp` in a Hermes session. Availability is not
authorization to run browser automation.

## Install (optional)

Not a platform prerequisite. Current CLI install (see official
quickstart for Desktop installer and Windows):

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.zshrc   # or ~/.bashrc
hermes setup      # or: hermes model
```

## Verify in a bootstrapped project

```bash
cd /path/to/your-project
hermes doctor
# Confirm AGENTS.md is loaded, not .hermes.md
ls -l AGENTS.md .hermes.md 2>/dev/null
hermes skills trust
hermes skills list
```

Start a session (`hermes` or `hermes --tui`) and confirm the banner /
project context. `grok inspect` is Grok-only; Hermes uses `hermes doctor`.

## Limitations vs Cursor

| Cursor | Hermes |
| --- | --- |
| Glob / `alwaysApply` `.mdc` rules | `.mdc` files are a fallback context type, skipped when `AGENTS.md` exists |
| Skills load with the project | Requires `hermes skills trust` once per repo |
| MCP in Cursor settings | MCP in `~/.hermes/config.yaml` |
| Laravel Boost `.cursor/mcp.json` | Boost MCP is Cursor-oriented; Hermes MCP is separate user config |

Identity and safety reach Hermes through `AGENTS.md` → `core/agent-core.md`.
On Laravel apps where Boost already owns `AGENTS.md`, bootstrap still
does not overwrite it; use `.ai/guidelines/ai-platform.md` and
`php artisan boost:update`.
