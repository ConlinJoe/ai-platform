#!/usr/bin/env bash

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "${SCRIPT_PATH}" ]]; then
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
fi
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/project-capabilities.sh
source "${SCRIPT_DIR}/lib/project-capabilities.sh"

RULES_DIR="${AI_REPO}/.cursor/rules"
SKILLS_LOCK="${AI_REPO}/skills-lock.json"

FAILS=0
WARNS=0

ok() {
  echo "OK    $1"
}

fail() {
  echo "FAIL  $1"
  FAILS=$((FAILS + 1))
}

warn() {
  echo "WARN  $1"
  WARNS=$((WARNS + 1))
}

resolve_target() {
  if [[ $# -ge 1 && -n "${1:-}" ]]; then
    if [[ ! -d "$1" ]]; then
      echo "Error: Target path does not exist or is not a directory: $1" >&2
      exit 1
    fi
    cd "$1" && pwd
    return
  fi

  if [[ "${PWD}" != "${AI_REPO}" ]]; then
    pwd
    return
  fi

  echo "${AI_REPO}"
}

check_file() {
  local path="$1"
  local label="$2"
  if [[ -f "${path}" ]]; then
    ok "${label}"
  else
    fail "${label} missing: ${path}"
  fi
}

check_executable() {
  local path="$1"
  local label="$2"
  if [[ -x "${path}" ]]; then
    ok "${label}"
  else
    fail "${label} not executable: ${path}"
  fi
}

check_bash_syntax() {
  local path="$1"
  local name
  name="$(basename "${path}")"
  if bash -n "${path}"; then
    ok "bash -n ${name}"
  else
    fail "bash -n ${name} failed"
  fi
}

check_platform() {
  echo "--- AI Platform (${AI_REPO}) ---"
  echo ""

  check_file "${RULES_DIR}/00-platform.mdc" "Rule 00-platform.mdc"
  check_file "${RULES_DIR}/30-laravel.mdc" "Rule 30-laravel.mdc"
  check_file "${RULES_DIR}/35-roots.mdc" "Rule 35-roots.mdc"
  check_file "${RULES_DIR}/50-workflows.mdc" "Rule 50-workflows.mdc"
  check_file "${RULES_DIR}/60-browser-qa.mdc" "Rule 60-browser-qa.mdc"
  check_file "${SKILLS_LOCK}" "skills-lock.json"
  check_file "${AI_REPO}/core/project-profiles/laravel-webapp.md" "Laravel webapp profile"
  check_file "${AI_REPO}/core/project-profiles/roots-radicle.md" "Roots/Radicle/Sage profile"
  check_file "${AI_REPO}/docs/contracts/features/browser-qa.md" "Browser QA contract"
  check_file "${AI_REPO}/docs/contracts/features/laravel-boost.md" "Laravel Boost contract"
  check_file "${AI_REPO}/mcp/README.md" "MCP guidance index"
  check_file "${AI_REPO}/mcp/laravel-boost/README.md" "Boost MCP guidance"
  check_file "${AI_REPO}/mcp/playwright/README.md" "Playwright MCP guidance"
  check_file "${AI_REPO}/core/prompts/browser-qa-loop.md" "Browser QA loop prompt"
  check_file "${AI_REPO}/core/prompts/project-adoption.md" "Project adoption prompt"
  check_file "${AI_REPO}/LICENSE" "MIT LICENSE"
  check_file "${AI_REPO}/core/prompts/existing-project-bootstrap.md" "Existing-project bootstrap alias"
  check_file "${AI_REPO}/core/agent-core.md" "Canonical agent-core"
  check_file "${AI_REPO}/core/adapters/README.md" "Agent adapter index"
  check_file "${AI_REPO}/core/adapters/hermes.md" "Hermes adapter"
  check_file "${AI_REPO}/AGENTS.md" "AGENTS.md entrypoint"
  check_file "${AI_REPO}/CLAUDE.md" "CLAUDE.md entrypoint"

  if [[ -e "${AI_REPO}/.hermes.md" || -e "${AI_REPO}/HERMES.md" ]]; then
    fail "Platform must not ship .hermes.md / HERMES.md (would override AGENTS.md in Hermes)"
  else
    ok "No .hermes.md (Hermes uses AGENTS.md)"
  fi
  check_file "${AI_REPO}/templates/docs/99-project-status.md" "Status template"
  check_file "${AI_REPO}/templates/docs/contracts/features/browser-qa.md" "Browser QA project template"
  check_file "${AI_REPO}/templates/existing-project/platform-reconciliation.md" "Reconciliation template"

  local script
  for script in \
    "${AI_REPO}/scripts/bootstrap-project.sh" \
    "${AI_REPO}/scripts/doctor.sh" \
    "${AI_REPO}/scripts/link-rules.sh" \
    "${AI_REPO}/scripts/export-chatgpt-context.sh" \
    "${AI_REPO}/scripts/update-skills.sh" \
    "${AI_REPO}/scripts/lib/project-capabilities.sh"
  do
    check_file "${script}" "Script $(basename "${script}")"
    if [[ -f "${script}" ]]; then
      check_executable "${script}" "Script $(basename "${script}") executable"
      check_bash_syntax "${script}"
    fi
  done

  if [[ ! -s "${AI_REPO}/scripts/doctor.sh" ]]; then
    fail "doctor.sh is empty"
  fi

  echo ""
}

check_project_links() {
  local target="$1"
  local target_rules="${target}/.cursor/rules"
  local failures=0
  local rule

  echo "--- Project links (${target}) ---"
  echo ""

  for rule in "${RULES_DIR}"/*.mdc; do
    [[ -f "${rule}" ]] || continue
    local name
    name="$(basename "${rule}")"
    local link_path="${target_rules}/${name}"

    if [[ ! -L "${link_path}" ]]; then
      fail "Rule not linked: ${link_path}"
      failures=$((failures + 1))
      continue
    fi

    local current_target
    current_target="$(readlink "${link_path}")"
    if [[ "${current_target}" != "${rule}" ]]; then
      fail "Rule link target mismatch: ${name}"
      failures=$((failures + 1))
      continue
    fi

    ok "Rule: ${name}"
  done

  local export_link="${target}/scripts/export-chatgpt-context.sh"
  if [[ -L "${export_link}" ]] && [[ "$(readlink "${export_link}")" == "${AI_REPO}/scripts/export-chatgpt-context.sh" ]]; then
    ok "Export script linked"
  else
    warn "Export script not linked to AI Platform"
  fi

  local doctor_link="${target}/scripts/doctor.sh"
  if [[ -L "${doctor_link}" ]] && [[ "$(readlink "${doctor_link}")" == "${AI_REPO}/scripts/doctor.sh" ]]; then
    ok "Doctor script linked"
  else
    warn "Doctor script not linked to AI Platform"
  fi

  if [[ -e "${target}/AGENTS.md" || -L "${target}/AGENTS.md" ]]; then
    ok "AGENTS.md present"
  else
    warn "AGENTS.md missing"
  fi

  if [[ -e "${target}/CLAUDE.md" || -L "${target}/CLAUDE.md" ]]; then
    ok "CLAUDE.md present"
  else
    warn "CLAUDE.md missing"
  fi

  echo ""
  return 0
}

check_laravel_boost() {
  local target="$1"
  local diagnosis
  diagnosis="$(boost_diagnosis "${target}")"

  echo "--- Laravel Boost ---"
  echo ""

  case "${diagnosis}" in
    not_applicable)
      ok "Boost not applicable (not a Laravel project)"
      ;;
    ok)
      ok "Boost declared in composer.json"
      ok "Boost installed at vendor/laravel/boost"
      ok "Boost MCP configured (laravel-boost)"
      if boost_artisan_available "${target}"; then
        ok "Boost artisan command discoverable (vendor + artisan present)"
      else
        warn "artisan missing; cannot confirm boost:mcp"
      fi
      echo ""
      echo "Note: Cursor must have the laravel-boost MCP server enabled."
      echo "      That toggle is not detectable from the filesystem."
      ;;
    missing_package)
      fail "Boost package not declared (laravel/boost missing from composer.json)"
      echo ""
      boost_next_steps "${diagnosis}"
      ;;
    declared_not_installed)
      ok "Boost declared in composer.json"
      fail "Boost not installed (vendor/laravel/boost missing)"
      echo ""
      boost_next_steps "${diagnosis}"
      ;;
    installed_not_configured)
      ok "Boost declared in composer.json"
      ok "Boost installed at vendor/laravel/boost"
      fail "Boost MCP not configured (.cursor/mcp.json has no laravel-boost)"
      echo ""
      boost_next_steps "${diagnosis}"
      ;;
    *)
      fail "Boost diagnosis unknown: ${diagnosis}"
      ;;
  esac

  echo ""
}

check_browser_qa() {
  local target="$1"

  echo "--- Browser QA ---"
  echo ""

  if playwright_expected "${target}"; then
    ok "Playwright Mode A expected (Laravel web application profile)"

    if playwright_present "${target}"; then
      ok "Playwright present"
      if playwright_artifacts_gitignored "${target}"; then
        ok "Playwright artifacts gitignored"
      else
        fail "Playwright artifacts not fully gitignored (need playwright-report/ and test-results/)"
      fi
    else
      warn "Playwright Mode A not present yet (expected for this profile; do not install without approval)"
    fi

    if browser_qa_contract_present "${target}"; then
      ok "Project browser-QA contract present"
    else
      warn "Project browser-QA contract missing (docs/contracts/features/browser-qa.md)"
    fi
  else
    ok "Playwright Mode A not required for this project type"
    if playwright_present "${target}"; then
      ok "Playwright is present (optional; not forced by platform)"
    fi
  fi

  echo ""
}

check_docs() {
  local target="$1"
  local mode
  mode="$(project_bootstrap_mode "${target}")"

  echo "--- Documentation (${mode} project) ---"
  echo ""

  if docs_index_present "${target}"; then
    ok "docs/README.md present"
  else
    warn "docs/README.md missing (run bootstrap or add documentation contracts)"
  fi

  if [[ -f "${target}/docs/00-project-context.md" ]]; then
    ok "docs/00-project-context.md present"
  else
    warn "docs/00-project-context.md missing"
  fi

  if [[ -f "${target}/docs/99-project-status.md" ]]; then
    ok "docs/99-project-status.md present"
  else
    warn "docs/99-project-status.md missing"
  fi

  if [[ "${mode}" == "existing" ]]; then
    if reconciliation_contract_present "${target}"; then
      ok "Platform reconciliation contract present"
    else
      warn "Existing project has no platform-reconciliation contract"
    fi
  fi

  echo ""
}

TARGET="$(resolve_target "${1:-}")"

echo ""
echo "=== AI Platform Doctor ==="
echo "AI platform: ${AI_REPO}"
echo "Target: ${TARGET}"
echo ""

check_platform

if [[ "${TARGET}" != "${AI_REPO}" ]]; then
  check_project_links "${TARGET}"
  check_docs "${TARGET}"
  check_laravel_boost "${TARGET}"
  check_browser_qa "${TARGET}"
else
  echo "Target is the AI Platform repository. Skipping project-profile checks."
  echo "Playwright and Laravel Boost are not required here."
  echo ""
fi

echo "--- Summary ---"
echo "Failures: ${FAILS}"
echo "Warnings: ${WARNS}"
echo ""

if [[ "${FAILS}" -gt 0 ]]; then
  echo "Doctor found failures that need attention." >&2
  exit 1
fi

echo "Doctor passed."
exit 0
