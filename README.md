# AI Platform

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
-   Reusable vendor skills
-   Automatic documentation maintenance

## Repository Structure

-   `agents/` - Specialized AI agents
-   `core/` - Rules, profiles, standards, prompts, workflows, and custom
    skills
-   `mcp/` - MCP-specific guidance
-   `templates/` - Project templates
-   `vendor/` - Third-party skills and resources
-   `scripts/` - Automation scripts

## Project Philosophy

Projects own their business logic.

The AI Platform owns reusable knowledge.

Each project should contain only its own:

-   `.cursorrules`
-   Documentation
-   Business rules
-   Architecture
-   Implementation

Everything reusable belongs in this repository.

## Documentation

Documentation is considered part of the implementation and must remain
synchronized with the codebase throughout the life of every project.
