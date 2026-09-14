---
status: active
last_reviewed: 2026-09-14
source_of_truth_for:
  - Current working mode and agent continuation instructions
depends_on:
  - 00-project-context.md
  - 99-project-status.md
referenced_by: []
type: continuation
---

# Working mode

Operational continuation for a fresh agent. Not project context,
architecture, or a progress log.

## Mode

Bounded harness maintenance.

## Preserve

Shared architecture is frozen except when an explicit platform change
is requested. Follow Current-First, Framework-Native First,
capability-on-demand, routed Impeccable/Hallmark design stack, two-layer browser QA,
and the work-item lifecycle. Contracts and ADRs remain authoritative.
Do not modify consuming applications from this repository.

## Before editing

Read this file. Load only the platform rules, contracts, and ADRs the
requested change needs. Use `docs/README.md` to find them. Do not ingest
the whole documentation tree.

## Scope

One bounded platform change at a time. Capture out-of-scope discoveries;
do not expand the task.

## Do not

Do not commit or push unless instructed. Do not add machinery merely
because it is possible. Do not treat a long kickoff prompt or a long
completion report as the way to carry state between threads.
