# Existing-project bootstrap

The AI Platform is not copied into an existing project as if the project
were greenfield. Bootstrap **reconciles** the project with the platform.

Policy companions: `.cursor/rules/50-workflows.mdc`,
`templates/existing-project/platform-reconciliation.md`.

## Sequence

1. Inspect the actual project: layout, installed versions, architecture,
   existing docs, ADRs, tests, MCP, and UI stack.
2. Run platform bootstrap (rules, export script, doctor link, skills).
   Bootstrap must not overwrite existing documentation.
3. Bring in missing platform templates (draft only): documentation gaps,
   browser-QA contract if the profile expects it, reconciliation contract.
4. Fill `docs/00-project-context.md` and foundational contracts from
   **this** project's reality, not leftover placeholders.
5. Reconcile ADRs with the real architecture.
6. Document legitimate project-specific differences in
   `docs/contracts/foundational/platform-reconciliation.md`.
7. Surface meaningful deviations from current platform best practices to
   the developer. Do not silently bless them.
8. Do not migrate or refactor application code as part of bootstrap.
   Architectural/code changes outside safe bootstrap and documentation
   work require developer approval.

## Result

Platform standards + developer preferences + actual project architecture
→ a documented, reconciled project harness.

## Laravel extras

- Diagnose Laravel Boost; do not install it without approval.
- Diagnose Playwright Mode A expectations; do not add `@playwright/test`
  without approval.
- Leave Boost-owned files (`AGENTS.md`, `.cursor/mcp.json`, Boost skills)
  under Boost's installer.
