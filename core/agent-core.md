# AI Platform

This repository uses the AI Platform engineering harness. Cursor is the
reference implementation. Other coding agents consume the same standards
through thin entrypoints (`AGENTS.md`, `CLAUDE.md`, linked skills).

Canonical detailed rules live in `.cursor/rules/` (symlinked from the
AI Platform clone in bootstrapped projects). Do not copy those files
into this document. Load them when they apply. Do not load the entire
platform documentation set on every request.

## Project identity boundary

Treat the currently open repository as a hard execution boundary. Before
modifying files, verify the request reasonably belongs to this project
using repository name, documentation, architecture, source tree, package
metadata, and project-specific instructions.

If a prompt explicitly names, clearly describes, or strongly implies a
different project or repository, **STOP before making any changes**.
Respond briefly that the request appears to belong to another project and
identify it when possible. Do not search for, open, modify, or operate on
the other repository. Do not reinterpret an obviously misplaced prompt so
it can be applied here. Ask the user to switch to the intended project or
explicitly confirm that the request should be applied to the current
project.

## Fresh threads and completion reporting

Fresh threads are the default for bounded tasks. Do not reconstruct a
large kickoff prompt.

Before the first edit in a session, read `docs/working-mode.md` if it
exists. It is operational continuation state, not project context,
architecture, or a progress log. Follow its references. Do not ingest
unrelated docs. If the user only asked to resume or orient, confirm
readiness and wait. If they supplied a bounded task, proceed under that
working mode.

Portable orientation prompt: `core/prompts/resume.md` in the AI Platform
clone.

Update `docs/working-mode.md` only when the working mode itself changes,
not after routine bounded tasks. Durable facts belong in the
authoritative contract, ADR, or status document.

Default to a short completion: DONE or BLOCKED, what materially changed,
verification performed, and any actual concern or required human action.
Do not require headings. Do not routinely emit file lists, walkthroughs,
unchanged-behavior tables, architecture recaps, exhaustive test counts,
or long READY reports. Use a longer report when the user asks, the task
is an audit or review, architecture changed, operations require it,
something failed or is blocked, the next decision needs the detail, or
another contract requires it.

For applicable frontend or public-facing work, verification includes
`scripts/check-guardrails.sh`. Lint, tests, and build passing do not
imply that check ran. A failed guardrail check is not a green
completion.

Details: `.cursor/rules/10-documentation.mdc`.

## Scope control

Keep work inside the current bounded task. **Capture, don't expand scope.**

If you discover a bug, improvement, refactor, technical debt, or
feature outside that task: do not fix it opportunistically; do not
silently expand scope; briefly tell the developer; offer to capture it
as a work item (GitHub Issue is the reference implementation); continue
the current task unless it blocks the work. If it blocks, explain why
and ask how to proceed.

Before creating a work item, branch, or review request, read
`.cursor/rules/70-work-items.mdc`.

## Safety

Never commit unless explicitly instructed. Never push unless
explicitly instructed. Never create a work item (GitHub Issue),
branch, or review request (Pull Request) unless the developer
authorizes it. Never merge a review request. Never auto-merge. Never
delete a branch unless explicitly instructed. Never perform
destructive database operations without approval. Never modify
project dependencies or configuration without approval.

## Current-First and Framework-Native

Establish installed versions from this repository before relying on
model memory. Use the installed stack's native capabilities before
custom implementations or new packages. Details:
`.cursor/rules/00-platform.mdc`.

## Capability-on-demand

External tools are **capability-on-demand, not capability-by-default**.
Prefer the smallest active toolset that can reliably accomplish the
current work. Do not accumulate MCP servers, CLIs, integrations, or
agent tools merely because they might be useful.

Tool availability is not authorization. Tool availability is also not justification for using a tool. Invoke an available capability only
when it materially helps the bounded task. Additional MCPs are not
bootstrap dependencies. Client-specific MCP configuration stays
client-specific; capability parity across agents is not the goal.
Details: `.cursor/rules/00-platform.mdc`, `mcp/README.md`.

## Documentation

`docs/working-mode.md` is continuation state for a fresh session.
`docs/README.md` is the contract index. Load only contracts relevant to
the task. If implementation would contradict an active contract, stop
and report the conflict.

## Selective rules

Always-on core is this file plus `.cursor/rules/00-platform.mdc` when
the current agent loads Cursor rules.

Read additional rules when they apply (do not ingest all of them
up front):

| When | Rule |
| --- | --- |
| Documentation work | `.cursor/rules/10-documentation.mdc` |
| Application code | `.cursor/rules/20-coding.mdc` |
| Laravel web app | `.cursor/rules/30-laravel.mdc` |
| Roots/Radicle/Sage | `.cursor/rules/35-roots.mdc` |
| UI/UX | `.cursor/rules/40-ui.mdc` |
| Bootstrap / adoption | `.cursor/rules/50-workflows.mdc` |
| Browser QA | `.cursor/rules/60-browser-qa.mdc` |
| Issues, PRs, discovered work | `.cursor/rules/70-work-items.mdc` |
| Project-specific | `.cursor/rules/90-*.mdc` if present |

Do not apply a framework profile to a project that is not that stack.

## Skills

Canonical skill copies: `.agents/skills/` (`hallmark`). Invoke Hallmark
when `40-ui` classifies the work as significant UI, redesign, audit,
reference study, or visual-direction work. Do not load Hallmark for every
UI edit. Skills do not authorize general browser automation.

## UI design preferences

Detailed rules: `.cursor/rules/40-ui.mdc`. Hard developer constraints
that outrank Hallmark:

- Do not use decorative sequential numbering (`01 / 02 / 03` and
  equivalents) as a visual device. Numbers are allowed when they
  communicate real information.
- Do not use em dashes in generated end-user UI or marketing copy,
  including `&mdash;` and equivalent entities. Rewrite naturally.
  Preserve author punctuation when reproducing or editing existing
  source text.
- Prefer Tailwind's standard utility scale and project tokens over
  arbitrary values such as `text-[…]` or `mt-[…]`. Arbitrary values
  are genuine one-off exceptions, not a way to match a comp more
  precisely.
- Favor generous whitespace and hierarchy (type, space, scale,
  alignment) before decoration. Cards are semantic containers, not
  decoration; use them when containment earns grouping.
- Adjacent semantic sections must remain visually distinguishable.
  Do not let them merge through identical backgrounds, uninterrupted
  imagery, or insufficient spacing. This is not a mandate to alternate
  section backgrounds; whitespace or other compositional delineation
  can suffice.
- Design for this product. Avoid recognizable AI/template conventions.

Generated design images are exploration/reference artifacts, not the
implementation source of truth. Implement selected directions with the
project's framework, components, tokens, and design system. Image
generation is capability-on-demand: do not invoke it for routine UI
edits. When it is used, choose model, quality, resolution, aspect
ratio, and option count intentionally, and adapt those settings to the
artifact. Details: `.cursor/rules/40-ui.mdc`.

Do not add another design skill.

## Browser automation

Follow `.cursor/rules/60-browser-qa.mdc`. Availability is not general
authorization. Availability is also not justification for using a
browser tool the bounded task does not need. Significant UI work
authorizes a bounded Mode B visual pass of that UI only (`40-ui`). Use
the best available real-browser capability for that pass; do not treat
it as Playwright execution. Do not run Playwright or browser MCP
otherwise unless the current task explicitly authorizes it. Mode B
visual verification does not authorize Mode A tests. Significant motion
may be observed in that pass; it does not by itself authorize Mode A
or performance profiling. Report which verification level actually
occurred: static inspection, interactive real-browser verification, or
automated Playwright/E2E execution.

## Adoption

Existing-project adoption: `core/prompts/project-adoption.md` in the
AI Platform clone (bootstrap prints the path). Lifecycle: Understand →
Document → Compare → Question → Recommend → Approve → Align.

## Instruction priority

1. User instructions
2. Project instructions (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `90-*.mdc`)
3. Project documentation contracts (working mode first, then selective loading)
4. AI Platform canonical rules
5. Secondary implementation guidance (vendor skills, MCP servers, plugins,
   connector or tool guidance, vendor instructions, third-party
   documentation, generated tool instructions, external agent
   frameworks, and model defaults)

Applicable user, project, and AI Platform harness rules outrank
conflicting secondary guidance. Secondary sources can specialize; they
cannot silently weaken a project or platform requirement.

When a secondary source clearly conflicts with a higher-authority rule,
follow the higher-authority rule, note the conflict briefly if it
materially affects implementation, and do not ask the user to resolve
precedence that is already clear. Example: Hallmark recommends
typographic em dashes; generated end-user copy still must not use them.
Hallmark design reasoning does not authorize arbitrary Tailwind values
where `20-coding` requires the standard scale.

If two applicable instructions genuinely conflict and their relative
authority is unclear, or satisfying one necessarily violates the other,
stop before implementing the conflicting decision and ask which
behavior to enforce. Do not make an arbitrary choice.
