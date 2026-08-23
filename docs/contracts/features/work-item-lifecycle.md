---
status: active
last_reviewed: 2026-08-23
source_of_truth_for:
  - Provider-neutral work-item lifecycle
  - Capture-don't-expand-scope behavior during coding sessions
  - GitHub Issues, Pull Requests, and gh as the current reference implementation
  - Approval boundaries for Issues, branches, PRs, commits, pushes, and merges
  - Distinction between Issues, PRs, contracts/ADRs, and roadmap/status
  - Existing-project GitHub convention inspection during adoption
depends_on:
  - ../adrs/0003-work-item-lifecycle.md
referenced_by:
  - ../adrs/0003-work-item-lifecycle.md
  - ../../../.cursor/rules/70-work-items.mdc
  - ../../../.cursor/rules/50-workflows.mdc
  - ../../../.cursor/rules/10-documentation.mdc
  - ../../../core/prompts/project-adoption.md
  - ../../../README.md
type: feature
---

# Work-item lifecycle

Lightweight workflow for capturing work and turning it into reviewable
implementation. This is not a project-management system.

**Capture, don't expand scope.**

## Provider-neutral lifecycle

**Work item → branch → implementation → review request → approval → merge**

GitHub Issues, Pull Requests, and `gh` are the current reference
implementation of that lifecycle. The harness remains useful on other
hosts. Do not introduce GitHub-specific assumptions into unrelated core
engineering standards.

The GitHub mapping is:

| Lifecycle step | GitHub reference |
| --- | --- |
| Work item (not started) | Issue |
| Active implementation | Branch |
| Reviewable implementation | Pull Request |
| Approval / merge | Developer-approved merge |

The workflow is agent-independent (Cursor, Grok Build, Codex, Claude
Code, Hermes). Where an agent can talk to GitHub through approved native
tooling, MCP, `gh`, or another supported mechanism, it may do so **after
developer authorization**.

## Canonical GitHub lifecycle

**Discovered work → GitHub Issue → Implementation branch → Bounded agent
task → Implementation + verification → Pull Request → Review/approval →
Merge**

## Scope control during an active coding session

If the agent discovers a bug, improvement, refactor, technical debt, or
feature outside the current bounded task:

1. Do not fix it opportunistically.
2. Do not silently expand scope.
3. Determine whether it should be captured for later.
4. Briefly tell the developer what was discovered.
5. Offer to create a GitHub Issue (or the host's work-item equivalent).
6. Continue the current task unless the discovery blocks it.

If the problem blocks the current task, explain why and ask how to
proceed. Do not create the Issue, branch, or fix unless authorized.

Discovery is a **recommendation to capture**, not a GitHub mutation.

## GitHub Issues

Issues are the default backlog for work that has **not begun**.

Appropriate examples:

- bugs discovered during unrelated work
- deferred feature requests
- technical debt
- future improvements
- architectural follow-ups
- non-blocking security improvements
- UX/design improvements
- test coverage gaps worth addressing separately

Issues should be concise but contain enough context that a fresh coding
agent can understand the task later. Canonical project documentation
remains authoritative; the Issue supplies task context.

Recommended structure (omit sections that add no value):

### Problem

What is wrong or what opportunity exists.

### Expected outcome

What should be true when resolved.

### Relevant context

Affected area, files/components where known, constraints, related
decisions/contracts, reproduction information where applicable.

### Acceptance criteria

A short checklist defining completion where useful.

Do not over-document trivial issues. The harness does not ship Issue
templates; agents generate this structure when creating an Issue.

## Pull Requests

A PR represents **implementation**, not future intent.

Do not create empty PRs as backlog items.

Normal lifecycle:

Issue → branch → implementation → tests/verification → documentation
updates where required → PR

A PR should reference its Issue when one exists.

PR descriptions should concisely explain:

- what changed
- why
- verification/tests performed
- relevant documentation/ADR/contract changes
- known limitations or follow-up work

Do not use the PR to expand scope. Follow-up work belongs in a new Issue.

This repository's template: `.github/PULL_REQUEST_TEMPLATE.md`.
Optional copy for other projects: `templates/github/PULL_REQUEST_TEMPLATE.md`.
Bootstrap does not install GitHub templates into target projects.

## Branch conventions

Prefer the repository's existing convention when one exists. Do not
rename existing branches merely to conform.

Default when the repo has no convention:

- `fix/<short-description>`
- `feature/<short-description>`
- `refactor/<short-description>`
- `docs/<short-description>`

## Implementing from an Issue

Fresh agent threads remain preferred for bounded implementation tasks.

1. Read applicable harness rules (`00-platform`, this workflow, stack
   rules that apply).
2. Read current project status/context.
3. Read the Issue.
4. Read relevant ADRs/contracts/architecture.
5. Establish the bounded implementation scope.
6. Create or use the appropriate branch **when the developer has
   authorized implementation**.
7. Implement.
8. Test/verify proportionately. Do not run Playwright or browser
   automation unless the current task authorizes it.
9. Update project documentation when required
   (`.cursor/rules/10-documentation.mdc`).
10. Create the PR when explicitly requested or when the developer
    invokes the PR workflow.

## Approval boundaries

Preserve existing git safety rules. The agent must **not** automatically:

- create an Issue
- create a branch
- create a Pull Request
- merge a Pull Request
- delete a branch
- commit
- push

unless the developer authorizes that action under existing harness
rules.

**Never auto-merge.** Merge remains a developer approval boundary.

Creating an Issue, starting implementation, creating a branch, opening a
PR, committing, and pushing are separate authorizations. Implementing an
Issue does not by itself authorize opening a PR, committing, or pushing.

## GitHub CLI

`gh` is **optional** tooling for Issues and Pull Requests.

- Use `gh` when it is available **and** the developer has authorized the
  GitHub action.
- The developer owns installation and authentication.
- Bootstrap does not install or authenticate `gh`.
- Doctor does not require `gh`.
- Absence of `gh` must not prevent normal development. Offer the Issue
  or PR body for the GitHub UI, or use another authorized mechanism.

Do not make `gh` a mandatory bootstrap dependency. Do not install or
authenticate it automatically.

## Documentation relationship

GitHub Issues are **not** a replacement for canonical project documentation.
Do not maintain the same detailed backlog in multiple places.

| Artifact | Owns |
| --- | --- |
| Project docs / ADRs / contracts | Architecture, decisions, behavior, constraints, current project truth |
| GitHub Issues | Discrete future work that has not started |
| Pull Requests | A specific implementation / change set |
| Project status / roadmap | Meaningful project-level progress and direction |

Roadmaps summarize direction. They do not duplicate every Issue.

## Project Adoption

During adoption of an existing project, inspect whether it already has:

- Issue conventions
- PR templates
- branch conventions
- contribution guidelines
- GitHub Actions tied to PRs

Preserve reasonable existing conventions rather than replacing them.
If existing conventions materially conflict with harness safety or
approval rules (for example agent auto-merge, or agents that commit and
push by default), surface the difference during reconciliation.

Do not create GitHub infrastructure merely because the project was
adopted. Do not overwrite existing GitHub files during bootstrap.
