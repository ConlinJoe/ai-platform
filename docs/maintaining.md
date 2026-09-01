---
status: active
last_reviewed: 2026-09-01
source_of_truth_for:
  - Updating the harness clone and propagating changes
  - Skill update and restore
  - Doctor, troubleshooting, and removal
depends_on:
  - getting-started.md
  - adopting-projects.md
referenced_by:
  - ../README.md
  - README.md
  - llm-support-prompt.md
type: foundational
---

# Maintaining the harness

Canonical procedures for updates, validation, troubleshooting, and
removal. First-time setup: [Getting started](getting-started.md).

Commands below assume:

```bash
AI_PLATFORM="$HOME/src/ai-platform"
```

Change the path to wherever you cloned the harness.

## Update the harness clone

```bash
cd "$AI_PLATFORM"
git pull
./scripts/doctor.sh
```

Shared Cursor rules (`00`–`70`) in bootstrapped projects are **symlinks**
into this clone. They pick up rule changes as soon as the clone updates.
You do not edit each project's copies of the shared rules.

## Re-run bootstrap on a project

Re-run bootstrap in the project to reconcile managed files:

- prune retired managed skills that are no longer in the lockfile
- refresh Claude/Grok skill adapter links
- apply current bootstrap-managed project configuration
- add current ignore entries such as `.hallmark/`, `.DS_Store`, and `.ai/`
- link current platform scripts such as `scripts/check-guardrails.sh`

```bash
"$AI_PLATFORM/scripts/bootstrap-project.sh" /path/to/your-project
```

Re-bootstrap is not Project Adoption. It does not rewrite application
code. Skill copies that are already installed are not refreshed unless
they are missing or you restore from the linked lockfile (below).
A re-run does not replace an existing Deployer strategy. To add the
optional Deployer stack later without a full bootstrap:

```bash
"$AI_PLATFORM/scripts/install-deployer.sh" /path/to/your-project
```

**Known limitation.** New versus existing is the presence of
`docs/README.md`. After the first bootstrap of a new project that file
exists, so a later re-run classifies the project as existing. It may
add a draft `docs/contracts/foundational/platform-reconciliation.md`
and print the existing-project adoption prompt. It still does not
overwrite project docs. A greenfield project can ignore that prompt and
omit or delete the unused reconciliation draft. Do not treat this as a
signal to run Project Adoption on an app you just scaffolded.

If you **moved** the harness clone, re-run bootstrap in every adopted
project so symlink targets match the new absolute path.

## Update managed skills

In this clone only:

```bash
cd "$AI_PLATFORM"
./scripts/update-skills.sh
```

That runs `npx skills update -p -y`. Review the git diff before
committing. `update-skills.sh` is not linked into target projects.

Re-running project bootstrap restores **missing** skills; it does not
refresh skill copies that are already installed. To restore project
skills from the linked lockfile:

```bash
cd /path/to/your-project
npx skills experimental_install
```

The same restore command is used in the harness clone if
`.agents/skills/hallmark` is missing after clone. It requires network
access; see [Getting started](getting-started.md#2-configure-the-harness-clone).

## Validate

Harness clone:

```bash
cd "$AI_PLATFORM"
./scripts/doctor.sh
./scripts/test-platform.sh   # optional; for changes to this repository
./scripts/check-guardrails.sh
```

Bootstrapped project:

```bash
"$AI_PLATFORM/scripts/doctor.sh" /path/to/your-project
# after bootstrap, this is the same script via symlink:
/path/to/your-project/scripts/doctor.sh
```

For frontend or public-facing application work in a project, run
`scripts/check-guardrails.sh` from that project before treating the
task as done. Lint, tests, and build passing do not imply that check
ran.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Doctor fails on the clone | Missing rules, Hallmark skill, or non-executable scripts. Re-run `chmod +x scripts/*.sh scripts/lib/*.sh`. Restore skills if `.agents/skills/hallmark` is missing. |
| Doctor fails on a project | First confirm `ls -l project/.cursor/rules` shows symlinks into `$AI_PLATFORM`. If those links are missing or stale, re-run bootstrap. If the links are correct and the project is Laravel, a FAIL for missing Boost is expected until `laravel/boost` is declared, installed, and MCP-configured. |
| Rules in the project are real files, not symlinks | Bootstrap prompts before replacing a real file. Shared `00`–`70` rules should be symlinks into the clone. |
| Agent ignores detailed `.mdc` rules | Expected on some non-Cursor clients. Read [core/adapters/README.md](../core/adapters/README.md). The portable core still applies via `AGENTS.md`. |
| Laravel agent files lack the portable core | Boost may own `AGENTS.md` / `CLAUDE.md`. Confirm `.ai/guidelines/ai-platform.md` is linked, then run `php artisan boost:install` or `boost:update`. |
| Skills missing in a project | `npx skills experimental_install` from the project root (lockfile must be the symlink). Bootstrap skips restore when you decline the prompt. |
| `npx skills` mutates the clone lockfile | Bootstrap snapshots and restores `skills-lock.json` for that reason. Prefer bootstrap's restore path. |
| Browser automation ran unexpectedly | Availability is not authorization. Policy: [60-browser-qa](../.cursor/rules/60-browser-qa.mdc). |
| Deployer prompt or install looked like a deploy | Installing the stack is not authorization to deploy. Contract: [Deployer capability](contracts/features/deployer.md). |
| Unsure whether install worked | Doctor pass on the clone, then `ls -l project/.cursor/rules` showing links into `$AI_PLATFORM/.cursor/rules/`. Project doctor may still FAIL on Laravel until Boost is present. |
| Claude or Grok skills missing after bootstrap | Confirm `.agents/skills/hallmark` exists, then re-run bootstrap so `.claude/skills/` and `.grok/skills/` adapter links are created. |

If documentation and scripts disagree, treat the scripts and
`.cursor/rules/` as implementation truth and report the docs conflict.
Do not invent a third procedure.

## Remove the harness from a project

There is **no uninstall script**. Removal is reversing what bootstrap
added. Project-owned docs, `90-*.mdc`, and application code stay unless
you delete them.

Typical leftovers to remove if you no longer want the harness:

- Symlinks in `.cursor/rules/` whose targets are inside the harness
  clone (`00`–`70` `*.mdc`, not your `90-*.mdc`)
- `scripts/doctor.sh`, `scripts/export-chatgpt-context.sh`,
  `scripts/check-guardrails.sh` if they are symlinks into the clone
- `skills-lock.json` if it is a symlink into the clone
- `.agents/skills/` copies that came from the lockfile, plus
  `.claude/skills/` and `.grok/skills/` adapter links
- Laravel-only `.ai/guidelines/ai-platform.md` if it is a symlink to
  `core/agent-core.md`
- `AGENTS.md` / `CLAUDE.md` only if you added them via bootstrap and
  no longer want them (do not delete Boost-owned files without a plan)

Ignore entries (`.build/`, `.hallmark/`, `.DS_Store`, `.ai/`,
Playwright artifact paths)
are ordinary `.gitignore` lines; remove them only if you want that.

After removal, coding agents in that project no longer load harness
rules.
