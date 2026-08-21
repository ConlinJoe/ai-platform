---
status: draft
last_reviewed: YYYY-MM-DD
source_of_truth_for:
  - Classified differences from AI Platform defaults (A/B/C/D)
  - Open remediations that must not be silently blessed
depends_on:
  - contracts/foundational/architecture.md
referenced_by: []
type: foundational
---

# Platform Reconciliation

This contract records where this **existing** project differs from current
AI Platform defaults.

Inspect the real project first. Platform bootstrap is not a migration
engine. Code and architecture changes outside documentation/bootstrap
require developer approval.

## A. Sound existing decisions

Documented and preserved. Durable detail belongs in architecture or ADRs;
this list is the index.

| Topic | Decision | Where documented |
| --- | --- | --- |
| | | |

## B. Reasonable differences from platform preferences

Legitimate project-specific choices. Do not change them merely for
conformity.

| Topic | Platform default | This project | Why it remains |
| --- | --- | --- | --- |
| | | | |

## C. Recommended remediations

Gaps versus current platform, framework, architecture, testing, security,
or maintainability expectations that are **not** accepted yet. Surface
these to the developer. Do not treat presence in this section as
approval. Do not implement until approved.

For each material item, record:

- Current state
- Problem
- Recommended state
- Reason
- Expected impact
- Migration / risk (when relevant)
- Status: proposed | approved | deferred | rejected

| Topic | Gap | Recommended state | Status |
| --- | --- | --- | --- |
| | | | |

## D. Questions for the developer

Decisions that cannot safely be inferred from the repository. Grouped;
not facts the repo already establishes.

- Question
