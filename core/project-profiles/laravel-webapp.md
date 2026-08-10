# Laravel Web Application Profile

## Purpose

This profile applies to standard Laravel web applications built using
the preferred development stack.

## Technology Stack

Preferred stack (unversioned; subordinate to Current-First Engineering
in `00-platform` — establish installed or current stable versions before
implementation):

-   Laravel
-   Livewire
-   Blade
-   Tailwind CSS
-   Alpine.js
-   MariaDB

## Architecture

-   Follow Laravel conventions for the installed or intentionally
    selected ecosystem (Current-First Engineering in `00-platform`).
-   Keep controllers thin.
-   Place business logic in services or domain classes.
-   Keep models focused on persistence and relationships.
-   Prefer dependency injection.
-   Prefer existing patterns over introducing new ones.

## Development Principles

-   Keep solutions simple and maintainable.
-   Avoid unnecessary abstractions.
-   Make focused changes.
-   Do not perform unrelated refactoring.

## Documentation

Follow the `10-documentation` project rule.

Use contract-based documentation with `docs/README.md` as the dependency
graph. Maintain `docs/00-project-context.md` for ChatGPT context. Export
project AI context via `scripts/export-chatgpt-context.sh`.
