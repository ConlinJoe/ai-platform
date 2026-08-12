# AI Platform

Version 1.1.1

This repository contains the shared AI platform used across all
development projects.

Its purpose is to standardize how AI assists with architecture,
development, documentation, code review, design, and project setup while
keeping project-specific context inside each individual repository.

## Goals

-   Consistent AI behavior across all projects
-   Shared development standards
-   Shared workflows
-   Shared prompts
-   Shared agent profiles
-   Reusable project skills
-   Automatic documentation maintenance

## Repository Structure

-   `.cursor/rules/` - Shared Cursor project rules
-   `.agents/` - Third-party skills (managed via `skills-lock.json`)
-   `agents/` - Specialized AI agents
-   `core/` - Project profiles, prompts, and custom skills
-   `scripts/` - Automation scripts (`bootstrap-project.sh`, `export-chatgpt-context.sh`,
    `update-skills.sh`, `doctor.sh`, `test-platform.sh`)
-   `mcp/` - MCP ownership guidance (Boost is project-native; browser MCP is
    typically user-global)
-   `templates/` - Project templates
-   `docs/` - Platform documentation
-   `experiments/` - Experimental work
-   `skills-lock.json` - Locked skill versions
-   `CHANGELOG.md` - Release history

## Project Philosophy

Projects own their business logic.

The AI Platform owns reusable knowledge.

Each project should contain only its own:

-   `.cursor/rules/` (linked from AI platform)
-   Documentation
-   Business rules
-   Architecture
-   Implementation

Everything reusable belongs in this repository.

## Documentation

Documentation is a collection of **contracts** — focused documents with
single responsibilities, metadata, and declared dependencies.

- `docs/README.md` — dependency graph and contract registry
- `docs/00-project-context.md` — concise entry point for ChatGPT Projects
- `scripts/export-chatgpt-context.sh` — exports project AI context to
  `.build/chatgpt-context.zip`

Agents load only contracts relevant to the current task. Every
implementation must update affected contracts, explicitly state why no update
is required, or stop and report a documentation conflict.

Browser-capable Laravel web apps follow two-layer browser QA
(`docs/contracts/features/browser-qa.md`). Laravel Boost is required and
project-native (`docs/contracts/features/laravel-boost.md`).

See `docs/documentation-philosophy.md` and `docs/chatgpt-projects.md`.
