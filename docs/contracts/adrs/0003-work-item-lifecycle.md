---
status: accepted
last_reviewed: 2026-08-23
source_of_truth_for:
  - Decision to use a provider-neutral work-item lifecycle
  - Decision that GitHub Issues, Pull Requests, and gh are the current reference implementation
  - Decision that discovered work is captured rather than used to expand the current task
depends_on:
  - ../features/work-item-lifecycle.md
referenced_by:
  - ../features/work-item-lifecycle.md
  - ../../../.cursor/rules/70-work-items.mdc
type: adr
---

# ADR-0003: Provider-neutral work-item lifecycle

## Status

Accepted

## Context

Coding agents discover bugs, improvements, technical debt, and features
while doing unrelated work. Fixing those discoveries in the same session
expands scope, mixes review surfaces, and leaves no durable record for a
later bounded task.

The harness also needs a lightweight way to turn planned work into
reviewable implementation. That must not become a project-management
system, must not require GitHub, and must not weaken existing git
approval boundaries.

## Decision

The harness uses a provider-neutral lifecycle:

**Work item → branch → implementation → review request → approval → merge**

GitHub Issues, Pull Requests, and the GitHub CLI (`gh`) are the current
**reference implementation**, not a required hosting provider.

Issues (work items) represent work that has **not started**. Pull Requests
(review requests) represent implementation that has a branch and is ready
for review. Empty PRs are not backlog items.

Discovered work outside the current bounded task is captured, not fixed
opportunistically. The agent recommends capture; it does not create
Issues, branches, PRs, commits, pushes, or merges unless the developer
authorizes that action. Merge is always a developer approval boundary.
Never auto-merge.

`gh` is optional tooling. Bootstrap does not install or authenticate it.
Absence of `gh` must not block normal development.

Existing project Issue, PR, branch, and contribution conventions are
inspected during Project Adoption and preserved when reasonable.

Canonical project documentation (contracts, ADRs, status, roadmap)
remains authoritative for architecture and current truth. Issues track
discrete future work. They do not replace docs.

## Consequences

### Positive

- Out-of-scope discoveries can be recorded without expanding the session.
- Fresh agent threads can implement from an Issue with enough context.
- Review stays attached to a real change set, not to future intent.
- Non-GitHub hosts can use the same lifecycle with local equivalents.

### Negative

- Developers must authorize GitHub mutations; capture is not automatic.
- Projects not hosted on GitHub need an equivalent work-item and review
  mechanism if they want the same tracking.

## Alternatives Considered

- Fix discovered work in the same session — rejected; expands scope.
- Empty PRs as backlog — rejected; a PR represents implementation.
- Mandatory GitHub CLI / GitHub hosting — rejected; the harness must
  remain useful outside GitHub.
- Heavyweight project-management fields, boards, and Issue templates —
  rejected; Issues stay concise, and agents can structure them.
- Auto-merge after CI — rejected; merge remains a developer approval
  boundary.
