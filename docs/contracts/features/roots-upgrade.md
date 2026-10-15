---
status: active
last_reviewed: 2026-10-15
source_of_truth_for:
  - Roots upgrade procedure for Bedrock, Sage, Radicle, Acorn, and Bud
  - When the full procedure runs and when a routine dependency update does not
  - Read-only assessment, classification, and safe execution gates
depends_on:
  - ../adrs/0009-roots-upgrade-procedure.md
referenced_by:
  - ../adrs/0009-roots-upgrade-procedure.md
  - ../../../.cursor/rules/35-roots.mdc
  - ../../../.cursor/rules/50-workflows.mdc
  - ../../../core/agent-core.md
  - ../../../core/project-profiles/roots-radicle.md
  - ../../../core/prompts/roots-upgrade.md
  - ../../../core/prompts/project-adoption.md
  - ../../README.md
  - ../../how-it-works.md
  - ../../adopting-projects.md
type: feature
---

# Roots upgrade procedure

Canonical procedure for upgrading existing WordPress projects that use
any combination of Roots technologies. Bedrock, Sage, Radicle, Acorn,
and Bud may appear alone or together, including older generations
(Sage 9 with Mix, Sage 10 with Bud, Sage 11 with Vite, Acorn 2 through
current, Radicle applications).

This contract is the policy. The session runbook is
`core/prompts/roots-upgrade.md` in the AI Platform clone. If they
disagree, follow this contract.

The procedure discovers the installed stack. It does not require a
particular Roots architecture or version. It does not move a project
onto the harness greenfield baseline (ACF Pro, Keen Slider, WPForms
Lite, Navi) and it does not replace project deployment tooling with
harness Deployer.

Project findings, target versions, and approvals belong in that
project's planning contract. They are not written back into this file.

## When to use it

Run the full procedure when the task is any of these:

- Upgrade Bedrock, Sage, Radicle, Acorn, Bud, or the WordPress / PHP /
  Node / Tailwind / build toolchain around them
- A security assessment of Composer, JavaScript, or WordPress plugins
  on that stack
- A proposed change that crosses a major version, replaces the build
  tool, changes the production PHP or Node floor, or changes the
  Tailwind major
- Several lockfiles, a split application and theme, or deploy tooling
  with its own dependencies
- Production, staging, and local runtimes that are not the same
- A project ADR or contract that pins Roots, PHP, Node, or Tailwind
  versions

## When a routine update is enough

Skip the full procedure for one named direct dependency when all of
the following are true:

- The user asked for that package, or an advisory names it and a fix
  exists inside the current major
- The installed constraint already allows the new version, or the bump
  stays on the same major
- The package is not Acorn, Sage, Radicle, Bud, Vite, Tailwind,
  WordPress core, PHP, Node, Laravel/Illuminate, or Symfony
- No project ADR defers that line
- The change does not pull a new major of a framework package in the
  lockfile

A routine update still needs explicit dependency approval, a clean
baseline, that package's changelog, and verification of the surface it
affects. It does not authorize `composer update`, `yarn upgrade`, or
`npm audit fix` with no package arguments.

Adoption and bootstrap do not run this procedure. They may record the
installed generation. Version changes wait for a task that asks for
them.

## Scope

In scope:

- Bedrock applications, including a Bedrock root nested below the git
  root
- Sage themes, whether they live in the theme directory or share the
  application `package.json`
- Radicle applications (`composer.json` `"name"` of `roots/radicle`,
  with or without a package named `roots/radicle`)
- Acorn, including Acorn required by Bedrock, the theme, or both
- Bud, Vite, Mix, and other build tools actually installed
- WordPress core, plugins, and premium packages managed by Composer or
  present on disk
- PHP, Composer, Node, Yarn, npm, and Tailwind as installed
- Deployment and CI only as constraints on the upgrade

Out of scope:

- Laravel web applications that are not a Roots project
- Plain WordPress with none of Bedrock, Sage, Acorn, Bud, or Radicle
- Installing the harness greenfield stack as if it were an upgrade
- Switching deployment tools
- Writing project-specific versions into this harness

If a required component is absent, record it as absent. Do not install
it to match another project or the current Roots default.

## Assessment gate

The first deliverable is a read-only assessment and a written plan.
Until the user approves a named stage:

- Do not edit manifests, lockfiles, theme code, WordPress content,
  configuration, or deployment files
- Do not run install, update, require, remove, `audit fix`, or
  broad upgrade commands
- Do not delete a lockfile to regenerate it
- Do not create a branch, commit, push, or open a pull request unless
  the user asks
- Writing or updating the project planning contract is the assessment
  output, and it is allowed

User-supplied version notes are hypotheses. Lockfiles, installed
metadata, and project ADRs are the inventory. Where they disagree,
record both and treat the repository evidence as the installed stack.

## Discovery

Search the repository. Do not assume `composer.json` or `package.json`
is at the git root, that there is only one of each, or that the web
root is `web/`. A theme toolchain may sit several directories down
(`web/app/themes/<theme>` or `public/content/themes/<theme>`).

Installed plugins and mu-plugins often ship their own `composer.json`
or `package.json`. Those files describe the plugin, not a project
upgrade root. The roots to assess are the manifests the project
maintains: the Bedrock or Radicle application, a Sage theme the
project develops, and deploy tooling with its own Composer project.
Record plugin copies on disk in the plugin inventory. Do not plan
upgrades inside plugin source.

### Layouts to detect

Record which of these is present. A project may match more than one.

| Layout | Evidence |
| --- | --- |
| Nested Bedrock | Application `composer.json` below the git root, often `site/composer.json`, with `"name": "roots/bedrock"` |
| Bedrock at the repo root | Root `composer.json` named `roots/bedrock` |
| Sage theme beside Bedrock | Theme `composer.json` / `package.json` under the themes directory (`web/app/themes/<theme>` or the installer path in `extra.installer-paths`) |
| Sage or Bud toolchain on the Bedrock root | Root `package.json` contains `@roots/sage`, `@roots/bud`, or Bud scripts |
| Radicle | `"name": "roots/radicle"`. Vite config and `package.json` are often at the application root. Web root may be `public/` rather than `web/` |
| Sage without Bedrock | Theme repository with Sage/Acorn/Bud/Vite and no Bedrock |
| Bedrock without a theme toolchain | Bedrock Composer project and no Sage, Bud, or Vite manifests |

Also record `extra.wordpress-install-dir`, `extra.installer-paths`,
and the actual content directory (`web/app`, `public/content`, or
another path).

### Versions and relationships

From each Composer root, read `composer.json` and `composer.lock`.
From each JavaScript root, read `package.json` and the lockfile that
matches the package manager the project actually uses (`yarn.lock`,
`package-lock.json`, `pnpm-lock.yaml`, or more than one). When two
lockfiles exist, record both and which one the scripts and docs use.
Do not pick one by preference.

Identify:

- Bedrock, Sage, Radicle, Acorn, and Bud versions, and which package
  requires which
- WordPress (`roots/wordpress` or the core actually installed)
- PHP constraint, Composer `config.platform.php` if set, and Composer
  version available locally
- Node constraint (`engines`, `.nvmrc`, `.node-version`) and Yarn or
  npm major
- Tailwind major and how it is pulled in (direct dependency,
  `@roots/bud-tailwindcss`, `@tailwindcss/vite`, or both)
- Illuminate and Symfony majors locked with Acorn
- Build tool: Bud (`bud.config.*`, `@roots/bud`), Vite
  (`vite.config.*`, `vite`, `@roots/vite-plugin`), or Mix

Acorn's major selects the Laravel components it vendors. Confirm the
pairing in the official Acorn upgrade guide for the installed major
and any proposed next hop:

<https://roots.io/acorn/docs/upgrading-acorn/>

As of 2026-10-15 that guide states: Acorn 3 vendors Laravel 9 (PHP
>= 8.0.2), Acorn 4 vendors Laravel 10 (PHP >= 8.1), Acorn 5 vendors
Laravel 12 (PHP >= 8.2), Acorn 6 vendors Laravel 13 (PHP >= 8.3).
Re-read the guide during the assessment. Do not treat this paragraph
as a target, and do not skip hops because a later major exists.

Sage 10 projects commonly use Bud. Sage 11 and current Radicle
commonly use Vite. Confirm against the installed packages and the
Sage or Radicle release notes for those versions. Replacing Bud with
Vite is a build-system migration, not a Bud upgrade.

### Runtimes

Record local, staging, and production separately.

| Source | What it proves |
| --- | --- |
| `php -v` and `node -v` on the machine running the assessment | Local only |
| `composer.json` `php` and `package.json` `engines` | Declared constraints |
| `config.platform` | What Composer pretends is installed |
| CI images, `.php-version`, `.nvmrc`, deploy config, hosting docs, ADRs | Staging or production only when the file says so |

A newer local PHP or Node version is not the production floor. A
constraint of `>=8.0` is not proof that production runs 8.0, 8.1, or
8.4. If an environment is not evidenced, mark it unknown. Do not SSH
to a server or read secrets unless the user asks.

### Plugins, premium packages, and auth

Inventory WordPress plugins from:

- Composer `require` and the lockfile (`wpackagist-plugin/*`,
  premium package names, `roots/*` WordPress packages)
- Plugin directories on disk that Composer did not install

Record premium and private sources: ACF Pro Composer endpoints,
Delicious Brains, Font Awesome npm, private Git remotes, and any
other non-packagist repository. Note whether `auth.json`, an npmrc,
or an environment variable name is required. Do not copy tokens,
license keys, or `auth.json` contents into the plan or the harness.

### Deployment, CI, and customizations

Record deploy tooling that is actually in the repo (`deploy.php`,
`deploy/`, Trellis, GitHub Actions, hosting docs, a second Composer
project used only to deploy). A separate deploy Composer project is
its own dependency graph.

Read project ADRs, architecture contracts, and working mode for
decisions that keep a Roots generation, PHP version, Node version, or
Tailwind major. Those decisions are constraints. This procedure does
not supersede them.

## Dependency and security assessment

Audit each Composer root and each JavaScript root with the read-only
audit command that the installed tool supports. Check `--help` on
that version. Do not upgrade Composer, Yarn, or npm to obtain a newer
audit flag.

- Composer: `composer audit --locked`. When that version supports a
  no-dev mode, run it as a second pass.
- Yarn classic (lockfile v1): `yarn audit --json` from the directory
  that owns `yarn.lock`.
- Yarn Berry: `yarn npm audit --json`, only if the project already
  uses that Yarn.
- npm: `npm audit --json`, plus `--omit=dev` when that flag exists.
  Do not run `npm audit fix` or `yarn audit` apply/fix modes.

`roave/security-advisories` in `require-dev` blocks some installs. It
is not an audit report.

Composer audit does not cover most WordPress plugins. Plugin findings
come from the installed plugin version plus that plugin's changelog
or advisory. A clean Composer audit does not mean plugins are clean.

For every finding, record:

| Distinction | What to write down |
| --- | --- |
| Direct vs transitive | The direct manifest requirement, then the locked package that is vulnerable. Use `composer why` / the lockfile parent. |
| Unique vs repeated | One advisory ID once, even when many paths mention it. List affected packages under that ID. |
| Runtime vs development | Composer `require` vs `require-dev`; npm `dependencies` vs `devDependencies`. A dev-only build tool is not production exposure. |
| Patch vs maintenance | A fix inside the current major that addresses an advisory, versus a bump with no security effect. |
| Deprecation vs failure | Warnings, including PHP deprecations that appear only on a newer local PHP. Separate those from solver conflicts, fatal errors, and failed builds. |
| No fix in this major | The advisory's smallest fixed version is another major, or no fixed release exists. |

Rank by production exposure. An unauthenticated or authenticated
vulnerability in a package that runs in production outranks a large
count of development-tool advisories and outranks repeated paths to
one advisory.

## Compatibility planning

Build a matrix for the installed stack and any proposed target. Leave the target empty until there is a reason to propose one. The newest major is not a default target.

Columns: component, locked version, manifest constraint, production
runtime, proposed target, official source, minimum PHP, minimum Node,
Illuminate/Symfony majors, WordPress compatibility, build tool,
Tailwind major, blocker.

Use the official upgrade document and release notes for each hop:

- Acorn: <https://roots.io/acorn/docs/upgrading-acorn/>
- Sage, Radicle, Bedrock, and Bud release notes for the installed
  version and the proposed version
- Laravel upgrade guide for the Illuminate major that Acorn vendors
- WordPress release notes for `roots/wordpress` changes
- Tailwind upgrade guide only when a Tailwind major change is proposed
- PHP and Node release notes for the production runtime, not the
  local machine

Propose at most the next compatible hop that satisfies the approved
goal. A jump across two Acorn majors is two hops. Combining them is a
framework upgrade and needs its own approval. A Bud 6 patch or minor
that the Bud changelog treats as compatible, that keeps the Tailwind
major, and that still runs on the project's Node floor, is a
maintenance candidate. A switch from Bud to Vite, or from Tailwind 3
to Tailwind 4, is a separate architectural decision.

Check minimum PHP and Node against production evidence. A target whose
PHP floor is higher than production PHP is blocked until that runtime
change is approved. Local success on a newer PHP does not clear the
blocker.

Record solver conflicts, abandoned packages, and packages that only
exist on a private repository. Do not add `conflict` resolutions,
`inline-alias`, or forced version overrides to make a solve succeed.

## Classification

Place every recommendation in exactly one class:

1. **Immediate security remediation within existing versions.** A
   patched release inside the current major, or a config/workaround
   that removes production exposure without a framework upgrade.
2. **Compatible patch or minor maintenance.** Same major, changelog
   shows no breaking change for this project's PHP, Node, Tailwind,
   and build tool.
3. **Framework upgrade.** Coordinated dependency changes required by
   an Acorn, Laravel/Illuminate, Symfony, or WordPress hop, including
   the `-W` style update the official guide requires for that hop.
4. **Major architectural migration.** Sage generation change, Bud to
   Vite (or the reverse), Tailwind major, Radicle adoption, or any
   other restructuring. Evaluate and approve it on its own. Do not
   attach it to a security patch.
5. **Deferred or blocked.** No fix inside the current major, production
   runtime too old, missing credentials, an accepted ADR that keeps
   the current generation, or a change the user did not approve.

Preserve the installed architecture. A migration happens only when it
is justified by a goal the user accepts and the user approves that
class 4 item.

An advisory with no fix inside the current major is class 5 until a
class 3 or class 4 upgrade is approved. Do not disguise it as class 1.

## Safe execution

After the user approves specific stages, and not before:

1. Record a clean Git baseline: `HEAD`, `git status`, and hashes of
   every lockfile in scope. If the tree is dirty with unrelated work,
   stop and ask. Do not create a branch unless the user asks.
2. Apply one approved stage at a time. A stage is one class 1 or
   class 2 package, or one class 3 hop whose official guide says those
   packages move together.
3. Change only the named constraints. Update only those packages'
   lockfile entries with the project's package manager. Keep every
   other lockfile entry.
4. For an approved Acorn or Laravel hop, follow that hop's official
   guide, including a with-dependencies update when the guide requires
   it. Use it for the named hop only.
5. Verify before the next stage: install from the lockfile, production
   PHP compatibility (not only the local binary), WordPress admin and
   front end, templates, built assets, integrations that use upgraded
   packages, and the project's deploy path in a dry run or staging
   deploy. Do not deploy to production as part of verification.
6. Validate the approved result in staging before any production
   deploy. Production deploy remains a separate explicit
   authorization, with a restorable backup, under
   `docs/contracts/features/deployer.md` when that stack is what the
   project uses. Projects with other deploy tooling use that tooling's
   own staging path.

Do not run `composer update` with no packages, `composer update` of
the whole lockfile, `yarn upgrade` with no packages, `npm update`,
`npm audit fix`, or `yarn audit` fix modes. Do not take a major
version that was not in the approved stage. Do not add forced
overrides to silence a solver.

### Rollback

Before the stage starts, write the rollback for that stage:

- Restore the previous manifests and lockfiles from the baseline
- Rebuild assets from those lockfiles
- Restore plugin directories that the stage replaced, including
  premium copies that Composer does not install
- Confirm the application boots on the production PHP version

Roll back if the build fails, PHP cannot run the result on the
production version, WordPress or a required integration errors,
templates or assets break, private packages cannot install, or the
deploy dry run fails. Do not continue to the next stage after a
failed stage.

## Project plan

Write the assessment in the project as a planning contract:

`docs/contracts/planning/roots-upgrade.md`

If the project already has an upgrade plan, update that file instead
of adding a second one. Register it in the project's `docs/README.md`.
`type: planning`. It is not implementation authority until the user
approves a stage.

The plan contains:

- Current stack inventory
- Compatibility matrix
- Security findings ranked by production exposure
- Recommended target versions, each tied to a class
- Dependency conflicts and blockers
- Proposed execution sequence
- Required testing
- Rollback strategy
- Explicitly deferred upgrades

Include the illustrative concerns below only when this project's
evidence matches them. Replace every version with this project's
lockfiles.

### Illustration, not a target

A single project can look like this. The numbers are an illustration
of how to classify mixed evidence. They are not recommended versions
for any project.

- Production PHP 8.1 and local PHP 8.4. Production is the floor.
  Deprecations that appear only on 8.4 are local. They do not justify
  Acorn 5 or 6, which require newer PHP.
- Acorn 2.1.x installed, with a possible move to Acorn 4.3.x. That is
  more than one major and a new Illuminate major. Class 3 if a
  framework upgrade is the approved goal. Class 5 if an ADR still
  keeps Acorn 2. It is not class 2.
- Bud 6.13.x with a later Bud 6 release that keeps Tailwind 3 and the
  project's Node floor. Class 2 after the changelog between those
  versions is read. A Vite migration is class 4.
- Tailwind 3 stays. Tailwind 4 is class 4 and is not bundled into the
  Bud or Acorn stage.
- Composer and Yarn advisories are deduplicated, split by runtime and
  development, and left in class 5 when the fixed release is another
  major.
- A Composer project that exists only to deploy is not upgraded in the
  application stage and is not swapped for a different deploy tool.

If the lockfile disagrees with this illustration, the lockfile wins.
