---
status: active
last_reviewed: 2026-10-29
source_of_truth_for:
  - Stack detection and which architecture or styling profile applies
  - Mechanical architecture check, review items, exceptions, and baselines
  - Architecture completion review that the check does not replace
depends_on:
  - ../adrs/0011-stack-native-architecture.md
  - ../adrs/0006-instruction-precedence-and-mechanical-guardrails.md
  - copy-and-tailwind-guardrails.md
referenced_by:
  - ../adrs/0011-stack-native-architecture.md
  - ../../../.cursor/rules/00-platform.mdc
  - ../../../.cursor/rules/20-coding.mdc
  - ../../../.cursor/rules/21-stack-architecture.mdc
type: feature
---

# Stack-native architecture

Follow the established boundaries of the project's actual languages,
frameworks, libraries, and architecture. Instruction detail for agents
lives in `00-platform`, `20-coding`, and `21-stack-architecture`. This
contract owns detection, the mechanical check, exceptions, baselines,
and the completion review.

Appearance requests, design references, and visual fidelity do not waive
these standards. Translate the approved design into the stack's normal
implementation.

## Detection

Before applying a framework-specific rule, detect the installed stack
from repository evidence: manifests, lockfiles when present, config
files, and source layout. Read applicable project contracts and ADRs.
Apply only the profiles that evidence supports.

| Evidence | Profile |
| --- | --- |
| `laravel/framework`, `roots/acorn`, `roots/sage`, or `roots/radicle` in a Composer manifest, or Blade files | Template profile. WordPress template tags are failed only when a Roots/Sage/Acorn package is declared. Blade without one of those packages is uncertain: Eloquent and `DB::` checks still run, and the report says WordPress tags were not failed. |
| `react`, `vue`, `svelte`, `preact`, `solid-js`, or `@angular/core` | Component profile. MVC template restrictions are not applied to component files. |
| JSX, TSX, Vue, or Svelte files without one of those dependencies | Component profile is uncertain. MVC restrictions are still not applied. |
| `tailwindcss` in a package manifest, a Tailwind config file, or a Tailwind entry (`@import "tailwindcss"`, `@tailwind`, `@theme`) | Tailwind styling profile for that package scope. |
| `bootstrap`, styled-components, Emotion, MUI, or Bulma in a nearer package, without Tailwind | Tailwind checks are not applied to that package. |
| `*.module.css` | Tailwind custom-CSS check is not applied to that file. |

A Tailwind dependency at the root does not cover a nested package that
declares a different styling system. A directory with no styling package
inherits an ancestor Tailwind package. The check reports the scope it
used.

Other template languages (Twig, Nunjucks, ERB, Razor, Haml, Slim) are
reported as unsupported. They are not failed by PHP or Blade rules.

When detection is uncertain, the report says so. Do not apply an
unrelated profile to fill the gap.

## Profiles

### Template and MVC-style views

Views render prepared data. Presentation conditions, loops, formatting,
components, and class selection belong in the template. Queries,
persistence, business decisions, substantial data transformation,
content parsing, and service orchestration belong in the controller,
composer, presenter, service, or whatever layer this framework actually
uses.

Do not rename those layers into Laravel terms for a framework that has
its own. Do not treat every template expression or helper call as
prohibited logic.

### Components

React and similar component architectures follow their own component,
hook, rendering, and data-access conventions. Do not mechanically apply
MVC "no logic in views" restrictions to components, and do not invent a
universal separation that conflicts with that framework.

### Styling

When Tailwind is the styling system for the file's scope, compose
styling with native utilities and project theme tokens. CSS may contain
framework imports, theme definitions (`@theme`, `@font-face`, Tailwind
`@utility` blocks), and CSS that cannot reasonably be done with
utilities.

Do not add a semantic class, custom declaration, or `@apply` wrapper
merely to relocate utility-supported styling. Do not switch to an
arbitrary utility to avoid that rule when a standard utility or token
works. The arbitrary-utility check remains
`copy-and-tailwind-guardrails.md`.

Plain CSS, Bootstrap, CSS Modules, CSS-in-JS, and other systems follow
their own conventions. Do not impose Tailwind class composition on them,
and do not forbid their stylesheets.

## Mechanical check

The same command as the copy and Tailwind guardrails:

```bash
scripts/check-guardrails.sh
```

From the AI Platform clone, pass the project root. Default scope is
git-changed and untracked files. `--all`, `--since`, and `--files` match
the copy check. Doctor links the script and does not run the scan.
Bootstrap does not add a CI workflow. A project that already runs this
script locally or in CI runs the architecture check on that same path.

Every run reports applicable profiles, executed checks, and unsupported
or uncertain coverage. It does not stay silent when a profile is skipped.

Blocking findings name a file and line. Review items are printed and do
not fail the command.

### Blocking

In Blade and in PHP files under `resources/views` (not composers or view
component classes):

- Eloquent and `DB::` query calls
- Persistence and outbound calls such as `save`, `Mail::`, and `Http::`
- `app()` and `resolve()`
- In `@php` / `<?php` blocks: collection and array shaping, content
  parsing, closures, loops that accumulate a new structure, and blocks
  with 15 or more statements
- When a Roots/Sage/Acorn package is declared: `get_field`, `WP_Query`,
  and `get_posts`

Inline template expressions may format prepared data. Those helper calls
are not failed unless they match a query, persistence, or service-location
pattern.

In a Tailwind scope:

- `@apply` inside application CSS
- A single-class ruleset whose declarations all map to standard utilities

These are not failed:

- `@theme`, `@font-face`, `@keyframes`, and `@utility` blocks
- CSS Modules files
- CSS outside a Tailwind scope
- Controllers, composers, services, and other non-view PHP
- Component files, including hooks, filtering, and local state

### Review

A single-class ruleset that mixes utility-mappable declarations with
other CSS is a review item. It is not a failure. The completion review
decides whether the remaining CSS is a concrete limitation.

### Not proved

The check does not prove architecture compliance. It does not prove that
business rules live in the right layer, that a presenter was the right
extraction, that a component's data access matches that framework's
current convention, or that a custom value should have been a theme
token. A zero-finding result, lint, tests, and build do not prove it
either.

## Exceptions

On the finding line or the previous line:

```text
guardrail-allow-architecture: <concrete limitation>
```

The limitation must be specific and at least a short sentence. Generic
reasons (`legacy`, `exception`, `false positive`, `ok`, and similar) do
not suppress the finding.

`guardrail-allow-file: architecture` is invalid. The finding still fails,
and the file-level marker is itself a finding.

An accepted marker is accountability, not proof that the exception is
justified. Agents must not add one merely to make the command pass.
Ordinary convenience is not an exception. Project ADRs remain
authoritative: if a project decision conflicts with this check, stop and
report the conflict. Do not overwrite the project decision and do not
silently suppress it.

## Baseline

`docs/architecture-baseline.txt` is an explicit, reviewable list of
existing findings. One line suppresses one finding:

```text
path<TAB>kind<TAB>snippet
```

Bare paths, wildcards, and incomplete lines are invalid and do not
suppress anything.

Create or refresh it only with:

```bash
scripts/check-guardrails.sh --write-architecture-baseline
```

That command reads committed files in a repository whose git toplevel is
the project root. It does not baseline untracked files or uncommitted
findings. Review and commit the file deliberately. Agents must not run
it, and must not edit the file, to clear a failure in the current task.

Matching is by path, kind, and line text. A baseline entry is consumed
once, so a second copy of the same violation still fails. Changing the
violating line fails. New files fail. Unchanged baselined lines in a
touched file do not fail. Stale entries for files in the current scan are
reported and do not fail the command.

`--all` inventories the tree, including findings a baseline would hide
only after it exists. Without a baseline, historical violations fail when
their files are scanned. Do not fix those findings as part of adoption
unless that remediation was approved.

## Completion review

When the task changes views, components, data preparation, or styling,
the completion includes a short architecture review even if the command
exits 0:

- Which profiles the command reported, including uncertain or unsupported coverage
- The mechanical result (failures, review items, baselined matches)
- Judgments the command does not make: layer placement, framework-native data access, whether remaining custom CSS is actually necessary, and any conflict with a project contract or ADR

Do not describe that review as proof that every architectural decision is correct. Do not skip it because lint, tests, or build passed.

## New and existing projects

New bootstraps link the rules and the check script. Fresh sessions read
the always-on principle in `00-platform` and `core/agent-core.md`. No
baseline file is created. Enforcement does not depend on the wording of
an implementation prompt.

Existing projects receive rule edits and the check script through
symlinks already in the project. Re-run bootstrap once so doctor links
`21-stack-architecture.mdc`. Re-bootstrap does not rewrite application
code and does not write a baseline.

The explicit adoption step, when historical findings should remain while
new ones fail, is to inventory with `--all`, then write and commit a
baseline only after the developer approves that debt. Until then, a
touched file that contains a violation fails the check.
