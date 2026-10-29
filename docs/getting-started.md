---
status: active
last_reviewed: 2026-10-29
source_of_truth_for:
  - First-time clone and harness setup
  - Prerequisites, doctor, bootstrap, and bootstrap verification
  - Required versus optional tooling for installation
depends_on:
  - 00-project-context.md
  - how-it-works.md
referenced_by:
  - ../README.md
  - README.md
  - adopting-projects.md
  - maintaining.md
  - llm-support-prompt.md
type: foundational
---

# Getting started

Canonical installation for a developer who has not used this repository
before. Daily usage, adoption, and updates live in the linked pages.

Internal scripts and clone paths still use `AI_PLATFORM` / `ai-platform`.
That is compatibility naming. The public product name is **AI Development
Harness**.

## What you will have when this is done

1. A stable clone of this repository on the machine that runs your coding
   agent.
2. `scripts/doctor.sh` passing against that clone.
3. At least one application project bootstrapped so it can load harness
   rules.

You then adopt the project (existing apps) or fill project documentation
(new apps). Those steps are not part of clone setup:
[Adopting projects](adopting-projects.md).

## Prerequisites

Required:

| Tool | Why |
| --- | --- |
| Git | Clone this repository |
| Bash | All harness scripts (`#!/usr/bin/env bash`) |
| Python 3 | JSON parsing in bootstrap and doctor |
| Node.js with npm/`npx` | Skill restore and update |
| A supported coding agent | Cursor is the reference implementation. Grok Build, Codex, Claude Code, and Hermes Agent are also supported. |

Playwright MCP's own documentation requires Node.js 18+. Install these
with your OS package manager or the vendor installer. Homebrew is not
required.

Optional. This repository does **not** install them:

- Playwright MCP, BrowserMCP, and other user-global MCP servers
- Laravel Boost (project-native on Laravel apps)
- `@playwright/test` (project-owned Mode A; expected on the Laravel
  profile, not installed here)
- GitHub CLI (`gh`) for Issues and Pull Requests
- Optional Deployer stack (offered at bootstrap or installed later;
  [Deployer capability](contracts/features/deployer.md))
- Hermes Agent, Codex, Claude Code, or Grok Build if you already use
  another supported client

Cursor-specific MCP configuration is optional and is **not** part of
harness clone setup. See [MCP ownership](../mcp/README.md).

## 1. Clone to a stable path

Bootstrap writes **absolute** symlink targets into each project. Pick a
path you can leave in place. Moving the clone later means re-running
bootstrap in every adopted project.

HTTPS:

```bash
git clone https://github.com/ConlinJoe/ai-platform.git ~/src/ai-platform
```

SSH:

```bash
git clone git@github.com:ConlinJoe/ai-platform.git ~/src/ai-platform
```

`~/src/ai-platform` is an example, not a required location. Use any
stable directory on **this** machine.

Set a variable for the commands below (change the path if you cloned
elsewhere):

```bash
AI_PLATFORM="$HOME/src/ai-platform"
```

## 2. Configure the harness clone

```bash
cd "$AI_PLATFORM"
chmod +x scripts/*.sh scripts/lib/*.sh
./scripts/doctor.sh
ls .agents/skills
```

Doctor should pass. The locked skill directories should already be present
from git:

`hallmark`, `impeccable`

`video-production` is also in that directory. It is harness-owned and
optional. It is not listed in `skills-lock.json`, and the restore
command above does not install it into a project.

If `hallmark` or `impeccable` is missing, restore from `skills-lock.json`. This is
**not** the skill-update command:

```bash
cd "$AI_PLATFORM"
npx skills experimental_install
```

First-time skill restore requires **network access**. That command
currently retrieves the locked skills from GitHub/upstream. Bootstrap
uses the same restore when a project is missing locked skills.

`scripts/update-skills.sh` is later maintenance. It runs
`npx skills update -p -y` in this clone. Review the git diff before
committing. It is not linked into target projects.
See [Maintaining the harness](maintaining.md).

Optional, if you are changing this repository:

```bash
./scripts/test-platform.sh
```

## 3. Supported coding agents

Open **target projects** in whichever supported agent you use after
bootstrap. You do not need this clone open while working on an app;
linked rules resolve into `$AI_PLATFORM`.

You do not choose an agent during bootstrap. A project may be used with
more than one supported agent.

| Agent | Role | What bootstrap provisions | Details |
| --- | --- | --- | --- |
| **Cursor** | Primary / reference | `.cursor/rules/*.mdc` symlinks, `.agents/skills/` | [cursor.md](../core/adapters/cursor.md) |
| **Grok Build** | Supported | Shared `AGENTS.md`; `.grok/skills/` → `.agents/skills/` | [grok-build.md](../core/adapters/grok-build.md) |
| **Codex** | Supported | `AGENTS.md` → `core/agent-core.md` when missing | [codex.md](../core/adapters/codex.md) |
| **Claude Code** | Supported | `CLAUDE.md` (`@AGENTS.md`); `.claude/skills/` → `.agents/skills/` | [claude-code.md](../core/adapters/claude-code.md) |
| **Hermes Agent** | Supported (Nous Research) | Shared `AGENTS.md`. **No `.hermes.md`** (that file would override the shared core) | [hermes.md](../core/adapters/hermes.md) |

Canonical detailed standards stay in `.cursor/rules/`. The portable
always-on core is `core/agent-core.md`. Do not copy the full rule set
into `AGENTS.md` or `CLAUDE.md`. Capability matrix:
[core/adapters/README.md](../core/adapters/README.md).

Capabilities are not identical. Cursor loads `.cursor/rules/*.mdc`
natively. Other agents consume the portable core plus adapter-specific
skill paths. Read the adapter doc for the client you use.

Hermes installation is optional. After bootstrap, in the project run
`hermes skills trust` once so Hermes loads `.agents/skills/`.

On Laravel apps, Laravel Boost may own generated `AGENTS.md` /
`CLAUDE.md`. Bootstrap does not overwrite those files. It links
`.ai/guidelines/ai-platform.md` → `core/agent-core.md`. Run
`php artisan boost:install` or `boost:update` so Boost regenerates its
agent instructions and includes the portable core.

## 4. Optional MCP servers

| Kind | Scope | Who installs it |
| --- | --- | --- |
| Shared agent skills (Impeccable, Hallmark) | Harness lockfile; copied into `.agents/skills/`; adapter dirs are symlinks | This repository / bootstrap |
| Playwright MCP, BrowserMCP | Agent/client config (often user-global) | You. Not bootstrap. [mcp/README.md](../mcp/README.md) |
| GitKraken or other SCM MCPs | User-global where the client supports it | You. Not owned or required by this harness |
| Laravel Boost MCP | Laravel **project** `.cursor/mcp.json` | `php artisan boost:install`, not bootstrap |

Bootstrap does **not** install MCP servers. Additional MCPs are not
bootstrap dependencies. MCP configuration is client-specific.

Playwright MCP setup for Cursor: [mcp/playwright/README.md](../mcp/playwright/README.md).
Availability is not authorization to run browser automation
([60-browser-qa](../.cursor/rules/60-browser-qa.mdc)).

## 5. Bootstrap a project

Bootstrap **provisions** the harness. It does not analyze or rewrite
application code, install Composer or npm packages, or run Project
Adoption.

From the **target project** root:

```bash
"$AI_PLATFORM/scripts/bootstrap-project.sh"
```

From the **harness** clone:

```bash
"$AI_PLATFORM/scripts/bootstrap-project.sh" /path/to/your-project
```

Optional Deployer flags (skip the prompt; neither flag deploys):

```bash
"$AI_PLATFORM/scripts/bootstrap-project.sh" --with-deployer /path/to/your-project
"$AI_PLATFORM/scripts/bootstrap-project.sh" --without-deployer /path/to/your-project
```

Interactive bootstrap may ask `Install Deployer deployment stack? [y/N]`
(default N) when the harness-managed stack is absent and the project
matches a supported profile. Add Deployer later without re-running
adoption:

```bash
"$AI_PLATFORM/scripts/install-deployer.sh" /path/to/your-project
```

Installing Deployer does not deploy anything, does not configure a
server, and does not authorize deployment. Supported profiles and
server setup: [Deployer capability](contracts/features/deployer.md).

Video production is separate. Bootstrap does not prompt for it and
does not install it unless you pass `--with-video`. Add it later
without re-running bootstrap:

```bash
"$AI_PLATFORM/scripts/install-video-production.sh" /path/to/your-project
```

A video-only studio, with no application framework:

```bash
"$AI_PLATFORM/scripts/init-video-studio.sh" /path/to/video-studio
```

Neither command renders a film or spends generation credits.
Canonical reference:
[Video production](contracts/features/video-production.md).

If you run the script from the harness clone with no argument, it
prompts for a target path.

### What bootstrap does

| Item | Behavior |
| --- | --- |
| Shared Cursor rules (`00`–`70` `*.mdc`) | Symlink into `.cursor/rules/` |
| `AGENTS.md` | Symlink to `core/agent-core.md` if missing (not overwritten) |
| `CLAUDE.md` | Copied if missing (`@AGENTS.md`) |
| `.hermes.md` | **Not** created. Hermes uses `AGENTS.md` |
| `.ai/guidelines/ai-platform.md` | Laravel only: symlink to `core/agent-core.md` for Boost composition |
| `.claude/skills/`, `.grok/skills/` | Symlinks to `.agents/skills/` |
| `scripts/doctor.sh`, `scripts/export-chatgpt-context.sh`, `scripts/check-guardrails.sh` | Symlink into the project |
| `skills-lock.json` | Symlink to this clone |
| Locked skills | Copied into `.agents/skills/` (`npx skills experimental_install`) when missing; requires network |
| `docs/` | Copied from templates if `docs/README.md` is missing; existing docs are not overwritten |
| `.github/` Issue/PR templates | Not copied; existing GitHub files are not overwritten |
| Existing projects | May add missing drafts: `working-mode.md`, `99-project-status.md`, `platform-reconciliation.md`, `public-submissions.md`, Laravel `browser-qa.md` |
| `.cursor/rules/90-*.mdc` | Not created; project-owned if you add them later |
| Application code, Composer, npm, WordPress plugins | Not modified / not installed, except optional Deployer may declare `deployer/deployer` in `require-dev` without running Composer |
| Public submission protection | Not installed. New projects receive a `public-submissions.md` record to fill (`not applicable` is valid). Requirement: [spam and abuse protection](contracts/features/spam-and-abuse-protection.md) |
| Optional Deployer | Prompt or `--with-deployer` / `--without-deployer`. Does not deploy. |
| Optional video production | Off unless `--with-video` or `scripts/install-video-production.sh`. Does not render or publish. |

Bootstrap does not write `docs/architecture-baseline.txt`. New projects
run stack-native checks through the linked `scripts/check-guardrails.sh`
with no baseline. See
[stack-native architecture](contracts/features/stack-native-architecture.md).

Bootstrap is safe to re-run. Shared Cursor rules update immediately
through those symlinks. A newly added rule file is linked on the next
bootstrap. A re-run also prunes retired managed skills,
refreshes Claude/Grok skill adapter links, applies current
bootstrap-managed project configuration, and adds current ignore entries
for Hallmark, Impeccable ephemeral artifacts, `.DS_Store`, and `.ai/`.
A later re-run of a newly bootstrapped project is
classified as existing because `docs/README.md` is now present; that is
a known limitation, not an overwrite of project docs. Details:
[Maintaining the harness](maintaining.md#re-run-bootstrap-on-a-project).

Agent-facing bootstrap checklist:
[.cursor/rules/50-workflows.mdc](../.cursor/rules/50-workflows.mdc).

## 6. Verify bootstrap

Bootstrap prints its own verification report (rules, skills, linked
scripts). Re-check from **either** side. Do not assume harness scripts
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

Installation success is:

1. Doctor passing on the **clone**.
2. Shared `00`–`70` rules in the project as **symlinks** into
   `$AI_PLATFORM/.cursor/rules/`.

Project doctor also diagnoses profile capabilities. On a Laravel app it
**fails** until Laravel Boost is declared, installed, and MCP-configured.
Treat that as a Laravel profile gap, not a failed harness link. Missing
Playwright on Laravel is a warning. Generic and Roots/Radicle projects
should get a clean project-doctor pass after bootstrap.

## 7. Next steps

| Situation | Next |
| --- | --- |
| Existing application | [Adopting projects](adopting-projects.md) |
| New / greenfield project | Fill `docs/` from the installed scaffold, then start implementation. Same adoption page. |
| Optional ChatGPT Project export | [ChatGPT Projects](chatgpt-projects.md) |
| Later updates, skills, uninstall | [Maintaining the harness](maintaining.md) |

## Help from your preferred LLM

If you want another model to walk you through setup, paste
[llm-support-prompt.md](llm-support-prompt.md) into that chat and point
it at this clone.
