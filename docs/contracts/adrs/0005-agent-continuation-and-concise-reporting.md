---
status: accepted
last_reviewed: 2026-08-26
source_of_truth_for:
  - Decision to store agent continuation in docs/working-mode.md
  - Decision that concise completion reporting is the default
depends_on:
  - ../../documentation-philosophy.md
referenced_by:
  - ../../../.cursor/rules/00-platform.mdc
  - ../../../.cursor/rules/10-documentation.mdc
  - ../../../core/agent-core.md
type: adr
---

# ADR-0005: Agent continuation and concise reporting

## Status

Accepted

## Context

The harness uses a fresh agent thread per bounded task. That keeps
context clean, but it previously required a large human-authored kickoff
prompt restating rules, contracts, phase, and constraints. At the other
end, agents often wrote long completion reports that then became
expensive thread context.

Project context, status, ADRs, and contracts already exist. The missing
piece was a small continuation record: how a fresh agent should operate
*now*, without duplicating those sources of truth.

## Decision

1. Store agent continuation state in `docs/working-mode.md`. It names
   the current working mode, what to preserve, minimum orientation,
   in-mode scope, and mode-specific prohibitions. It stays small and
   points at authoritative docs instead of copying them.
2. `docs/00-project-context.md` remains identity, stack, and standing
   constraints. `docs/99-project-status.md` remains progress,
   validation, and readiness.
3. Always-on agent instructions tell a fresh session to read
   `docs/working-mode.md` before the first edit, then load further docs
   only as the task requires. An orientation-only prompt lives at
   `core/prompts/resume.md`. The human's normal fresh-thread input is
   the bounded task itself.
4. Update working-mode only when the working mode itself changes, not
   after routine bounded tasks.
5. Concise completion reporting is the default. Durable facts that a
   future thread needs belong in the appropriate project document, not
   in a long chat report.

## Consequences

### Positive

- Fresh threads start from a few lines of human instruction.
- Continuation state survives across many bounded threads.
- Status files can grow without being reread in full on every resume.
- Completion output does not unnecessarily consume the context window.

### Negative

- A stale working-mode file misleads later agents. Updates are required
  at real mode transitions.
- Agents must not treat working-mode as architecture or as a second
  project-context document.

## Alternatives considered

- A numbered `98-agent-handoff.md` beside status — rejected; filename
  should reflect responsibility, not adjacency.
- Folding continuation into `99-project-status.md` — rejected; status
  files accumulate progress history and would defeat token conservation.
- Folding continuation into `00-project-context.md` — rejected; context
  changes on a different cadence and is the ChatGPT identity entry.
- A Cursor-only slash command as the durable mechanism — rejected;
  Cursor conveniences are optional. Continuation must remain a project
  file other agents can read.
- Ingesting the full `docs/` tree on resume — rejected; progressive
  disclosure is required.
