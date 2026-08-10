# AI Platform Context

Concise context for ChatGPT Projects and AI agents working on the shared AI
Platform repository.

## What This Project Is

The AI Platform standardizes how AI assists with architecture, development,
documentation, code review, design, and project setup across all development
projects. It owns reusable rules, skills, scripts, and templates — not
project business logic.

## Technology Stack

- Cursor project rules (`.cursor/rules/`)
- Agent skills (`.agents/skills/`)
- Bash automation scripts (`scripts/`)
- Markdown documentation contracts (`docs/`)

## Documentation Model

Documentation Contracts replace the legacy four-file layout. `docs/README.md`
is the dependency graph and contract registry. Project AI context exports to
ChatGPT via `scripts/export-chatgpt-context.sh`.

## Key Constraints

- Projects own business logic; the platform owns reusable knowledge.
- Current-first engineering: establish installed/current versions and
  official docs before relying on historical model knowledge (see
  `.cursor/rules/00-platform.mdc`).
- Never commit unless explicitly instructed.
- Do not modify dependencies without approval.
- Documentation conflicts must surface — never guess or silently override.

## Where to Look

| Need | Document |
| --- | --- |
| Documentation standard | `documentation-philosophy.md` |
| ChatGPT export workflow | `chatgpt-projects.md` |
| Cursor rules | `.cursor/rules/` |
| New project setup | `scripts/bootstrap-project.sh` |
