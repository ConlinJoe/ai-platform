---
status: accepted
last_reviewed: 2026-09-01
source_of_truth_for:
  - Decision to offer Deployer as the standardized optional deployment foundation
  - Decision that Deployer remains capability-on-demand
  - Decision that bootstrap does not infer arbitrary existing deployment strategies
depends_on:
  - ../features/deployer.md
referenced_by:
  - ../features/deployer.md
type: adr
---

# ADR-0007: Optional Deployer capability

## Status

Accepted

## Context

Every new or existing project that needed SSH-based PHP deployments was
re-deriving the same Deployer foundation by hand. That work is
repetitive, easy to get slightly wrong per framework, and easy to
confuse with authorization to deploy.

The harness already has optional, diagnosed capabilities (for example
Playwright on Laravel) and required-but-project-native ones (Laravel
Boost). Deployment is different: not every project deploys with
Deployer, existing projects may already have a strategy, and
installing tooling must never be treated as permission to change
production.

A previously discussed project-local `.ai/` portability architecture is
explicitly out of scope. The current absolute-symlink bootstrap remains
unchanged.

## Decision

- Deployer 8 (`deployer/deployer` as a project `require-dev` dependency)
  is the **standardized optional** deployment foundation for supported
  PHP project types: Laravel, Bedrock/Sage (Roots), Bedrock without
  Sage, and conventional WordPress.
- The capability is **capability-on-demand**: available from the
  harness, installed only when selected, absent without doctor
  warnings, independently installable later via
  `scripts/install-deployer.sh`.
- Bootstrap may prompt `Install Deployer deployment stack? [y/N]`
  (default N) or honor `--with-deployer` / `--without-deployer`.
  Selecting install authorizes only the Deployer dependency and
  harness-managed files. It does **not** authorize deployment.
- Bootstrap and the installer ask only whether the **harness-managed**
  Deployer stack is present. They do not audit GitHub Actions, Envoyer,
  Forge, CI/CD, or hosting-provider deploys.
- Framework-specific recipes are required. One `deploy.php` is not
  assumed to work for every stack. Shared behavior (hosts file,
  gitignore, keep_releases, no secrets, no deploy invocation) stays in
  installer helpers.
- Host and secret configuration live in gitignored `deploy/hosts.yaml`,
  not in `deploy.php`.
- Current-First: existing Deployer configuration is preserved. Conflicts
  stop that installation path. Incomplete existing recipes are not
  rewritten.
- Actual deployment remains a separate, explicit authorization. A
  restorable production backup is required before an authorized
  production deploy. Catastrophic operations remain forbidden.

## Consequences

### Positive

- New and existing projects can get a consistent Deployer foundation
  without repeating the same files by hand.
- Developers who do not want Deployer are not forced into it.
- Agents cannot treat bootstrap or "set up Deployer" as a deploy.
- Existing deployment strategies are not silently replaced.

### Negative

- Unsupported stacks must still be wired by the developer.
- Declaring `deployer/deployer` does not install vendor packages;
  `composer install` remains a later step.
- Server, DNS, and web-server document-root work remain outside the
  harness.

## Alternatives Considered

- Mandatory Deployer on every bootstrap — rejected; capability-on-demand
  and many projects already deploy another way.
- Inferring Forge/Envoyer/GitHub Actions and skipping the prompt —
  rejected; too many false positives and not the question being asked.
- A global `dep` binary on the operator machine — rejected; prefer a
  project-owned, reproducible Composer dependency.
- One recipe for all PHP apps — rejected; document root, shared paths,
  and build steps differ.
- Project-local `.ai/` snapshots of the harness — rejected for this
  release; symlink architecture stays as it is.
- Third-party Bedrock recipe packages — rejected for the default stack;
  compose Deployer's native recipes plus conservative Bedrock/Sage
  path configuration.
