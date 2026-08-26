# Playwright and browser MCP

Mode A (deterministic `@playwright/test`) is **project-owned**.
Mode B (agentic exploration) uses the **best available real-browser
capability** in the current environment: an IDE-integrated browser,
browser MCP (typically user-global Playwright MCP and/or BrowserMCP),
or equivalent. An interactive real-browser pass is not Playwright
execution.

Authoritative policy: `docs/contracts/features/browser-qa.md`

The AI Platform does **not** install Playwright MCP. Configure it in
Cursor as a **user-global** server.

## User-global Cursor config

File: `~/.cursor/mcp.json` (machine-level; applies across projects).

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

Equivalent UI: Cursor Settings → MCP → Add new MCP Server, command
`npx -y @playwright/mcp@latest`. Enable the server in Cursor MCP
settings after adding it.

Official package: [`@playwright/mcp`](https://github.com/microsoft/playwright-mcp).
That package documents Node.js 18+.

Do **not** add Playwright MCP to a Laravel app's `.cursor/mcp.json` to
satisfy this platform — that file is owned by Laravel Boost.

## Invocation

Agent invocation follows `.cursor/rules/60-browser-qa.mdc`. Playwright MCP
being configured does not generally authorize Mode B. Availability is
also not justification for using it when the bounded task does not need
it. Significant UI authorizes a bounded Mode B visual pass of that UI
only (`40-ui`). Use the best available real-browser capability for that
pass; do not treat it as Playwright execution. That pass may observe
relevant animation states when
meaningful motion is involved; it does not authorize Mode A or
performance profiling. Do not treat Playwright MCP as the regression
suite. If Playwright is required but its browser binary is unavailable,
report that Playwright was not executed and what interactive
verification ran instead.

The `mcp/browser/` directory is reserved for additional browser-tool notes;
policy lives in the browser-QA contract, not here.
