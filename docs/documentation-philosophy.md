# Documentation Philosophy

Documentation is a collection of **contracts** between the project and every
person or AI agent that works on it. Each contract owns one slice of truth.
Agents load only the contracts relevant to the task at hand.

This philosophy replaces the assumption that every project shares the same
four markdown files (`project.md`, `architecture.md`, `decisions.md`,
`roadmap.md`). Small projects may still have only a handful of contracts.
Large systems like QuoteBox may have dozens, split by domain, engine, or
feature.

## Core Principles

### 1. Contracts, not generic files

A documentation contract is a focused document that defines behavior,
architecture, rules, or decisions for exactly one concern. Contracts are
named and organized by responsibility, not by a platform-wide filename
mandate.

### 2. Single responsibility

Every contract answers one primary question. If a document covers unrelated
concerns, split it.

Examples:

- Good: `contracts/engines/billing.md` — billing rules and integration points
- Good: `contracts/adrs/0003-queue-driver.md` — one architectural decision
- Bad: one file mixing product vision, folder layout, and API design

### 3. Selective loading

AI agents must not load the entire documentation tree for every task. They
start with the documentation index, identify relevant contracts, then load
only those contracts and their declared dependencies.

### 4. Project-specific structure

Each project defines its own contract layout. The platform defines **types,
metadata, and behavior** — not a fixed set of filenames or folder depths.

### 5. README as index and dependency graph

`docs/README.md` is the canonical documentation index. It lists every
contract, its type, status, and relationships. Contracts with type
`foundational` are stable, high-level context for agent loading. It is the
entry point for humans and agents.

`docs/00-project-context.md` is the concise ChatGPT entry point: project
purpose, stack, constraints, and pointers to key contracts.

The project root `README.md` may summarize the project and link to
`docs/README.md`, but the documentation index lives under `docs/`.

### 6. Required metadata

Every contract begins with YAML frontmatter:

```yaml
---
status: active | draft | deprecated | superseded
last_reviewed: YYYY-MM-DD
source_of_truth_for:
  - What this document owns
depends_on:
  - path/to/other-contract.md
referenced_by:
  - path/to/dependent-contract.md
type: foundational | engine | feature | adr | planning
---
```

| Field | Purpose |
| --- | --- |
| `status` | Lifecycle of this contract |
| `last_reviewed` | Last date a human or agent verified accuracy |
| `source_of_truth_for` | Topics this document authoritatively defines |
| `depends_on` | Contracts that must be read first |
| `referenced_by` | Contracts that depend on this one (maintained in index) |
| `type` | Contract classification (see below) |

### 7. ADRs are first-class

Architecture Decision Records are individual contracts, not entries in a
shared log file. One decision, one file, under `type: adr`.

Recommended naming: `contracts/adrs/NNNN-short-title.md` (zero-padded
sequence number).

Each ADR includes:

- Context
- Decision
- Consequences
- Status (accepted, superseded, deprecated)

When a decision is superseded, update the old ADR's status and link to the
new ADR. Do not delete historical ADRs.

### 8. Documentation is part of implementation

Every implementation must end with a documentation outcome:

1. **Update** the affected contract(s), or
2. **Explicitly state** why no documentation changes were required, or
3. **Stop and report** a documentation conflict

There is no silent fourth option.

### 9. Conflicts must surface

If implementation contradicts an active contract, the agent must stop and
report the conflict. It must not guess, reinterpret, or silently override
documentation.

Conflict report format:

```
Documentation conflict detected.

Contract: docs/contracts/engines/billing.md
Conflict: Contract requires idempotent webhooks; implementation retries without idempotency key.
Resolution needed: Update contract OR change implementation.
```

The user resolves the conflict before work continues.

### 10. Contract types

| Type | Purpose | Change frequency |
| --- | --- | --- |
| `foundational` | Vision, domain model, platform-wide architecture | Rarely |
| `engine` | Subsystem or bounded context (auth, billing, search) | Occasionally |
| `feature` | User-visible or API feature behavior | Regularly |
| `adr` | Single architectural or technical decision | Immutable history; supersede instead of edit |
| `planning` | Roadmaps, spikes, temporary plans | Temporary; not source of truth for implementation |
| `status` | Current implementation progress and readiness | Snapshot; not architectural authority |

**Planning documents** must never be treated as implementation authority.
When a plan is executed, its durable truths move into foundational, engine,
feature, or ADR contracts.

### 11. Scale naturally

| Project size | Typical contract count |
| --- | --- |
| Small utility or prototype | 2–5 contracts + index |
| Standard web application | 5–15 contracts + ADRs |
| Large SaaS platform | 20–50+ contracts + ADRs |

More complexity earns more contracts. Do not split prematurely.

### 12. Minimize token usage

The index enables surgical loading:

1. Read `docs/README.md`
2. Match task scope to `source_of_truth_for` entries
3. Load matched contracts plus `depends_on` chain only
4. Skip unrelated contracts, deprecated contracts, and planning docs unless
   explicitly requested

## ChatGPT Projects

ChatGPT Projects receive project AI context via a single export command:

```bash
scripts/export-chatgpt-context.sh
```

### Export workflow

1. Maintain contracts under `docs/` in the repository
2. Run `scripts/export-chatgpt-context.sh` from the project root
3. Upload `.build/chatgpt-context.zip` to the ChatGPT Project
4. Re-export when documentation, Cursor rules, agent skills, or AI metadata
   change

### Export includes

- `docs/` (all contracts and ADRs)
- `.cursor/rules/`
- `.agents/` (if present)
- `skills-lock.json` (if present)
- Project-specific AI documentation (if present)

### Export excludes

Source code, vendor, tests, generated files, and build artifacts.

See `docs/chatgpt-projects.md` for the full workflow.

## Documentation Index Structure

`docs/README.md` must include:

1. **Overview** — how documentation is organized in this project
2. **Contract registry** — table of all contracts with type and status
3. **Dependency graph** — which contracts depend on which (text, mermaid, or
   both)
4. **Loading guide** — hints for common task types (e.g., "billing work →
   load X, Y, Z")

Example registry row:

| Contract | Type | Status | Source of Truth For |
| --- | --- | --- | --- |
| `contracts/foundational/vision.md` | foundational | active | Product purpose, constraints |
| `contracts/engines/billing.md` | engine | active | Billing rules, Stripe integration |

## Agent Workflow

### Before implementation

1. Load `docs/README.md`
2. Identify relevant contracts from the task description and index
3. Load those contracts and their `depends_on` dependencies
4. If contracts are missing for the work scope, ask whether to create them
   or proceed under explicit user direction

### During implementation

Follow active contracts. Treat `source_of_truth_for` as authoritative for
its scope.

### After implementation

1. Determine which contracts were affected
2. Update them, or state why no update is needed
3. Update `last_reviewed` on touched contracts
4. Update `docs/README.md` if contracts were added, removed, or dependencies
   changed
5. Sync `referenced_by` in the index when dependencies shift

## Migration from Legacy Structure

Projects using the old four-file layout may migrate gradually:

| Legacy file | Typical migration target |
| --- | --- |
| `project.md` | `foundational/vision.md` + feature contracts |
| `architecture.md` | `foundational/architecture.md` + engine contracts |
| `decisions.md` | Individual files under `contracts/adrs/` |
| `roadmap.md` | `planning/roadmap.md` (type: planning) |

During migration, note legacy mapping in `docs/README.md` until the old files
are removed.

The export script supports legacy projects without a contract registry by
falling back to `project.md`, `architecture.md`, and `decisions.md`.

## Relationship to Platform Rules

- **Instruction priority**: Project rules → project documentation contracts →
  AI Platform → vendor skills
- **Conflicts between rules and contracts**: Surface to the user; do not
  guess
- **New projects**: Start with the minimum viable contract set (see
  `templates/docs/`)
