# Laravel Boost MCP

Boost is a **project-scoped** MCP server. The AI Platform does not register
it globally and does not write `.cursor/mcp.json`.

Authoritative policy: `docs/contracts/features/laravel-boost.md`  
Decision: `docs/contracts/adrs/0002-laravel-boost-ownership.md`  
Installer: [Laravel Boost](https://laravel.com/docs/boost) and the installed
`laravel/boost` package.

## Expected project config (written by Boost, not by this platform)

```json
{
  "mcpServers": {
    "laravel-boost": {
      "command": "php",
      "args": ["artisan", "boost:mcp"]
    }
  }
}
```

Path: `.cursor/mcp.json` (Cursor). After install, enable `laravel-boost` in
Cursor MCP settings.

## Platform behavior

- `doctor.sh` FAILs Laravel web apps that lack declared/installed/configured Boost.
- `bootstrap-project.sh` diagnoses and prints native install steps.
- Neither script runs `composer require` or `boost:install`.
