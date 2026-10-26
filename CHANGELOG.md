# Changelog

## Unreleased

Substantial redesigns and authorized new expressive directions resolve
creative direction, including motion, before the review comp. The agent
infers what the project already decides and asks only when a
consequential choice is still open. Subtle motion is the preferred
recommendation when motion fits. The existing comp remains the only
approval gate. When motion matters, that artifact includes the motion
treatment and, if timing would change the decision, a browser-openable
preview. Simple CSS entrances do not need a separate prototype. GSAP
and Higgsfield stay optional and are not harness dependencies.
Reference: `core/prompts/creative-direction.md`. Decisions: ADR 0004
and ADR 0008.

Roots upgrades and Roots security assessments follow one procedure for
whatever mix of Bedrock, Sage, Radicle, Acorn, and Bud a project
already uses. The assessment is read-only until a specific stage is
approved. The newest major is not the default target, and a routine
update of one package inside its current constraint does not use the
full workflow. Findings stay in the application project's planning
contract. Canonical:
`docs/contracts/features/roots-upgrade.md`. Runbook:
`core/prompts/roots-upgrade.md`. Decision: ADR 0009.

Projects that accept public submissions include server-side spam and
abuse protection when that surface is built. Contact and lead forms,
quote requests, registration, comments, and other endpoints that create
records, send mail, or trigger costly work are in scope. A browser
widget, JavaScript check, or CSRF token alone does not count. Projects
with no such surface record `not applicable`. Existing-project adoption
inventories current endpoints and protection and does not silently
retrofit or deploy them. Canonical requirement:
`docs/contracts/features/spam-and-abuse-protection.md`.

Bootstrap adds one `.DS_Store` rule to a project `.gitignore` when macOS
metadata is not already ignored in every directory. An existing global
rule (`.DS_Store`, `**/.DS_Store`, or `*.DS_Store`) is left unchanged.
Path-specific rules do not count as full coverage, and existing
`.gitignore` contents are preserved.

A substantial UI redesign requires a project-local review comp and
explicit approval before application UI changes. The comp shows the
key screens and relevant states at mobile and desktop sizes, and it
opens from `design-reviews/<slug>/index.html` in a regular browser.
Small polish, copy changes, and straightforward fixes stay on the
existing path. The comp is a review artifact. Creating it does not
authorize deployment. Procedure: `.cursor/rules/40-ui.mdc`. Checklist:
`core/prompts/ui-comp-approval.md`. Decision: ADR 0008.

WordPress projects that use Tailwind and `theme.json` (including
Radicle/Sage) keep typography and color in the project Tailwind tokens.
`theme.json` presets alias those tokens. Editorial element styles stay
scoped to the block editor canvas and the published content region.
Canonical rule: `.cursor/rules/36-wordpress-theme.mdc`.

Impeccable 4.3.1 is now the primary managed skill for significant
product/application UI, including shaping, responsive adaptation,
critique, hardening, polish, and technical audit. Hallmark remains the
specialist for expressive marketing, campaign/editorial, reference
study, and alternate art direction. `40-ui` loads one by default.
`frontend-design`, `ui-ux-pro-max`, and Superdesign remain retired.

`40-ui` now encodes durable, framework-neutral usability principles
alongside the existing visual floor: task-first interaction, capable
simplicity (not empty screens), progressive disclosure, familiar
patterns, preserved context, control proximity, touch-first targets
where applicable, typography as hierarchy, craft as product quality,
and restraint against globally prescribed visual trends. Design skills
remain secondary to project design systems, approved visual
references, accessibility, and these principles.

## 1.3.0 — 2026-09-01

Optional Deployer capability. The harness can install a standardized
SSH/PHP deployment foundation for Laravel, Bedrock/Sage, Bedrock, and
conventional WordPress. It remains capability-on-demand: absent without
doctor warnings when not selected, independently installable later.

Interactive bootstrap may ask `Install Deployer deployment stack? [y/N]`
(default N) when the harness-managed stack is absent. `--with-deployer`
installs it without prompting. `--without-deployer` skips it. Automated
and agent-driven bootstrap should pass an explicit flag.
`scripts/install-deployer.sh` adds the stack to an already-bootstrapped
project without rerunning adoption.

Each supported profile gets its own recipe. Host, repository, and SSH
values live in gitignored `deploy/hosts.yaml`. Secrets are not
generated or committed. Selecting install authorizes only the
`deployer/deployer` Composer declaration and harness-managed files. It
does not run `composer install` and does not deploy.

Canonical reference: `docs/contracts/features/deployer.md`. ADR 0007.
Project-local notes land at `docs/contracts/features/deployment.md` when
the installer creates that file. Existing Deployer configuration is
preserved (Current-First). Conflicting files stop that installation
path. Installing or configuring Deployer does not authorize deployment.
Production deploys still require a restorable backup. The
catastrophic-operation guardrail applies to deployment scripts.

This release does **not** implement the deferred project-local `.ai/`
portability architecture. Absolute rule symlinks remain the bootstrap
model.

Also included from the previous unreleased working tree: public
documentation landing page and focused guides; copy/Tailwind
guardrails (ADR 0006); working-mode continuation (ADR 0005);
capability-on-demand and capability-aware browser verification;
bootstrap `.gitignore` hygiene for `.DS_Store` and `.ai/`.

## 1.2.0 — 2026-08-23

Simplified the UI/UX design stack. Hallmark is the only managed design
skill. `frontend-design`, `ui-ux-pro-max`, and Superdesign were removed
from the harness.

`40-ui` now classifies UI work as small, significant, or exploration.
Hallmark loads only when that classification warrants it. Significant UI
authorizes a bounded Playwright Mode B visual pass of that UI; Mode A
workflow/regression tests remain separately authorized. Small UI does
not automatically load Hallmark or start a browser QA loop.

Significant UI is reviewed against a WCAG 2.2 AA accessibility floor and
a short rendered design-review protocol. References (screenshots, URLs,
named aesthetics) supply design language; they do not override the
current product. Framework-native implementation and an established
project design system remain authoritative.

Claude and Grok adapters expose only Hallmark. Bootstrap prunes retired
managed skills on re-run, adds `.hallmark/` to project gitignores, and
keeps Cursor, Grok Build, Codex, Claude Code, and Hermes supported.
Doctor and platform tests cover the new stack.

`40-ui` now encodes hard developer constraints against decorative
sequential numbering and em dashes in generated end-user copy, plus
anti-AI-template heuristics, generous whitespace, and
hierarchy-before-decoration. These preferences outrank Hallmark and
apply to new work in adopted projects without silently restyling
existing interfaces.
