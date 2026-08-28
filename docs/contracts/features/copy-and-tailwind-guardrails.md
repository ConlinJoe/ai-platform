---
status: active
last_reviewed: 2026-08-28
source_of_truth_for:
  - Mechanical em-dash and Tailwind arbitrary-value guardrail check
  - Exception markers and invocation for consuming projects and agents
depends_on:
  - ../adrs/0006-instruction-precedence-and-mechanical-guardrails.md
referenced_by:
  - ../adrs/0006-instruction-precedence-and-mechanical-guardrails.md
  - ../../../.cursor/rules/00-platform.mdc
  - ../../../.cursor/rules/20-coding.mdc
  - ../../../.cursor/rules/40-ui.mdc
type: feature
---

# Copy and Tailwind guardrails

Mechanical check for two generated-implementation standards. Instruction
detail lives in `00-platform`, `20-coding`, and `40-ui`. This contract
owns how the check runs.

## Invocation

From a bootstrapped project:

```bash
scripts/check-guardrails.sh
```

From the AI Platform clone, targeting a project:

```bash
/path/to/ai-platform/scripts/check-guardrails.sh /path/to/project
```

Default scope is git-changed files versus `HEAD`, plus untracked files.
That is the agent DONE path. It does not scan vendor dependencies or
the whole historical tree.

| Option | Behavior |
| --- | --- |
| *(default)* | Changed and untracked in-scope files |
| `--files PATH...` | Explicit paths |
| `--since REF` | Files changed since a git ref, plus untracked |
| `--all` | Every in-scope file (opt-in; historical violations will fail) |

Bootstrap links the script beside `doctor.sh`. Doctor verifies the
link. Doctor does not run the content scan.

## What is checked

In-scope extensions include templates and frontend sources such as
Blade, HTML, Vue, JSX/TSX, PHP, CSS, JS/TS, Twig, and translation JSON
under `lang/` paths.

Skipped path parts include `vendor/`, `node_modules/`, `.agents/`,
`.cursor/`, `storage/`, and similar non-application trees.

### Em dashes

Fails on `—`, `&mdash;`, `&#8212;`, `&#x2014;`, and equivalent `\u2014`
forms in in-scope files.

Does not rewrite vendor files, third-party content, fixtures, or quoted
source material. Those belong behind an exception marker when they
appear in newly written or modified application sources.

### Arbitrary Tailwind utilities

Fails on bracket utilities in the typography, spacing, and sizing
families, including `text-[…]`, `p-[…]` / `px-[…]` / `m-[…]` /
`mt-[…]`, `gap-[…]`, `w-[…]` / `h-[…]`, and comparable `min-` /
`max-` size utilities, including responsive/state variants.

Does not ban all bracket syntax. Arbitrary properties, colors outside
those prefixes, and theme tokens such as `@theme { --text-display:
2.35rem }` with `text-display` are not this check.

Project theme tokens remain the correct place for repeated non-standard
values.

## Exceptions

Same line or previous line:

- `guardrail-allow-em-dash`
- `guardrail-allow-arbitrary`

First 30 lines of a file:

- `guardrail-allow-file: em-dash`
- `guardrail-allow-file: arbitrary`
- `guardrail-allow-file: em-dash, arbitrary`

An allowed finding still requires a brief explanation when the agent
introduced it. Markers are accountability, not a global weakening of
the rule.

## Completion gating

For work that writes or modifies public-facing copy or Tailwind markup,
this check is part of DONE validation.

Lint, tests, and build passing do not imply it ran. A failed check is
not a green completion: fix the violation, or use a legitimate
exception marker and explain why.

Hallmark slop-test or audit output is not a pass condition for these
standards.
