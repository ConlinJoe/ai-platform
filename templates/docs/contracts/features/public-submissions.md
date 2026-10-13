---
status: draft
last_reviewed: YYYY-MM-DD
source_of_truth_for:
  - Whether this project has public submission surfaces
  - Which of those endpoints are protected, and how
depends_on:
  - contracts/foundational/architecture.md
referenced_by: []
type: feature
---

# Public submissions

Record **this** project's public submission surfaces here.

The requirement (what counts, server-side enforcement, rate limits,
validation, tests, secrets, and rollout) lives in the AI Platform:
`docs/contracts/features/spam-and-abuse-protection.md`.
Do not copy that policy into this file.

## Applicability

`applicable` or `not applicable`.

If `not applicable`, say why no public endpoint creates a record, sends
mail, or triggers costly work, then stop.

## Endpoints

| Endpoint | What it does | Server-side protection | Rate limit | Tests | Environment variable names |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

Name variables only. Do not record secret values.

## Rollout

Which environments enforce protection, and what must be true before
enforcement is turned on for a live form.
