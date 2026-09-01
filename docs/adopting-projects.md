---
status: active
last_reviewed: 2026-08-28
source_of_truth_for:
  - Human overview of new versus existing project adoption
  - What bootstrap changes in a project
  - Where to customize project-specific standards
depends_on:
  - getting-started.md
  - how-it-works.md
referenced_by:
  - ../README.md
  - README.md
  - maintaining.md
  - llm-support-prompt.md
type: foundational
---

# Adopting projects

Bootstrap links the harness into a project. Adoption teaches the harness
what that project actually is. Do not treat bootstrap as adoption.

Install the clone first: [Getting started](getting-started.md).

Canonical agent prompt for existing projects:
[core/prompts/project-adoption.md](../core/prompts/project-adoption.md).
`core/prompts/existing-project-bootstrap.md` is a compatibility alias
for the same prompt.

Agent workflow rules:
[.cursor/rules/50-workflows.mdc](../.cursor/rules/50-workflows.mdc).

## How invasive is this?

Bootstrap adds and links files. It does **not**:

- rewrite application code
- upgrade or change installed framework or library versions
- install Composer, npm, or WordPress packages
- install MCP servers
- copy or overwrite `.github/` templates
- overwrite existing `docs/` when `docs/README.md` already exists
- overwrite existing `AGENTS.md` or `CLAUDE.md`
- create `.hermes.md`

It does:

- symlink shared `00`–`70` rules into `.cursor/rules/`
- symlink doctor, ChatGPT export, and guardrail scripts
- symlink `skills-lock.json` and restore missing locked skills
- copy documentation **templates** only when the project has no docs
  index
- add missing draft files on existing projects (working mode, status,
  reconciliation, Laravel browser QA)
- ensure ignore entries such as `.build/`, `.hallmark/`, `.DS_Store`,
  and `.ai/`

You can adopt incrementally: bootstrap so agents load shared rules, then
run Project Adoption when you are ready to document and reconcile.

## New (greenfield) projects

There is no separate scaffold command in this repository. Create the
app with your usual stack tooling, then bootstrap.

1. Bootstrap from the project root.
2. Fill `docs/00-project-context.md`, `docs/working-mode.md`, and the
   foundational contracts from the **installed** scaffold, not from
   generic platform assumptions.
3. Do not start substantive feature work while contracts still contain
   only template placeholders.
4. Follow Current-First: the selected/installed stack is the starting
   point. Do not upgrade dependencies merely because newer versions
   exist.

Laravel and Roots/Radicle/Sage have additional profile notes in
`core/project-profiles/`. Do not apply a profile to a project that is
not that stack.

## Existing projects

Sequence: **Bootstrap → Adopt → Reconcile → Approve → Align.**

After bootstrap, in the **target** repository:

1. Open or reload the project in the current coding agent.
2. Start a **fresh** session.
3. Follow `$AI_PLATFORM/core/prompts/project-adoption.md`
   (bootstrap prints this path). From the project you can also resolve
   it:

```bash
AI_PLATFORM="$(cd "$(dirname "$(readlink .cursor/rules/00-platform.mdc)")/../.." && pwd)"
echo "$AI_PLATFORM/core/prompts/project-adoption.md"
```

Lifecycle: **Understand → Document → Compare → Question → Recommend →
Approve → Align**

The agent should establish or update project context, architecture,
ADRs, applicable contracts, roadmap/status, `90-*.mdc` rules when
needed, and
`docs/contracts/foundational/platform-reconciliation.md`.

Findings use A/B/C/D:

| Class | Meaning |
| --- | --- |
| **A** | Sound. Document and preserve. |
| **B** | Reasonable difference from harness preference. Document; do not change merely for conformity. |
| **C** | Outdated, unsafe, or structurally problematic. Recommend a change; do not implement yet. |
| **D** | Cannot safely be inferred. Ask you (grouped). |

Sound decisions and installed versions are preserved. Material
remediation needs your approval. Rejected C items are recorded as B.
Deferred work goes on the roadmap.

Existing Issue/PR/branch conventions are respected. Bootstrap does not
create GitHub infrastructure.

## What happens to existing versions and architecture?

Current-First Engineering is a harness rule: the installed environment
is technical reality. Adoption documents that reality. It does not
silently migrate the app onto a preferred stack.

Architectural decisions become ADRs and contracts so later agents do
not re-litigate them. If a contract and the code disagree, the agent
must stop and report the conflict rather than guessing.

## Where to customize

| Need | Where |
| --- | --- |
| Standards for **all** your projects | Edit shared rules in the harness clone (`.cursor/rules/00`–`70`) |
| Standards for **one** project | `.cursor/rules/90-*.mdc` plus that project's `docs/` |
| Architecture and product truth | Project contracts and ADRs |
| How a fresh agent should operate now | `docs/working-mode.md` |
| Visual language already in the product | Keep it. `40-ui` applies to new work; adoption does not silently restyle the existing UI |

Do not edit shared rules through the project's symlinks. Change them in
the clone so every bootstrapped project receives the same update.

## Daily usage after adoption

Work inside the **target** repository, not this clone.

- Linked `00`–`70` rules apply in Cursor; `AGENTS.md` / `CLAUDE.md`
  apply in Codex, Claude Code, Grok Build, and Hermes.
- `docs/working-mode.md` is current working mode for a fresh agent.
  Update it when that mode changes, not after every task.
- Start a fresh thread by stating the bounded task. Always-on rules
  load working mode automatically; no kickoff prompt is required.
- Orientation only: follow `$AI_PLATFORM/core/prompts/resume.md`, or
  say: Resume from `docs/working-mode.md`. Do not edit yet.
- Existing projects that lack working mode: re-run bootstrap to add the
  draft, then fill it.
- Work discovered outside the current task should normally be captured
  as a GitHub Issue (or host equivalent), not fixed in the same
  session. See [work-item lifecycle](contracts/features/work-item-lifecycle.md).
  `gh` is optional. Existing project Issue/PR/branch conventions are
  respected.
- Do not run Playwright or browser MCP unless the current task
  authorizes it (`60-browser-qa`). Significant UI authorizes a bounded
  Mode B visual pass of that UI only (`40-ui`).
- After documentation, rule, or skill changes in a project, you may
  export ChatGPT context: [ChatGPT Projects](chatgpt-projects.md).

## How updates reach projects

Shared `00`–`70` rules are symlinks. After you `git pull` the harness
clone, those projects receive the new rules immediately.

Re-run bootstrap to reconcile **managed** files (retired skills, adapter
links, ignore entries, newly added platform scripts). Re-bootstrap is
not Project Adoption and does not rewrite application code.

Details: [Maintaining the harness](maintaining.md).
