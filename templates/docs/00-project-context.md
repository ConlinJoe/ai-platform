# Project Context

This file provides the essential context ChatGPT Projects and AI agents need
before reading individual documentation contracts. Keep it concise and
current.

## What This Project Is

<!-- One paragraph: product purpose, primary users, core value. -->

## Technology Stack

<!-- Languages, frameworks, infrastructure. -->

## Documentation Model

This project uses **Documentation Contracts**. Start with `docs/README.md` for
the dependency graph and contract registry. Project AI context exports to
ChatGPT via `scripts/export-chatgpt-context.sh`.

## Key Constraints

- Current-first engineering: establish installed or current stable
  versions and official docs for those versions before relying on
  historical model knowledge. Do not upgrade an existing stack merely
  because newer versions exist (see `.cursor/rules/00-platform.mdc`).
- Framework-Native First: use the installed stack's native capabilities
  before custom implementations, parallel abstractions, or new
  dependencies (see `.cursor/rules/00-platform.mdc`).
- UI: product-specific, spacious, hierarchy-driven design. Avoid
  recognizable AI/template conventions. Cards are semantic containers,
  not decoration. Adjacent semantic sections must remain visually
  distinguishable without mechanically alternating backgrounds
  (see `.cursor/rules/40-ui.mdc`).
- Generated public-facing copy must not use em dashes. Prefer standard
  Tailwind utilities and project tokens over arbitrary values
  (see `.cursor/rules/20-coding.mdc`, `.cursor/rules/40-ui.mdc`).

<!-- Additional non-negotiable technical, business, or operational constraints. -->

## Where to Look

| Need | Contract |
| --- | --- |
| Product vision | `contracts/foundational/vision.md` |
| System architecture | `contracts/foundational/architecture.md` |
| Architectural decisions | `contracts/adrs/` |
| Current working mode | `working-mode.md` |
| Implementation status | `99-project-status.md` |

Update this table as contracts are added.
