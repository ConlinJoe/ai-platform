---
status: accepted
last_reviewed: 2026-10-29
source_of_truth_for:
  - Decision that project and platform rules outrank conflicting secondary skill, MCP, plugin, vendor, and tool guidance
  - Decision that em-dash and Tailwind arbitrary-value rules are mechanically checked on changed application sources
  - Decision that Hallmark is not forked to encode those preferences
depends_on:
  - 0004-design-stack-and-ui-visual-verification.md
  - ../features/copy-and-tailwind-guardrails.md
referenced_by:
  - ../features/copy-and-tailwind-guardrails.md
  - 0011-stack-native-architecture.md
  - ../../../.cursor/rules/00-platform.mdc
  - ../../../.cursor/rules/20-coding.mdc
  - ../../../.cursor/rules/40-ui.mdc
type: adr
---

# ADR-0006: Instruction precedence and mechanical copy/Tailwind guardrails

## Status

Accepted

## Context

Instruction-only rules did not prevent generated marketing copy from
using em dashes, or Tailwind markup from using arbitrary utilities such
as `text-[1.2rem]` where the standard scale was appropriate.

Hallmark, a vendor skill, encourages typographic em dashes and includes
CSS/token recipes that are easy to translate into one-off arbitrary
Tailwind values. `40-ui` already outranks Hallmark, but that override
was easy to miss, and Hallmark's own slop-test is not a project pass
condition.

Normal validation (doctor wiring, lint, tests, build) did not inspect
these standards. Agents could report a green completion while skipping
them.

## Decision

1. Applicable user, project, and AI Platform harness rules are
   authoritative over conflicting secondary implementation guidance
   (skills, MCP servers, plugins, connector/tool guidance, vendor
   instructions, third-party documentation, generated tool
   instructions, external agent frameworks, and model defaults).
2. Clear conflicts follow the higher-authority rule without asking.
   Genuine ambiguity, where relative authority is unclear or one
   instruction cannot be satisfied without violating the other, stops
   for user clarification.
3. Do not fork Hallmark. Encode the override in harness rules and
   enforce it in the validation path.
4. Consuming projects and agents run `scripts/check-guardrails.sh` on
   newly written or modified public-facing / frontend sources before
   reporting DONE. The check fails closed on prohibited em-dash forms
   and on scoped arbitrary Tailwind utilities unless a documented
   exception marker is present.
5. Lint, tests, and build passing do not imply this check ran. A failed
   check is not a green completion.

## Consequences

### Positive

- Secondary skills cannot silently reverse project copy or Tailwind
  rules
- Agents have a mechanical DONE gate for the confirmed failure modes
- Legitimate source-fidelity copy and genuine one-off arbitrary values
  remain possible without a global exemption

### Negative

- Historical files are not scanned unless they change
- Exception markers are honor-system accountability, not a proof that
  the exception is justified
- Agents can still skip the script; the rules now make that an invalid
  green completion rather than an invisible gap

## Alternatives considered

- Fork Hallmark to remove em-dash guidance — rejected; ADR 0004 keeps
  developer preferences in `40-ui`
- Ban every Tailwind arbitrary value — rejected; genuine exceptions
  remain valid
- Scan the entire project on every doctor run — rejected; noisy on
  adopted codebases and outside the newly-written/modified scope
- Git hooks or CI as the only gate — rejected as broad infrastructure;
  the script is available for those uses without requiring them
