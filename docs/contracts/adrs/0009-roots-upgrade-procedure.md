---
status: accepted
last_reviewed: 2026-10-15
source_of_truth_for:
  - Decision that Roots upgrades use one harness procedure
  - Decision that the procedure does not change an existing project's Roots generation
  - Decision that project findings stay in the project planning contract
depends_on:
  - ../features/roots-upgrade.md
referenced_by:
  - ../features/roots-upgrade.md
type: adr
---

# ADR-0009: Roots upgrade procedure

## Status

Accepted

## Context

Existing WordPress projects use different generations and combinations
of Bedrock, Sage, Radicle, Acorn, and Bud. A security advisory or a
requested version bump was being handled as an ad hoc Composer or Yarn
update. That path treats the newest major as the target, ignores a
production PHP that is older than the developer machine, and can turn
a plugin patch into a Sage, Vite, or Tailwind migration.

The harness already has a place for this kind of reusable procedure:
a feature contract as the policy, a prompt as the session runbook, and
a short pointer in the stack rule and the always-on agent core.
Locked skills remain the design stack (Impeccable and Hallmark).
Bootstrap restores those skills from `skills-lock.json` and does not
install a third skill.

Project Adoption already preserves installed versions unless the
developer approves a change. An upgrade procedure must not run as a
side effect of adoption, and it must not rewrite a project's accepted
version ADR.

## Decision

- Roots upgrades and Roots security assessments use
  `docs/contracts/features/roots-upgrade.md`. The runbook is
  `core/prompts/roots-upgrade.md`. `.cursor/rules/35-roots.mdc` and
  `core/agent-core.md` point at those files. They do not restate the
  procedure.
- The procedure is generation-agnostic. It inventories the stack that
  is installed. It does not require Radicle, Bud, Sage 11, Vite, or
  the current Acorn major, and it does not apply the greenfield
  baseline to an existing project.
- A routine update of one named package inside its current constraint
  does not use the full procedure.
- Assessment is read-only until the user approves a stage. Newest-major
  upgrades, blanket lockfile updates, and forced dependency overrides
  are out of the procedure.
- Findings, targets, and approvals are written to the project's
  `docs/contracts/planning/roots-upgrade.md` (or the upgrade plan that
  project already has). They are not copied into the harness.
- This is not a new skill and not a new `skills-lock.json` entry.

## Consequences

### Positive

- Agents in an adopted project can find the procedure from the shared
  rules symlink and from `AGENTS.md`.
- Older Sage/Bud/Acorn projects and newer Radicle projects follow the
  same gates.
- Security work stays ranked by production exposure, and architectural
  migrations stay separately approved.

### Negative

- The agent must read the contract and the runbook. The stack rule is
  only the pointer.
- Official Acorn, Sage, Bud, and Radicle pairings change. The contract
  tells the agent to re-read those guides rather than shipping a
  permanent version matrix.

### Neutral

- Bootstrap, doctor, and Project Adoption do not upgrade application
  dependencies.
- Harness Deployer remains optional and is not an output of this
  procedure.
