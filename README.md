# AI Development Harness

Version 1.1.1

An agent-agnostic engineering harness for AI-assisted software development.

It sits **above** individual projects and coding agents and provides
persistent:

- engineering standards
- agent guardrails (including a project-identity boundary)
- project context
- architecture, ADR, and documentation-contract workflows
- project adoption and reconciliation
- reusable skills
- tooling integration
- documentation maintenance
- multi-agent portability

```text
Developer
    → AI Development Harness
        → coding agent (Cursor, Grok Build, Codex, Claude Code, or Hermes)
            → project repository
```

The GitHub repository and scripts still use `ai-platform` /
`$AI_PLATFORM` internally. That is compatibility naming, not a second
product.

Projects own business logic. This repository owns reusable knowledge.

## Supported coding agents

| Agent | Role |
| --- | --- |
| **Cursor** | Primary / reference implementation |
| **Grok Build** | Supported |
| **OpenAI Codex / Codex CLI** | Supported |
| **Claude Code** | Supported |
| **Nous Research Hermes Agent** | Supported |

Capabilities are **not** identical. Matrix: `core/adapters/README.md`.

If a prompt clearly belongs to another repository, the agent must **stop**
before modifying files, identify the mismatch, and wait for you to switch
projects or confirm. That guardrail is part of the portable always-on core.

## Bootstrap vs Project Adoption

**Bootstrap** is deterministic provisioning. It links shared rules, portable
agent entrypoints, skills/adapters, and documentation templates. It does
not analyze or rewrite the application. You do not choose an agent during bootstrap. A project may be used with more than one supported agent.

**Project Adoption** is agent-driven reasoning after bootstrap:

**Understand → Document → Compare → Question → Recommend → Approve → Align**

Adoption establishes project context, architecture, ADRs, applicable
contracts, roadmap/status, and reconciliation. Material remediation
requires your approval. Agent adapter files are not an alternate source
of project truth.

This README is the starting point. Follow it in order.

## 1. Prerequisites

Required:

| Tool | Why |
| --- | --- |
| Git | Clone this repository |
| Bash | All harness scripts (`#!/usr/bin/env bash`) |
| Python 3 | Bootstrap/doctor JSON parsing; UI/UX Pro Max skill scripts |
| Node.js with npm/`npx` | Skill restore/update; Playwright MCP; Superdesign CLI |
| A supported coding agent | Cursor (reference), Grok Build, Codex, Claude Code, and/or Hermes Agent |

Playwright MCP's own docs require Node.js 18+. Install these with your
OS package manager or the vendor installer. Homebrew is not required.

Optional / not installed by this repository:

- Playwright MCP, BrowserMCP, and other **user-global** MCP servers
- Superdesign CLI (invoked on demand via `npx`; requires login)
- Laravel Boost (project-native on Laravel apps; not harness-owned)
- `@playwright/test` (project-owned Mode A; Laravel profile expects it)

Hermes Agent installation is optional. Codex, Claude Code, and Grok
Build are optional if you use another supported client.

## 2. Clone

Pick a **stable** path. Bootstrap writes that path into project
symlinks; moving the clone later requires re-running bootstrap.

```bash
git clone git@github.com:ConlinJoe/ai-platform.git ~/Sites/AI
```

HTTPS: `https://github.com/ConlinJoe/ai-platform.git`.

Use this variable in the commands below (change the path if you cloned
elsewhere):

```bash
AI_PLATFORM="$HOME/Sites/AI"
```

Do not treat any personal machine path as required. Choose a location
on the machine that will use the clone.

## 3. Configure the harness clone

```bash
cd "$AI_PLATFORM"
chmod +x scripts/*.sh scripts/lib/*.sh
./scripts/doctor.sh
ls .agents/skills
```

Doctor should pass. Locked skills should already be present from git:

`frontend-design`, `hallmark`, `superdesign`, `ui-ux-pro-max`

If those directories are missing, restore from `skills-lock.json`
(this is **not** the skill-update command):

```bash
cd "$AI_PLATFORM"
npx skills experimental_install
```

`scripts/update-skills.sh` is later maintenance. It runs
`npx skills update -p -y` in this clone. Review the git diff before
committing. It is not linked into target projects.

Optional, if you are changing this repository:

```bash
./scripts/test-platform.sh
```

## 4. Configure coding agents

Open **target projects** in whichever supported agent you use after
bootstrap. You do not need this clone open while working on an app;
linked rules resolve into `$AI_PLATFORM`.

| Agent | Role | Bootstrap | Details |
| --- | --- | --- | --- |
| **Cursor** | Primary / reference | `.cursor/rules/*.mdc` symlinks, `.agents/skills/` | `core/adapters/cursor.md` |
| **Grok Build** | Supported | Shared `AGENTS.md`; `.grok/skills/` → `.agents/skills/` | `core/adapters/grok-build.md` |
| **Codex** | Supported | `AGENTS.md` → `core/agent-core.md` when missing | `core/adapters/codex.md` |
| **Claude Code** | Supported | `CLAUDE.md` (`@AGENTS.md`); `.claude/skills/` → `.agents/skills/` | `core/adapters/claude-code.md` |
| **Hermes Agent** | Supported (Nous Research) | Shared `AGENTS.md`. **No `.hermes.md`** (that file would override the shared core) | `core/adapters/hermes.md` |

Canonical detailed standards stay in `.cursor/rules/`. The portable
always-on core is `core/agent-core.md`. Do not copy the full rule set
into `AGENTS.md` or `CLAUDE.md`. Capability matrix:
`core/adapters/README.md`.

Hermes installation is optional (see its adapter). After bootstrap, in
the project: `hermes skills trust` once so Hermes loads `.agents/skills/`.

On Laravel apps, Laravel Boost may own generated `AGENTS.md` /
`CLAUDE.md`. Bootstrap does not overwrite those files. It links
`.ai/guidelines/ai-platform.md` → `core/agent-core.md`. Run
`php artisan boost:install` or `boost:update` so Boost regenerates its
agent instructions and includes the portable core.

### Skills vs MCP servers

| Kind | Scope | Who installs it |
| --- | --- | --- |
| Shared agent skills (Hallmark, frontend-design, ui-ux-pro-max, Superdesign) | Harness lockfile; copied into `.agents/skills/`; adapter dirs are symlinks | This repository / bootstrap |
| Playwright MCP, BrowserMCP | **Agent/client** config (often user-global) | You; not bootstrap. See `mcp/README.md` |
| GitKraken or other SCM MCPs | User-global where the client supports it | You; **not** owned or required by this harness |
| Laravel Boost MCP | Laravel **project** `.cursor/mcp.json` | `php artisan boost:install`, not bootstrap |

Bootstrap does **not** install MCP servers. Per-agent MCP notes:
`core/adapters/`.

### Playwright MCP (Cursor user-global; reference)

Add to `~/.cursor/mcp.json` (not a Laravel app's `.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

Or Cursor Settings → MCP → Add new MCP Server, command
`npx -y @playwright/mcp@latest`. Enable the server in Cursor MCP
settings. Availability is not authorization to run browser automation
(`.cursor/rules/60-browser-qa.mdc`).

### BrowserMCP (user-global)

Typical Mode B companion. Configure in Cursor Settings → MCP as a
user-global server. This harness does not install it and does not
write its config.

### Superdesign (skill + CLI, not MCP)

- **Skill:** `.agents/skills/superdesign` (locked; copied into projects)
- **CLI:** `npx --yes @superdesign/cli@latest` (on demand; no global install)
- **Login:** if preflight reports `not authenticated`, run
  `npx --yes @superdesign/cli@latest login`

Do not conflate the skill, the CLI, and MCP servers.

## 5. Bootstrap a project

Bootstrap **provisions** the harness. It does not analyze or rewrite
the application.

From the **target project** root:

```bash
"$AI_PLATFORM/scripts/bootstrap-project.sh"
```

From the **harness** clone:

```bash
"$AI_PLATFORM/scripts/bootstrap-project.sh" /path/to/your-project
```

### What bootstrap does

| Item | Behavior |
| --- | --- |
| Shared Cursor rules (`00`–`60` `*.mdc`) | Symlink into `.cursor/rules/` |
| `AGENTS.md` | Symlink to `core/agent-core.md` if missing (not overwritten) |
| `CLAUDE.md` | Copied if missing (`@AGENTS.md`) |
| `.hermes.md` | **Not** created. Hermes uses `AGENTS.md` |
| `.ai/guidelines/ai-platform.md` | Laravel only: symlink to `core/agent-core.md` for Boost composition |
| `.claude/skills/`, `.grok/skills/` | Symlinks to `.agents/skills/` |
| `scripts/doctor.sh`, `scripts/export-chatgpt-context.sh` | Symlink into the project |
| `skills-lock.json` | Symlink to this clone |
| Locked skills | Copied into `.agents/skills/` (`npx skills experimental_install`) |
| `docs/` | Copied from templates if `docs/README.md` is missing; existing docs are not overwritten |
| Existing projects | May add missing drafts: `99-project-status.md`, `platform-reconciliation.md`, Laravel `browser-qa.md` |
| `.cursor/rules/90-*.mdc` | Not created; project-owned if you add them later |
| Application code, Composer, npm, WordPress plugins | Not modified / not installed |

Pick a stable `$AI_PLATFORM` path before bootstrapping. Re-run bootstrap
if you move the clone.

## 6. Verify bootstrap

Bootstrap prints its own verification report (rules, skills, linked
scripts). Re-check from **either** side — do not assume harness scripts
exist in a project until bootstrap has linked them:

```bash
"$AI_PLATFORM/scripts/doctor.sh" /path/to/your-project
ls -l /path/to/your-project/.cursor/rules
ls /path/to/your-project/.agents/skills
```

After bootstrap, `/path/to/your-project/scripts/doctor.sh` is a symlink
to the same doctor script. Prefer the `$AI_PLATFORM/...` form above if
you are not sure the symlink exists.

Linked rules should resolve into `$AI_PLATFORM/.cursor/rules/`.

## 7. Existing vs greenfield

The harness is **not** Laravel-specific. General behavior applies to
Python, JavaScript/TypeScript, PHP, Laravel, WordPress, Business
Central/AL, and other stacks. Framework-specific rules attach only when
that stack is present.

**Existing project** — Bootstrap → Adopt → Reconcile → Approve → Align.
Do not treat bootstrap as adoption.

**Greenfield project** — bootstrap before substantive implementation so
standards, architecture, documentation, and guardrails govern work from
the start. Fill `docs/` from the installed scaffold
(`.cursor/rules/50-workflows.mdc`). There is no separate scaffold
command in this repository.

## 8. Project Adoption

After bootstrap, in the **target** repository:

1. Open or reload the project in the current coding agent.
2. Start a **fresh** session.
3. Follow `$AI_PLATFORM/core/prompts/project-adoption.md`
   (bootstrap prints this path). From the project you can also resolve it:

```bash
AI_PLATFORM="$(cd "$(dirname "$(readlink .cursor/rules/00-platform.mdc)")/../.." && pwd)"
echo "$AI_PLATFORM/core/prompts/project-adoption.md"
```

Lifecycle: **Understand → Document → Compare → Question → Recommend → Approve → Align**

The agent should establish or update project context, architecture,
ADRs, applicable contracts, roadmap/status, `90-*.mdc` rules when
needed, and `docs/contracts/foundational/platform-reconciliation.md`.

It compares the implementation to harness standards, encoded developer
preferences, and current framework / security / testing /
maintainability expectations. Findings use A/B/C/D. Sound decisions
are preserved. Reasonable differences from harness preference are
documented, not changed for conformity. Material remediation needs
your approval. Ask only when the repository cannot safely answer.

`core/prompts/existing-project-bootstrap.md` is a compatibility alias
for the same prompt.

## 9. Daily usage

Work inside the **target** repository, not this clone.

- Linked `00`–`60` rules apply in Cursor; `AGENTS.md` / `CLAUDE.md` apply
  in Codex, Claude Code, Grok Build, and Hermes.
- Project `docs/` and `.cursor/rules/90-*.mdc` are local context.
- Use a fresh agent thread for bounded tasks when the work needs a
  clean adoption/implementation boundary.
- Do not run Playwright or browser MCP unless the current task
  authorizes it.
- Keep contracts current as implementation changes
  (`.cursor/rules/10-documentation.mdc`).
- After documentation/rule/skill changes in a project:

```bash
/path/to/your-project/scripts/export-chatgpt-context.sh
```

That script is a bootstrap symlink. Run it from the project root.
Upload `.build/chatgpt-context.zip` to the ChatGPT Project
(`docs/chatgpt-projects.md`).

## 10. Maintenance

In this clone only:

```bash
cd "$AI_PLATFORM"
./scripts/update-skills.sh
```

Review and commit. Re-running project bootstrap restores **missing**
skills; it does not refresh skill copies that are already installed.
To restore project skills from the linked lockfile:

```bash
cd /path/to/your-project
npx skills experimental_install
```

Edit shared rules in `$AI_PLATFORM`, not through project symlinks.

## Repository structure

- `.cursor/rules/` — canonical Cursor rules (linked into projects)
- `AGENTS.md` / `CLAUDE.md` — thin always-on entrypoints (`core/agent-core.md`)
- `core/adapters/` — per-agent setup, limitations, and capability matrix
- `.agents/skills/` — locked third-party skills (`.claude/skills/` and
  `.grok/skills/` are symlinks; Hermes reads `.agents/skills/` natively)
- `core/` — profiles, prompts (`core/prompts/project-adoption.md`)
- `scripts/` — `bootstrap-project.sh`, `doctor.sh`, `update-skills.sh`,
  `export-chatgpt-context.sh`, `test-platform.sh`
- `mcp/` — MCP **ownership** (not an installer)
- `templates/` — docs copied into new projects
- `docs/` — this harness's contracts
- `skills-lock.json` — pinned skill versions
- `LICENSE` — MIT

## Documentation

Contract model: `docs/documentation-philosophy.md`. Index:
`docs/README.md`. Workflows: `.cursor/rules/50-workflows.mdc`.

Laravel browser QA is opt-in
(`docs/contracts/features/browser-qa.md`). Laravel Boost is
project-native (`docs/contracts/features/laravel-boost.md`).

## License

MIT. See `LICENSE`.
