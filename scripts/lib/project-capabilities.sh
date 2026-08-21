#!/usr/bin/env bash
# Shared project-capability detection for bootstrap-project.sh and doctor.sh.
# Source this file; do not execute it.

composer_has_package() {
  local dir="$1"
  local pkg="$2"
  local composer="${dir}/composer.json"

  [[ -f "${composer}" ]] || return 1

  python3 - "${composer}" "${pkg}" <<'PY'
import json
import sys

path, package = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

for key in ("require", "require-dev"):
    if package in data.get(key, {}):
        sys.exit(0)

sys.exit(1)
PY
}

npm_has_package() {
  local dir="$1"
  local pkg="$2"
  local package_json="${dir}/package.json"

  [[ -f "${package_json}" ]] || return 1

  python3 - "${package_json}" "${pkg}" <<'PY'
import json
import sys

path, package = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

for key in ("dependencies", "devDependencies", "optionalDependencies"):
    if package in data.get(key, {}):
        sys.exit(0)

sys.exit(1)
PY
}

json_has_mcp_server() {
  local file="$1"
  local name="$2"

  [[ -f "${file}" ]] || return 1

  if python3 - "${file}" "${name}" <<'PY'
import json
import sys

path, name = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except json.JSONDecodeError:
    sys.exit(2)

servers = data.get("mcpServers") or data.get("servers") or {}
sys.exit(0 if name in servers else 1)
PY
  then
    return 0
  fi

  local status=$?
  if [[ "${status}" -eq 2 ]]; then
    grep -qE "\"${name}\"[[:space:]]*:" "${file}"
    return $?
  fi

  return 1
}

project_is_laravel() {
  composer_has_package "$1" "laravel/framework"
}

# The platform currently has one Laravel profile: laravel-webapp.
project_is_laravel_webapp() {
  project_is_laravel "$1"
}

# Roots Radicle applications and Sage themes (typically with Acorn).
# Do not treat Bedrock/WordPress-only composer packages as this profile.
project_is_roots_radicle() {
  composer_has_package "$1" "roots/radicle" && return 0
  composer_has_package "$1" "roots/sage" && return 0
  composer_has_package "$1" "roots/acorn" && return 0
  return 1
}

project_uses_livewire() {
  composer_has_package "$1" "livewire/livewire"
}

boost_declared() {
  composer_has_package "$1" "laravel/boost"
}

boost_installed() {
  [[ -d "$1/vendor/laravel/boost" ]]
}

boost_mcp_configured() {
  local dir="$1"
  json_has_mcp_server "${dir}/.cursor/mcp.json" "laravel-boost" && return 0
  json_has_mcp_server "${dir}/.mcp.json" "laravel-boost" && return 0
  return 1
}

boost_artisan_available() {
  [[ -f "$1/artisan" && -d "$1/vendor/laravel/boost" ]]
}

playwright_config_present() {
  local dir="$1"
  local candidate
  for candidate in \
    "${dir}/playwright.config.ts" \
    "${dir}/playwright.config.js" \
    "${dir}/playwright.config.mts" \
    "${dir}/playwright.config.mjs"
  do
    [[ -f "${candidate}" ]] && return 0
  done
  return 1
}

playwright_present() {
  playwright_config_present "$1" && return 0
  npm_has_package "$1" "@playwright/test"
}

playwright_expected() {
  project_is_laravel_webapp "$1"
}

playwright_artifacts_gitignored() {
  local gitignore="$1/.gitignore"

  [[ -f "${gitignore}" ]] || return 1

  grep -qE '(^|/)playwright-report/?$' "${gitignore}" || return 1
  grep -qE '(^|/)test-results/?$' "${gitignore}" || return 1
  return 0
}

docs_index_present() {
  [[ -f "$1/docs/README.md" ]]
}

browser_qa_contract_present() {
  [[ -f "$1/docs/contracts/features/browser-qa.md" ]]
}

reconciliation_contract_present() {
  [[ -f "$1/docs/contracts/foundational/platform-reconciliation.md" ]]
}

project_docs_exist() {
  docs_index_present "$1"
}

# Existing = already has a documentation index (previously bootstrapped or
# independently documented). New = no docs index yet.
project_bootstrap_mode() {
  if docs_index_present "$1"; then
    echo "existing"
  else
    echo "new"
  fi
}

boost_diagnosis() {
  local dir="$1"

  if ! project_is_laravel "${dir}"; then
    echo "not_applicable"
    return 0
  fi

  local declared=0 installed=0 configured=0 artisan=0
  boost_declared "${dir}" && declared=1
  boost_installed "${dir}" && installed=1
  boost_mcp_configured "${dir}" && configured=1
  boost_artisan_available "${dir}" && artisan=1

  if [[ "${declared}" -eq 1 && "${installed}" -eq 1 && "${configured}" -eq 1 ]]; then
    echo "ok"
    return 0
  fi

  if [[ "${declared}" -eq 0 ]]; then
    echo "missing_package"
    return 0
  fi

  if [[ "${installed}" -eq 0 ]]; then
    echo "declared_not_installed"
    return 0
  fi

  if [[ "${configured}" -eq 0 ]]; then
    echo "installed_not_configured"
    return 0
  fi

  echo "ok"
}

boost_next_steps() {
  local diagnosis="$1"

  case "${diagnosis}" in
    missing_package)
      cat <<'EOF'
Laravel Boost is required for Laravel web applications and is not declared.
Do not add Boost to user-global Cursor MCP (~/.cursor/mcp.json). Install it
with Laravel's native installer after approval:

  composer require laravel/boost --dev
  php artisan boost:install

Then enable the `laravel-boost` server in Cursor MCP settings.
EOF
      ;;
    declared_not_installed)
      cat <<'EOF'
laravel/boost is declared in composer.json but vendor/laravel/boost is missing.

  composer install

Then, if `.cursor/mcp.json` still has no `laravel-boost` server:

  php artisan boost:install --mcp

Enable `laravel-boost` in Cursor MCP settings.
EOF
      ;;
    installed_not_configured)
      cat <<'EOF'
laravel/boost is installed but Cursor MCP is not configured for this project.
Let Boost own the config (do not hand-write a competing MCP entry):

  php artisan boost:install --mcp

Then enable the `laravel-boost` server in Cursor MCP settings.
EOF
      ;;
    ok)
      echo "Laravel Boost is declared, installed, and MCP-configured. Enable it in Cursor MCP settings if it is toggled off."
      echo "If AGENTS.md is Boost-generated, run php artisan boost:update so it includes .ai/guidelines/ai-platform.md."
      ;;
    *)
      echo "Laravel Boost is not applicable to this project."
      ;;
  esac
}
