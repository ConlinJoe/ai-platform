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

## Documentation

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
- Do not use em dashes in generated end-user UI or marketing copy.
  Rewrite naturally. Preserve author punctuation when reproducing or
  editing existing source text.
- Favor generous whitespace and hierarchy (type, space, scale,
  alignment) over cards, dividers, badges, and decoration.
- Design for this product. Avoid recognizable AI/template conventions.

Do not add another design skill.

## Browser automation

Follow `.cursor/rules/60-browser-qa.mdc`. Availability is not general
authorization. Significant UI work authorizes a bounded Mode B visual
pass of that UI only (`40-ui`). Do not run Playwright or browser MCP
otherwise unless the current task explicitly authorizes it. Mode B visual
verification does not authorize Mode A tests.

## Adoption

Existing-project adoption: `core/prompts/project-adoption.md` in the
AI Platform clone (bootstrap prints the path). Lifecycle: Understand →
Document → Compare → Question → Recommend → Approve → Align.

## Instruction priority

1. User instructions
2. Project instructions (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `90-*.mdc`)
3. Project documentation contracts
4. AI Platform canonical rules
5. Vendor skills
