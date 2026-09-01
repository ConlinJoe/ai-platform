---
status: active
last_reviewed: 2026-09-01
source_of_truth_for:
  - Optional Deployer capability behavior
  - Bootstrap and standalone installer contract
  - How to configure an installed Deployer stack for a server
  - Deployment authorization, backup, and catastrophic-operation boundaries
depends_on:
  - ../adrs/0007-optional-deployer-capability.md
referenced_by:
  - ../adrs/0007-optional-deployer-capability.md
  - ../../../README.md
  - ../../getting-started.md
  - ../../how-it-works.md
type: feature
---

# Deployer capability

Deployer is an **optional** AI Development Harness capability. It is
capability-on-demand: available from the harness, installed only when
selected, and absent without warnings when not selected.

Installing or configuring this stack **does not authorize deployment**
to any environment. It does not connect to a server. It does not run
`dep deploy`.

Current Deployer major: **8** (`deployer/deployer` `^8.0`, PHP 8.3+).
Prefer the project's declared constraint when one already exists.

## Prerequisites

- A project the harness can identify (Laravel, Bedrock/Sage, Bedrock, or
  conventional WordPress)
- Composer (declared dependency; `composer install` is a later developer
  step and is not run by the installer)
- SSH public-key access to the target host, configured by the developer
- A document-root / deploy-path convention the web server already uses
  or will be configured to use
- For Sage: Node on the host that runs `npm ci` and `npm run build`

The harness clone does **not** depend on Deployer.

## Supported project types

| Profile | Detection | Recipe |
| --- | --- | --- |
| `laravel` | `laravel/framework` in Composer | native `recipe/laravel.php` |
| `roots` | `roots/radicle`, `roots/sage`, or `roots/acorn` | Bedrock paths plus Sage theme build |
| `bedrock` | Roots Bedrock without Sage/Acorn/Radicle | Bedrock paths, Composer vendors, no theme build |
| `wordpress` | `wp-content` plus `wp-config.php` or `wp-config-sample.php` at the project root | native `recipe/wordpress.php` |

Detection does **not** inspect GitHub Actions, Envoyer, Forge, custom
shell deploy scripts, CI/CD, or hosting-provider deployment. The only
install question is whether the **harness-managed Deployer stack** is
already present.

Unsupported project types are not given a guessed recipe.

## Installing the capability

### Bootstrap prompt

After the rest of bootstrap, if the harness-managed stack is absent and
no conflicting Deployer files exist, interactive bootstrap asks:

```text
Install Deployer deployment stack? [y/N]
```

Default is **N**. The prompt does not authorize deployment.

If the harness-managed stack is already present, bootstrap leaves it in
place and does not prompt. If a non-harness Deployer recipe exists,
bootstrap preserves it (Current-First) and does not prompt to replace it.

### Flags

| Flag | Behavior |
| --- | --- |
| `--with-deployer` | Install without prompting |
| `--without-deployer` | Skip without prompting |

Flags may appear before or after the project path. They cannot be
combined. Automated and agent-driven bootstrap should pass an explicit
flag. `AI_BOOTSTRAP_NONINTERACTIVE=1` skips Deployer unless
`--with-deployer` is set.

Selecting the prompt **Yes** or passing `--with-deployer` authorizes
**only** the Deployer Composer dependency (`deployer/deployer` in
`require-dev`) and the harness-managed files listed below. It does not
authorize other dependency changes and does not authorize deployment.

### Standalone installer

For an already-bootstrapped project:

```bash
"$AI_PLATFORM/scripts/install-deployer.sh" /path/to/project
```

The installer validates the path, refuses to target the harness clone,
detects the profile, preserves existing Deployer configuration, refuses
unsafe overwrite, installs the foundation, writes project-local notes,
and never deploys. It is safe to re-run (idempotent for a
harness-managed install).

## Generated stack

| Path | Tracked? | Role |
| --- | --- | --- |
| `deploy.php` | yes | Recipe. No secrets. |
| `deploy/hosts.yaml.example` | yes | Placeholder inventory |
| `deploy/hosts.yaml` | **no** (gitignored) | Real host, SSH, path, repository, branch |
| `docs/contracts/features/deployment.md` | yes, if the installer created it | Project-local notes |
| `composer.json` `require-dev.deployer/deployer` | yes | Project-owned dependency declaration |
| `/.dep/` | **no** (gitignored) | Deployer runtime state |

The installer does **not** run `composer install` and does not invoke
`vendor/bin/dep`.

Harness-managed `deploy.php` files contain
`AI_PLATFORM_DEPLOYER_STACK=<profile>`. Do not remove that marker from
a harness-managed recipe.

## What the developer must provide

Fill `deploy/hosts.yaml` (copy from the example if needed):

- `hostname` (IP, DNS name, or SSH alias)
- `remote_user`
- `deploy_path` (absolute path on the server where Deployer should
  create `releases/`, `shared/`, and `current`)
- `repository` (Git URL the server can fetch)
- `branch`
- optional `identity_file` when the default SSH agent/key is not enough
- optional `bin/php` when `php` on `$PATH` is the wrong runtime

SSH authentication is public-key based. Do not put passwords, tokens,
private keys, or production secrets in `deploy.php`, the example
inventory, or any committed file.

The web server must serve the live release symlink:

- Laravel: `current/public`
- Bedrock / Sage: `current/web`
- Conventional WordPress: `current/`

Shared files and writable directories are defined by the profile recipe.
Environment configuration (`.env` or `wp-config.php`) lives in
`shared/` after the first release and is not committed by this stack.

Server permissions must allow the deploy user to write `deploy_path`,
create releases, and (for Laravel/Bedrock) write the documented
writable directories. This harness does not provision users, firewalls,
or DNS.

`keep_releases` is **5**. Deployer's own cleanup of older releases
inside that release path is the established safe cleanup. Do not add
scripts that delete other absolute paths.

## First deployment procedure

1. Confirm the developer **explicitly authorized this deployment**
   (environment named). Installing or configuring Deployer is not that
   authorization.
2. If the target is **production**, verify a restorable production backup exists. If it cannot be verified, **stop**.
3. `composer install` in the project (local), so `vendor/bin/dep` exists.
4. Confirm `deploy/hosts.yaml` has no `CHANGE_ME` values.
5. `vendor/bin/dep config:hosts` (inventory check, not a deploy).
6. `vendor/bin/dep deploy <host>` only after the authorization in step 1.

Health/verification after an authorized deploy is project-specific:
HTTP 200 on a known URL, application logs, and (Laravel) that `current`
points at the new release. Do not treat a successful `dep deploy` exit
as product QA.

## Rollback procedure

After explicit authorization to roll back that environment:

```bash
vendor/bin/dep rollback production
```

Rollback uses Deployer's previous release. It is not authorization to
destroy the server, modify DNS, drop databases, or delete files outside
the release path.

## Profile details

### Laravel

Native `recipe/laravel.php`. Shared `.env` and `storage`. Writable
`bootstrap/cache` and `storage`. Public path `public`. Composer vendors
install on the server. The native recipe includes `artisan:migrate` and
`artisan:optimize`. `artisan:migrate:fresh`, `db:wipe`, and seeding are
**not** hooked. `assets:build` exists for Vite/npm but is **not** in the
default deploy flow; add it only when the server has Node and the
project needs a production asset build.

### Bedrock / Sage (`roots`)

Composer vendors at the project root. Public path `web`. Shared `.env`
and `web/app/uploads`. Sage build runs in `theme_path` when that path
is not `CHANGE_ME`. Detected theme directories with a `package.json`
are written at install time. Override `theme_path` in `hosts.yaml` if
needed. No database push/pull.

### Bedrock without Sage

Same paths as Roots without the Sage build task.

### Conventional WordPress

Native `recipe/wordpress.php`. Shared `wp-config.php` and
`wp-content/uploads`. Document root is the WordPress root. Keep
`wp-config.php` out of git; it belongs in `shared/`.

## Existing projects

If `deploy.php` / `deploy.yaml` / `deploy.yml` / `deploy.maml` already
exists and is **not** harness-managed: preserve it. Do not rewrite
`deploy.php`. Do not add a competing harness recipe. Report that an
existing Deployer strategy was detected. Incomplete or outdated
existing configuration is not permission to replace it.

If those files would conflict with a new harness install: **stop that
installation path** and report the conflict. Do not overwrite.

Existing projects without Deployer may be offered the stack during
bootstrap. Installation uses detected profile information. Application
code is otherwise untouched. Project-owned deployment documents are
not overwritten.

Selecting Deployer is not Project Adoption and is not architecture
reconciliation.

## Doctor

Doctor never SSHs to a server.

| State | Result |
| --- | --- |
| Not installed | OK. Valid. No warning. |
| Harness-managed, complete | OK. |
| Harness-managed, incomplete | FAIL with the missing piece. |
| Existing non-harness Deployer | OK. Not marked broken for differing from templates. |
| `vendor/bin/dep` missing on a healthy harness install | WARN (`composer install` not yet run). |

## Git and secrets

Commit the recipe, the example inventory, and documentation. Do not
commit `deploy/hosts.yaml`, `.dep/`, credentials, private keys, or
environment-specific secrets. Bootstrap/installer add those ignore
entries when missing.

## Authorization and safety

These rules are portable (always-on core and `00-platform`):

- Installing or configuring deployment tooling does not authorize
  deployment to any environment.
- Generic instructions such as "set up Deployer", "bootstrap this
  project", "install the deployment stack", or "configure deployment"
  do **not** authorize production deployment, staging deployment unless
  specifically requested, infrastructure changes, DNS changes, database
  destruction/reset, server destruction, or removal of previous
  releases beyond Deployer's `keep_releases` cleanup.
- Before an authorized **production** deployment, verify a restorable production backup. If it cannot be verified, stop. Deployer
  availability is not sufficient authorization.
- Generated recipes must not embed secrets, use unchecked absolute
  cleanup paths, hook destructive database operations, or provision
  infrastructure/DNS.
- The catastrophic-operation guardrail applies to deployment scripts
  the same way it applies to commands an agent runs directly.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| `Missing deploy/hosts.yaml` | Copy the example and fill CHANGE_ME values |
| SSH permission denied | Key, `remote_user`, `identity_file`, `ssh-add` |
| Git clone fails on the server | Deploy key or HTTPS credentials for `repository` |
| Wrong site / empty page | Document root vs `public_path` (`public`, `web`, or WP root) |
| Permission denied on storage/uploads | writable dirs and the deploy user |
| Sage assets missing | `theme_path`, Node on the server, `npm run build` |
| Doctor FAIL incomplete stack | Re-run `scripts/install-deployer.sh`; do not deploy |
| Want Deployer later | Standalone installer; do not re-run adoption |

Do not "fix" an existing non-harness Deployer setup by overwriting it
with the harness recipe.
