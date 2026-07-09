# Documentation Maintenance Rule

## Principle

Project documentation is part of the implementation, not a separate
task.

Every meaningful code change must be evaluated to determine whether
project documentation also needs to change.

## Required Review

At the completion of every feature, refactor, bug fix, or architectural
change, determine whether any of the following require updates:

-   `docs/project.md`
-   `docs/architecture.md`
-   `docs/decisions.md`
-   `docs/roadmap.md`

## Document Responsibilities

### project.md

Maintain:

-   Purpose
-   Features
-   Business rules
-   Integrations
-   User-visible behavior

### architecture.md

Maintain:

-   System architecture
-   Folder structure
-   Major components
-   Services
-   External integrations
-   Data flow

### decisions.md

Record significant technical or architectural decisions including:

-   Decision
-   Reason
-   Alternatives considered (if relevant)
-   Impact

### roadmap.md

Maintain:

-   Planned features
-   Technical debt
-   Future improvements
-   Deferred work

## Completion Criteria

A task is not complete until:

1.  Code is complete.
2.  Tests or validation are complete.
3.  Documentation has been reviewed.
4.  Any required documentation updates have been made.

If no documentation changes are required, explicitly state:

> Documentation reviewed. No updates required.

Never allow project documentation to drift from the implementation.
