# Browser MCP

Reserved for browser-tool notes. Policy for Mode A / Mode B lives in
`docs/contracts/features/browser-qa.md`. Playwright MCP vs project Playwright
is summarized in `mcp/playwright/README.md`. Agent invocation is opt-in
(`.cursor/rules/60-browser-qa.mdc`).

BrowserMCP is a typical **user-global** Cursor MCP for Mode B. The AI
Platform does not install it, does not write its config, and does not
treat it as required. Configure it in Cursor Settings → MCP if you use
it. Do not add it to a Laravel app's `.cursor/mcp.json` (Boost owns that
file).
