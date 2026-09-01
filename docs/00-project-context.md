# AI Development Harness

Version 1.2.0

Concise context for ChatGPT Projects and AI agents working on this
repository (`ai-platform`).

## What This Project Is

**AI Development Harness** is an agent-agnostic engineering harness for
AI-assisted software development. It standardizes architecture,
development, documentation, review, design, and project setup across
application repos. It owns reusable rules, skills, scripts, and
templates, not project business logic.

Public landing page: `../README.md`. Install: `getting-started.md`.

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
- Capability-on-demand: external tools are not capability-by-default.
  Tool availability is not authorization and is also not justification
  for using a tool. Prefer the smallest active toolset that can
  reliably accomplish the current work (`00-platform`, `mcp/README.md`).
- Never commit unless explicitly instructed.
- Do not modify dependencies without approval.
- Discovered work outside the current task is captured, not used to
  expand scope. GitHub Issues are the backlog; PRs represent
  implementation; merge requires developer approval. See
  `contracts/features/work-item-lifecycle.md`.
- Documentation conflicts must surface — never guess or silently override.
- Laravel Boost is project-native; the platform diagnoses it and does not
  write Boost MCP config.
- Playwright Mode A is expected only for browser-capable profiles (Laravel
  web applications), not every repository. Agent invocation of Playwright
  / browser automation is not generally authorized by tool availability.
  Availability is also not justification for using a browser tool the
  bounded task does not need. Significant UI authorizes a bounded Mode B
  visual pass of that UI only (`40-ui`, `60-browser-qa`). That pass uses
  the best available real-browser capability and is not Playwright
  execution. Agents must report which verification level actually
  occurred (static inspection, interactive real-browser verification, or
  automated Playwright/E2E). Significant
  motion may be observed in that pass; it does not by itself authorize
  Mode A or performance profiling.
- UI: product-specific, spacious, hierarchy-driven design. Avoid
  recognizable AI/template conventions. Cards are semantic containers,
  not decoration. Adjacent semantic sections must remain visually
  distinguishable; this is not a mandate to alternate section
  backgrounds. Meaningful motion is a specialized significant-UI
  concern, not a separate skill. Hard constraints (no decorative
  sequential numbering; no em dashes in generated end-user copy) live
  in `.cursor/rules/40-ui.mdc` and outrank Hallmark. Generated design
  images are exploration/reference artifacts, not implementation truth.
  Image generation is capability-on-demand and must not replace
  framework-native implementation or bounded Mode B verification.
- Tailwind: use the standard utility scale when an equivalent exists.
  Arbitrary values are last-resort exceptions, not a way to match a
  comp (`20-coding`).
- Secondary skills, MCP servers, plugins, and vendor/tool guidance
  cannot silently override project or platform rules. Clear conflicts
  follow the higher-authority rule; genuine ambiguity stops for
  clarification (ADR 0006).
- For applicable frontend or public-facing work, `scripts/check-guardrails.sh`
  is part of DONE validation. Lint, tests, and build passing do not
  imply it ran.
- User-global Cursor MCP (Playwright MCP, BrowserMCP) is configured in
  Cursor, not by bootstrap. Additional MCPs are not bootstrap
  dependencies. See `mcp/README.md`.

## Where to Look

| Need | Document |
| --- | --- |
| Public landing | `../README.md` |
| First-time clone / onboarding | `getting-started.md` |
| How the harness works | `how-it-works.md` |
| Project adoption | `adopting-projects.md`, `../core/prompts/project-adoption.md` |
| Updates / troubleshooting | `maintaining.md` |
| LLM support seed | `llm-support-prompt.md` |
| Documentation standard | `documentation-philosophy.md` |
| ChatGPT export workflow | `chatgpt-projects.md` |
| Cursor rules | `.cursor/rules/` |
| UI / design preferences | `.cursor/rules/40-ui.mdc`, ADR 0004 |
| Copy / Tailwind guardrails | `contracts/features/copy-and-tailwind-guardrails.md`, ADR 0006 |
| Fresh agent / resume | `working-mode.md`, `../core/prompts/resume.md` |
| Multi-agent adapters | `core/adapters/README.md` |
| Bootstrap behavior (agent) | `scripts/bootstrap-project.sh`, `.cursor/rules/50-workflows.mdc` |
| Issues / PRs / discovered work | `contracts/features/work-item-lifecycle.md` |
| Browser QA | `contracts/features/browser-qa.md` |
| Laravel Boost | `contracts/features/laravel-boost.md` |
| Roots/Radicle/Sage profile | `core/project-profiles/roots-radicle.md` |
| MCP ownership | `mcp/README.md` |
