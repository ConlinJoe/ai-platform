# Playwright and browser MCP

Mode A (deterministic `@playwright/test`) is **project-owned**.  
Mode B (agentic exploration) uses **available browser MCP**, typically
user-global Playwright MCP and/or browsermcp.

Authoritative policy: `docs/contracts/features/browser-qa.md`

Do not treat Playwright MCP as the regression suite. Do not add Playwright
MCP to a project's `.cursor/mcp.json` in order to satisfy this platform —
that file is owned by Laravel Boost on Laravel apps.

The `mcp/browser/` directory is reserved for additional browser-tool notes;
policy lives in the browser-QA contract, not here.
