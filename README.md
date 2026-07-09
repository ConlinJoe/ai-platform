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
-   `core/project-profiles/` - Stack-specific project profiles
-   `scripts/` - Automation scripts (`bootstrap-project.sh`, `update-skills.sh`,
    `doctor.sh`)
-   `mcp/` - MCP-specific guidance
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

Documentation is considered part of the implementation and must remain
synchronized with the codebase throughout the life of every project.
