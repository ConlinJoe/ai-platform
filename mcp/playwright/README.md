# Playwright and browser MCP

Mode A (deterministic `@playwright/test`) is **project-owned**.
Mode B (agentic exploration) uses **available browser MCP**, typically
user-global Playwright MCP and/or BrowserMCP.

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

Agent invocation is opt-in. Playwright MCP being configured does not
authorize Mode B. Do not run Playwright or browser MCP unless the current
task explicitly instructs it (`.cursor/rules/60-browser-qa.mdc`).

Do not treat Playwright MCP as the regression suite.

The `mcp/browser/` directory is reserved for additional browser-tool notes;
policy lives in the browser-QA contract, not here.
