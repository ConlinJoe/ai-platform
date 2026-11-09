---
status: accepted
last_reviewed: 2026-11-07
source_of_truth_for:
  - Decision that an authorized production deploy does not wait on a harness backup or restore check
  - Decision that code rollback is Git plus three Deployer releases
  - Decision that database, media, and server-image recovery belong to the operator
depends_on:
  - 0007-optional-deployer-capability.md
  - ../features/deployer.md
referenced_by:
  - 0007-optional-deployer-capability.md
  - ../features/deployer.md
  - ../../README.md
type: adr
---

# ADR-0012: Operator-managed production recovery

## Status

Accepted. Supersedes the production-backup requirement in ADR 0007.

## Context

ADR 0007 required a restorable production backup before an authorized
production deploy. The feature contract and the always-on rules
stopped that deploy when the backup could not be verified. The check
covered databases and uploads. It blocked fast, operator-managed
production deploys.

Code was already recoverable through Git and through Deployer's
release directories. `dep rollback` only repoints the `current`
symlink. Shared uploads and the database are not inside a release, so
rolling code back does not undo those changes. Server images are also
outside Deployer.

## Decision

- Production deployment stays a separate explicit authorization.
  Installing Deployer is still not that authorization.
- The harness does not require a pre-deploy database or uploads
  backup check, and it does not replace that check with another
  manual approval or restore verification.
- Git history and Deployer releases are the code record. Generated
  recipes set `keep_releases` to 3. Deployer counts the current
  release, so the two previous releases stay available for an instant
  code rollback.
- Server images, and recovery of databases or uploaded media, are the
  operator's responsibility.
- A Deployer rollback does not reverse database or upload changes.
- Existing releases are removed only by Deployer's own cleanup when a
  later deploy uses that retention. Do not delete them by another
  path. The installer does not rewrite an existing recipe.

## Consequences

### Positive

- An authorized production deploy is not blocked on a backup check
  the harness cannot perform.
- Code rollback stays immediate for the current release and two
  previous ones.

### Negative

- A bad migration or an upload change is not undone by `dep rollback`.
- The operator must already have whatever image or data recovery they
  consider sufficient. The harness does not check that.
- Projects that already installed a recipe keep that recipe's
  `keep_releases` value until the project changes it.

## Alternatives Considered

- Keep the backup gate. Rejected. It prevented the intended fast
  production deploys.
- Replace the gate with confirmation that a restore was rehearsed.
  Rejected. That is another manual approval.
- Keep more than two previous releases by default. Rejected. Two
  previous releases plus the current one is the rollback window.
  Older code remains in Git.
- Delete surplus releases on existing servers as part of this policy
  change. Rejected. Only Deployer's normal cleanup may remove them,
  and only on a later deploy that uses the new retention.
