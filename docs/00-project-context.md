# AI Development Harness

Concise context for ChatGPT Projects and AI agents working on this
repository (`ai-platform`).

## What This Project Is

**AI Development Harness** is an agent-agnostic engineering harness for
AI-assisted software development. It standardizes architecture,
development, documentation, review, design, and project setup across
application repos. It owns reusable rules, skills, scripts, and
templates — not project business logic.

Internal scripts and clone paths still use `AI_PLATFORM` / `ai-platform`.

## Technology Stack

- Cursor project rules (`.cursor/rules/`) — reference implementation
- Agent-neutral core (`core/agent-core.md`, `AGENTS.md`, `CLAUDE.md`)
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
- Framework-Native First: use the installed stack's native capabilities
  before custom implementations, parallel abstractions, or new
  dependencies (see `.cursor/rules/00-platform.mdc`).
- Never commit unless explicitly instructed.
- Do not modify dependencies without approval.
- Documentation conflicts must surface — never guess or silently override.
- Laravel Boost is project-native; the platform diagnoses it and does not
  write Boost MCP config.
- Playwright Mode A is expected only for browser-capable profiles (Laravel
  web applications), not every repository. Agent invocation of Playwright
  / browser automation is opt-in: do not run it unless the current task
  explicitly authorizes it.
- User-global Cursor MCP (Playwright MCP, BrowserMCP) is configured in
  Cursor, not by bootstrap. See `mcp/README.md`.

## Where to Look

| Need | Document |
| --- | --- |
| Documentation standard | `documentation-philosophy.md` |
| ChatGPT export workflow | `chatgpt-projects.md` |
| Cursor rules | `.cursor/rules/` |
| First-time clone / onboarding | `../README.md`, `mcp/README.md` |
| Multi-agent adapters | `core/adapters/README.md` |
| New / existing project setup | `scripts/bootstrap-project.sh`, `.cursor/rules/50-workflows.mdc` |
| Existing project adoption | `core/prompts/project-adoption.md` |
| Browser QA | `contracts/features/browser-qa.md` |
| Laravel Boost | `contracts/features/laravel-boost.md` |
| Roots/Radicle/Sage profile | `core/project-profiles/roots-radicle.md` |
| MCP ownership | `mcp/README.md` |
