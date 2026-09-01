---
status: active
last_reviewed: {{LAST_REVIEWED}}
source_of_truth_for:
  - Project-local Deployer installation notes for this application
depends_on: []
referenced_by: []
type: feature
---

# Deployment (Deployer)

The AI Development Harness installed the optional Deployer stack for
this project. **Installing or configuring that stack does not authorize
deployment.**

Canonical harness reference (in the harness clone, not this repo):
`docs/contracts/features/deployer.md`.

## What was installed

- Profile: `{{PROFILE}}`
- Recipe: `deploy.php` (harness-managed)
- Host template: `deploy/hosts.yaml.example`
- Local host file: `deploy/hosts.yaml` (gitignored, unconfigured)
- Dependency: `deployer/deployer` in Composer `require-dev` (declared;
  run `composer install` when you are ready; this installer does not)
- Runtime state directory `.dep/` is gitignored

## What remains unconfigured

Server-specific values are still placeholders. Fill `deploy/hosts.yaml`:

- `hostname` (host/IP or SSH alias)
- `remote_user`
- `deploy_path`
- `repository`
- `branch`
- optional `identity_file` and `bin/php`

Do not put passwords, tokens, private keys, or production secrets in
committed files.

{{PROFILE_NOTES}}

## Verify configuration

```bash
composer install
vendor/bin/dep config:hosts
```

That checks inventory parsing. It is not a deployment.

## First deployment

Deployment requires a **separate explicit instruction**. After that
authorization, and after a restorable production backup is verified
when the target is production:

```bash
vendor/bin/dep deploy production
```

## Rollback

```bash
vendor/bin/dep rollback production
```

Rollback stays inside Deployer's release history. It is not
authorization to destroy servers, DNS, or databases.

## Register this contract

Add `docs/contracts/features/deployment.md` to this project's
`docs/README.md` contract registry if it is not already listed.
