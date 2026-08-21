# Project Adoption Prompt

Use this prompt in a **fresh session of the current coding agent** in the
target project after `/path/to/ai-platform/scripts/bootstrap-project.sh`
has provisioned the AI Platform. Bootstrap only links shared
infrastructure. This prompt performs the intelligent adoption work.

The clone path is whatever the developer chose (see the repository
`README.md`). Bootstrap prints this file's absolute path. From the
target project you can also resolve it via a shared-rule symlink:

```bash
AI_PLATFORM="$(cd "$(dirname "$(readlink .cursor/rules/00-platform.mdc)")/../.." && pwd)"
echo "${AI_PLATFORM}/core/prompts/project-adoption.md"
```

Paste the **Agent instructions** below, or instruct the agent to follow
this file.

---

## Agent instructions

Adopt this existing repository into the AI Platform.

Sequence: **Understand → Document → Compare → Question → Recommend → Approve → Align.**

Do **not**: apply platform conventions blindly; migrate or refactor
application code because the project differs from platform defaults; or
treat bootstrap as if it already understood the project.

During adoption, the usual "do not load all documentation" rule does
**not** apply. Read the existing docs set before changing anything.

Presenting classified findings and grouped questions is required. Each
remediation still has one recommended state.

### 1. Read applicable AI Platform rules first

Read, in order:

1. Project instructions already loaded (`AGENTS.md`, `CLAUDE.md`, and/or
   `.cursor/rules/00-platform.mdc`)
2. `core/agent-core.md` in the AI Platform clone (canonical always-on core)
3. `.cursor/rules/10-documentation.mdc`
4. `.cursor/rules/50-workflows.mdc`
5. Any existing project-owned `.cursor/rules/90-*.mdc`

Then read stack rules that apply to **this** repository:

- Laravel web app: `.cursor/rules/30-laravel.mdc`,
  `core/project-profiles/laravel-webapp.md` (via the AI Platform clone)
- Roots/Radicle/Sage: `.cursor/rules/35-roots.mdc`,
  `core/project-profiles/roots-radicle.md`
- UI work in scope: `.cursor/rules/40-ui.mdc`
- Browser-capable Laravel: `.cursor/rules/60-browser-qa.mdc`
- Coding standards when inspecting source: `.cursor/rules/20-coding.mdc`

Find the AI Platform clone from a shared-rule symlink target when
present. Do not apply a profile that this project is not.

Do not run Playwright or other browser automation unless this session
explicitly authorizes it.

### 2. Establish identity before changing anything

Confirm the currently open repository is the project being adopted.
Use repository name, documentation, architecture, source tree, package
metadata, and project-specific rules.

If the request belongs to a different project, stop. Do not modify this
repository.

Then determine:

- Product name and purpose
- Primary users and core value
- What the software actually does today versus what docs/roadmap claim
- Whether a platform profile applies (`laravel-webapp`, `roots-radicle`,
  or none)

### 3. Read the entire existing documentation set

Read every existing file under `docs/` before assuming intent. Include
legacy layouts (`project.md`, `architecture.md`, `decisions.md`,
`roadmap.md`) if present.

Distinguish:

- **Implemented** — evidenced by source, config, tests, CI, or runtime
- **Planned** — roadmap, TODOs, placeholders, aspirational README text
- **Unknown** — cannot be established from the repository

Do not treat template placeholders or marketing copy as architecture.

### 4. Inspect the implementation

Establish current reality from the repository. Do not assume versions or
architecture from model memory.

Inspect, as applicable:

- Package manifests and lock files (`composer.json` / `composer.lock`,
  `package.json` / lockfile, language-specific equivalents)
- Installed framework, language, and toolchain versions
- Configuration (env examples, framework config, CI/CD)
- Directory structure and source architecture
- Tests and how they are run
- MCP, editor, and agent config
- Deployment/infrastructure evidence that exists in-repo

Follow Current-First Engineering and Framework-Native First in
`00-platform`. The installed environment is the starting point. Do not
upgrade anything merely because a newer version exists.

### 5. Compare against standards

Compare the project to:

- AI Platform standards
- Applicable framework best practices for the **installed** versions
- Current architectural best practices for this class of system
- Testing expectations
- Security expectations
- Maintainability and code-quality expectations

Classify every meaningful finding:

**A. Sound existing decisions**
Document and preserve them.

**B. Differences from platform preferences that are reasonable**
Document them. Do not change them merely for conformity.

**C. Outdated, unsafe, structurally problematic, or contrary to current
best practices**
Explain the issue and recommend a change. Do not silently preserve a
bad pattern. Do not implement the change yet.

**D. Cannot safely be inferred**
Ask the developer.

Scattered misuse of a framework is not a convention to copy.

### 6. Ask only real questions

Do not interrogate the developer about facts the repository already
establishes (versions, layout, which test runner exists, obvious stack).

Ask only when the answer is a genuine product, business, architectural,
security, or implementation decision that cannot safely be inferred.

Group questions. Prefer one grouped set over a series of single
questions.

### 7. Create or update canonical documentation

After inspection, create or update project-owned documentation so it
describes **this** project. Use the contract model in
`10-documentation`. Copy structure from AI Platform
`templates/docs/` and `templates/existing-project/platform-reconciliation.md`
when a needed file does not exist. Do not overwrite truthful existing
docs; replace leftover placeholders.

Required outcomes:

| Need | Where |
| --- | --- |
| Purpose | `docs/00-project-context.md`, `docs/contracts/foundational/vision.md` |
| Architecture | `docs/contracts/foundational/architecture.md` |
| Significant decisions | `docs/contracts/adrs/` (one decision per file) |
| Important boundaries/behaviors | applicable engine/feature contracts |
| Current status | `docs/99-project-status.md` |
| Planned work and deferred remediation | `docs/contracts/planning/roadmap.md` |
| Index | `docs/README.md` (registry + dependency graph) |
| A/B/C/D findings | `docs/contracts/foundational/platform-reconciliation.md` |

Laravel web apps also need `docs/contracts/features/browser-qa.md` when
the profile applies.

Write ADRs only for significant decisions that repository evidence can
establish. Do not manufacture an ADR per dependency.

Do not duplicate unnecessarily:

- `00-project-context.md` summarizes and points; it does not own architecture
- Vision owns purpose; architecture owns structure
- ADRs own individual decisions
- Reconciliation owns classified differences, not the architecture itself
- Roadmap and status are not implementation authority

Keep `depends_on` / `referenced_by` and `docs/README.md` accurate. Set
`last_reviewed` to today on touched contracts.

Documentation of verified existing behavior is allowed in this phase.
Material implementation or architectural change is not, until section 8
approval.

### 8. Human approval boundary

Do **not** make material implementation, dependency, configuration, or
architectural changes simply because the project differs from AI
Platform standards.

For each material **C** recommendation, present:

- **Current state**
- **Problem**
- **Recommended state**
- **Reason**
- **Expected impact**
- **Migration / risk** when relevant

Then wait for the developer. Do not implement first.

After the developer responds:

- **Approve** — implement the approved item, then update docs to match
- **Defer** — place it on the roadmap; do not treat deferral as approval
- **Reject / keep** — record it as a **B** intentional difference

Do not commit unless explicitly instructed.

### 9. Project-specific agent guidance

When this project needs guidance that shared platform rules do not
cover (identity, domain language, local commands, approved exceptions):

- Cursor: project-owned `.cursor/rules/90-<project-slug>.mdc` (real file,
  never a symlink into the AI Platform; do not reuse shared rule names)
- Other agents: keep `AGENTS.md` / `CLAUDE.md` as thin pointers to
  canonical rules; put durable project truth in `docs/` contracts

Do not duplicate shared platform rules. If no project-specific rule is
warranted, say so and skip.

### 10. Profile extras (only if they apply)

**Laravel web app**

- Diagnose Laravel Boost; do not install it without approval.
- Playwright Mode A is expected; do not add `@playwright/test` without
  approval. Do not run Playwright unless this session authorizes it.
- Leave Boost-owned files (`AGENTS.md`, `.cursor/mcp.json`, Boost skills)
  under Boost's installer. Keep `.ai/guidelines/ai-platform.md` (symlink
  to `core/agent-core.md`). After Boost install/update, generated agent
  files should include that guideline.

**Roots / Radicle / Sage**

- Do not treat the project as `laravel-webapp`.
- Inspect navigation, ACF/fields, slider/gallery, forms, and page/menu
  architecture first.
- If Log1x Navi, ACF Pro, Keen Slider, or WPForms is installed, use it
  correctly for the installed version.
- Preserve intentional mature alternatives (including Gravity Forms or
  Swiper). Report divergence from the preferred greenfield stack. Ask
  before replacing or migrating.
- Do not install, upgrade, or migrate Navi, ACF, Keen, WPForms, or
  Gravity Forms as part of adoption unless the developer approves that
  remediation.
- Do not invent a custom form fallback, substitute free ACF for Pro, or
  commit secrets.
- Do not re-provision or restructure production WordPress content during
  adoption.

### 11. Completion criteria

Adoption is complete only when all of the following are true:

- Project purpose is documented
- Architecture is documented
- Significant architectural decisions are captured
- Applicable contracts are documented
- Roadmap and current status are documented
- Project-specific agent rules are established where needed
- Important deviations have been reviewed with the developer
- Approved remediation has been completed **or** explicitly placed on
  the roadmap
- Documentation reflects the resulting implementation

The project must be **understood by the AI Platform** and
**intentionally aligned with it**, not merely bootstrapped.

When documentation, project instructions, agent skills, or AI metadata change,
tell the developer they can run `scripts/export-chatgpt-context.sh` from the
project (after bootstrap, a symlink) and upload `.build/chatgpt-context.zip`
to their ChatGPT Project.
