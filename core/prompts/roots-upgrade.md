# Roots upgrade runbook

Use this when the task is a Roots upgrade or a security assessment of
a Bedrock, Sage, Radicle, Acorn, or Bud project, including any mix of
generations.

Policy lives in `docs/contracts/features/roots-upgrade.md` in the AI
Platform clone. If this runbook and the contract disagree, follow the
contract.

A routine update of one named package inside its current constraint,
with no major-version advisory and no pinned-version ADR in the way,
does not use this runbook. That update still needs dependency approval.
Details and the boundary are in the contract section **When a routine
update is enough**.

## Find the harness copy

From the target project, when shared rules are linked:

```bash
AI_PLATFORM="$(cd "$(dirname "$(readlink .cursor/rules/35-roots.mdc)")/../.." && pwd)"
echo "${AI_PLATFORM}/docs/contracts/features/roots-upgrade.md"
```

Do this work in the application repository. Do not modify the harness
clone. Do not modify a different application than the one that is open.

## Order of work

Read the contract, then:

1. Confirm identity and stay read-only.
2. Discover the stack.
3. Assess dependencies and security.
4. Build the compatibility matrix from official docs.
5. Classify every recommendation.
6. Write the project plan and stop.
7. Execute only stages the user approved, one at a time.

## 1. Identity and read-only gate

Confirm the open repository is the project being assessed. If the
request names a different project, stop.

Read `docs/working-mode.md`, project ADRs, and architecture contracts
that mention Roots, PHP, Node, Tailwind, or deployment. An accepted
ADR that keeps the current generation is a constraint.

Do not edit manifests, lockfiles, application code, or deploy config
in this phase. Do not run update, require, remove, or audit-fix
commands. The written plan is the only file this phase should add or
change.

Treat versions mentioned in the task as hypotheses until the lockfile
and installed metadata confirm them.

## 2. Discovery

Search the repo for `composer.json`, `composer.lock`, `package.json`,
`yarn.lock`, `package-lock.json`, `pnpm-lock.yaml`, `bud.config.*`,
`vite.config.*`, and `webpack.mix.js`. Skip `vendor/` and
`node_modules/`. A `composer.json` inside an installed plugin or
mu-plugin is plugin metadata, not an application root.

For each Composer root record: `"name"`, PHP constraint,
`config.platform`, `repositories`, `require`, `require-dev`,
`extra.wordpress-install-dir`, `extra.installer-paths`, and locked
versions of `roots/wordpress`, `roots/acorn`, `illuminate/support`,
and `symfony/http-kernel` when present.

For each JavaScript root record: package manager, Node engines,
direct dependencies for Bud, Sage, Vite, Mix, and Tailwind, and the
locked versions.

Detect the layouts in the contract (nested Bedrock, root Bedrock,
theme-owned toolchain, Radicle, Sage without Bedrock, Bedrock without
a theme toolchain). Radicle is the composer `"name"`, not a required
package called `roots/radicle`. Absent tools stay absent.

Record local PHP and Node with `php -v` and `node -v`, then staging
and production only from CI, deploy config, `.php-version`, `.nvmrc`,
hosting docs, or ADRs. Unknown stays unknown. Local PHP is not
production PHP.

List Composer plugins and plugin directories that are not in the
lockfile. List private Composer and npm sources. Note that auth is
required without copying secrets.

List deploy and CI entrypoints, including a Composer project that
exists only to deploy.

## 3. Security

From each root, run the read-only audit the installed Composer, Yarn,
or npm documents. The contract names the usual commands. Do not take
fix flags.

Deduplicate by advisory ID. Mark direct versus transitive, runtime
versus development, and whether a fixed release exists inside the
current major. Composer audit does not clear WordPress plugins.
`roave/security-advisories` is not a report.

Rank production exposure above advisory counts.

## 4. Compatibility

Read the official upgrade guide for the installed major and the next
hop only. Start with the Acorn guide when Acorn is installed:

<https://roots.io/acorn/docs/upgrading-acorn/>

Add Sage, Radicle, Bedrock, Bud, Laravel, WordPress, and Tailwind
notes for the versions this project actually has. Re-check PHP and
Node floors against production evidence.

Do not fill the target column with the newest major.

## 5. Classification

Use the five classes in the contract. One class per recommendation.
Keep architecture as it is unless the user is being asked to approve
a class 4 migration on its own.

## 6. Plan, then stop

Write `docs/contracts/planning/roots-upgrade.md` in the project, or
update the upgrade plan that project already has. Register it in the
project `docs/README.md` with `type: planning`.

Required sections:

- Current stack inventory
- Compatibility matrix
- Security findings ranked by actual exposure
- Recommended target versions
- Dependency conflicts and blockers
- Proposed execution sequence
- Required testing
- Rollback strategy
- Explicitly deferred upgrades

Stop. Do not apply upgrades in the same turn as the first assessment
unless the user has already approved those exact stages.

## 7. Approved execution

For each approved stage:

- Baseline is clean, or the user has accepted the current dirty state
  for this stage. Record `HEAD` and lockfile hashes.
- Edit only the named constraints. Update only those lockfile entries.
- Follow the official hop when the stage is an approved Acorn or
  Laravel upgrade, including a with-dependencies update when that
  guide requires it for the named packages.
- Verify install, production PHP compatibility, WordPress, templates,
  assets, integrations, and the deploy path in staging.
- Roll back that stage on the conditions in the contract. Do not start
  the next stage after a failure.

Do not run a broad update, an automatic audit fix, an unapproved
major, or a forced override. Do not deploy to production from this
runbook.
