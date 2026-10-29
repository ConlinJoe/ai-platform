---
status: accepted
last_reviewed: 2026-10-29
source_of_truth_for:
  - Decision that architecture and styling standards follow the detected stack
  - Decision that high-confidence violations are checked on the existing guardrail path
  - Decision that existing projects can record an explicit finding baseline
depends_on:
  - 0006-instruction-precedence-and-mechanical-guardrails.md
  - ../features/stack-native-architecture.md
referenced_by:
  - ../features/stack-native-architecture.md
  - ../../../.cursor/rules/00-platform.mdc
  - ../../../.cursor/rules/21-stack-architecture.mdc
type: adr
---

# ADR-0011: Stack-native architecture checks

## Status

Accepted

## Context

Instruction-only architecture guidance was easy to miss. Task prompts had
to restate view boundaries and Tailwind composition, and a familiar stack
was sometimes applied to a project that does not use it. Appearance
requests and design references were also treated as permission to put
queries in templates or to recreate utilities as custom CSS.

`scripts/check-guardrails.sh` already fails closed on em dashes and
arbitrary Tailwind utilities (ADR 0006). Lint, tests, and build do not
inspect architecture. Those checks also cannot prove every structural
decision. Some violations are reliable to detect. Others require judgment.

Existing applications already contain both kinds. Adoption must not turn
that history into a mandatory rewrite, and it must not hide new violations
by exempting a whole file.

## Decision

1. The always-on harness states a stack-native principle: follow the
   project's actual languages, frameworks, and architecture. Detect the
   stack from repository evidence before applying a framework profile.
   When detection is uncertain, report that uncertainty. Do not assume a
   familiar stack.
2. Template/MVC architectures and component architectures have separate
   profiles. React and similar components are not held to an MVC "no
   logic in views" rule. Laravel layer names are not applied to other
   frameworks.
3. Tailwind utility composition applies only inside a detected Tailwind
   scope. Plain CSS, Bootstrap, CSS Modules, and CSS-in-JS keep their own
   conventions. A Tailwind dependency does not make every file a Tailwind
   file.
4. Appearance, comps, and visual fidelity do not waive these standards.
   Translate the approved design into the stack's normal implementation.
5. `scripts/check-guardrails.sh` also runs the architecture check. It
   fails on high-confidence template queries, persistence, orchestration,
   substantial template preparation, `@apply` relocation, and custom CSS
   that maps directly to standard utilities. It prints review items and
   coverage gaps without treating them as failures. It does not claim
   compliance.
6. Agents complete a short architecture review when the task changes
   views, components, data preparation, or styling. A passing lint, test,
   build, or guardrail command is not that review.
7. Exceptions are per finding, require a concrete limitation, and use
   `guardrail-allow-architecture`. File-level architecture exemptions are
   invalid. Agents do not add a marker or baseline entry merely to pass.
8. Existing projects may commit `docs/architecture-baseline.txt` from
   committed findings only, with an explicit write command. The baseline
   suppresses matching findings. It does not suppress new findings, new
   files, or a whole modified file. New projects start with no baseline.
9. The check uses the Python already required by the guardrail script. It
   does not install framework-specific tooling into unrelated projects.
   Template mode is chosen per file from that file's ancestor Composer
   package. A nested npm manifest does not hide that package, and a
   sibling package does not leak into it.
10. Local verification stays `scripts/check-guardrails.sh`. New bootstraps
    add `.github/workflows/guardrails.yml` when it is missing. The workflow
    checks out this harness and runs `scripts/ci-guardrails.sh` on the pull
    request or push range. It does not follow the project's absolute
    symlink. Existing projects are not given that file automatically.
    Bootstrap and doctor report the missing file and the copy step, and
    they do not overwrite other workflow files. A missing base revision
    fails the job. It does not treat a clean checkout's empty `HEAD` diff
    as a successful scan.

## Consequences

### Positive

- Fresh sessions see the principle without a reminder in the task prompt
- The mechanical failures are file-and-line specific
- React, Bootstrap, and plain CSS projects are not judged by Laravel or
  Tailwind rules
- Existing code can be inventoried and deferred without freezing new work
- The report says which profiles ran and which coverage is missing

### Negative

- The check misses architectural mistakes that do not match its patterns
- A justified exception can still be worded so the marker is accepted
- Historical files are untouched until they change, unless the project
  opts into `--all` or writes a baseline
- Projects need one bootstrap re-run before doctor links the new
  `21-stack-architecture.mdc` rule file. The always-on rules and the
  guardrail script update through existing symlinks
- Existing projects do not gain the CI workflow until someone copies and
  commits `templates/github/workflows/guardrails.yml`. That is deliberate:
  bootstrap must not overwrite workflows the project already has

## Alternatives considered

- Ask every task prompt to restate the architecture rules. Rejected.
  That is the failure this change removes.
- Ban every `@php` block, helper call, CSS selector, and React expression
  with a broad regex. Rejected. Those patterns include legitimate
  presentation and component code.
- Install PHPStan, ESLint, or Stylelint in every project. Rejected.
  Unrelated stacks should not gain framework tooling, and those tools do
  not know this harness's boundaries.
- Fail the command on every uncertain or review item. Rejected. That
  forces either noisy rewrites or blanket suppressions.
- Silently treat pre-existing lines in a touched file as allowed.
  Rejected. That exempts a whole modified file and hides new copies of
  an old violation unless a baseline entry matches that finding.
