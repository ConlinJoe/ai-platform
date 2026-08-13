#!/usr/bin/env bash

# Fixture tests for AI Platform bootstrap and doctor.
# Does not modify application projects. Does not install Composer packages.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

export AI_BOOTSTRAP_SKIP_SKILLS=1

PASSES=0
FAILURES=0

pass() {
  echo "PASS  $1"
  PASSES=$((PASSES + 1))
}

fail() {
  echo "FAIL  $1"
  FAILURES=$((FAILURES + 1))
}

assert_file() {
  local path="$1"
  local label="$2"
  if [[ -f "${path}" ]]; then
    pass "${label}"
  else
    fail "${label} (missing ${path})"
  fi
}

assert_missing() {
  local path="$1"
  local label="$2"
  if [[ ! -e "${path}" ]]; then
    pass "${label}"
  else
    fail "${label} (unexpected ${path})"
  fi
}

assert_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -qE "${pattern}" "${file}"; then
    pass "${label}"
  else
    fail "${label}"
  fi
}

assert_not_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -qE "${pattern}" "${file}"; then
    fail "${label}"
  else
    pass "${label}"
  fi
}

write_laravel_composer() {
  local dir="$1"
  local with_boost="${2:-0}"
  if [[ "${with_boost}" == "1" ]]; then
    cat > "${dir}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.3",
    "laravel/framework": "^13.0"
  },
  "require-dev": {
    "laravel/boost": "^2.4"
  }
}
EOF
  else
    cat > "${dir}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.3",
    "laravel/framework": "^13.0"
  }
}
EOF
  fi
}

write_radicle_composer() {
  local dir="$1"
  cat > "${dir}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.2",
    "roots/acorn": "^5.0",
    "roots/radicle": "*"
  }
}
EOF
}

WORKDIR="${AI_REPO}/.build/platform-tests"
LOGDIR="${WORKDIR}/logs"
rm -rf "${WORKDIR}"
mkdir -p "${LOGDIR}"

echo "=== AI Platform tests ==="
echo "Fixtures: ${WORKDIR}"
echo ""

echo "--- Syntax ---"
for script in \
  "${AI_REPO}/scripts/bootstrap-project.sh" \
  "${AI_REPO}/scripts/doctor.sh" \
  "${AI_REPO}/scripts/link-rules.sh" \
  "${AI_REPO}/scripts/export-chatgpt-context.sh" \
  "${AI_REPO}/scripts/update-skills.sh" \
  "${AI_REPO}/scripts/lib/project-capabilities.sh" \
  "${AI_REPO}/scripts/test-platform.sh"
do
  if bash -n "${script}"; then
    pass "bash -n $(basename "${script}")"
  else
    fail "bash -n $(basename "${script}")"
  fi
done

echo ""
echo "--- Doctor (AI Platform repo) ---"
if "${AI_REPO}/scripts/doctor.sh" "${AI_REPO}" >"${LOGDIR}/doctor-platform.log" 2>&1; then
  pass "doctor on AI Platform exits 0"
else
  fail "doctor on AI Platform exits 0"
  cat "${LOGDIR}/doctor-platform.log"
fi
assert_grep "Playwright and Laravel Boost are not required" "${LOGDIR}/doctor-platform.log" \
  "doctor does not require Playwright/Boost of the platform repo"

echo ""
echo "--- Generic new project ---"
GENERIC="${WORKDIR}/generic"
mkdir -p "${GENERIC}"
printf 'hello\n' > "${GENERIC}/README.md"

"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" >${LOGDIR}/boot-generic.log 2>&1

assert_file "${GENERIC}/docs/README.md" "generic received docs templates"
assert_missing "${GENERIC}/docs/contracts/features/browser-qa.md" \
  "generic did not receive browser-QA template"
assert_not_grep 'playwright-report' "${GENERIC}/.gitignore" \
  "generic gitignore has no Playwright artifacts"
assert_grep "Playwright Mode A is not required" ${LOGDIR}/boot-generic.log \
  "bootstrap does not require Playwright for generic projects"
assert_grep "Laravel Boost is not required" ${LOGDIR}/boot-generic.log \
  "bootstrap does not require Boost for generic projects"
assert_grep "Detected profile: none" ${LOGDIR}/boot-generic.log \
  "bootstrap does not assign laravel-webapp or roots-radicle to generic projects"

if "${AI_REPO}/scripts/doctor.sh" "${GENERIC}" >${LOGDIR}/doctor-generic.log 2>&1; then
  pass "doctor on generic project exits 0"
else
  fail "doctor on generic project exits 0"
  cat ${LOGDIR}/doctor-generic.log
fi
assert_grep "Playwright Mode A not required" ${LOGDIR}/doctor-generic.log \
  "doctor does not force Playwright on generic projects"
assert_grep "Boost not applicable" ${LOGDIR}/doctor-generic.log \
  "doctor does not require Boost on generic projects"

echo ""
echo "--- New Roots/Radicle project ---"
RADICLE_NEW="${WORKDIR}/radicle-new"
mkdir -p "${RADICLE_NEW}"
write_radicle_composer "${RADICLE_NEW}"

"${AI_REPO}/scripts/bootstrap-project.sh" "${RADICLE_NEW}" >${LOGDIR}/boot-radicle-new.log 2>&1

assert_file "${RADICLE_NEW}/docs/README.md" "Radicle project received docs templates"
assert_missing "${RADICLE_NEW}/docs/contracts/features/browser-qa.md" \
  "Radicle project did not receive browser-QA template"
assert_not_grep 'playwright-report' "${RADICLE_NEW}/.gitignore" \
  "Radicle gitignore has no Playwright artifacts"
assert_grep "Detected profile: roots-radicle" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap detects roots-radicle profile"
assert_not_grep "Detected profile: laravel-webapp" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not treat Radicle as laravel-webapp"
assert_grep "Playwright Mode A is not required" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not require Playwright for Radicle"
assert_grep "Laravel Boost is not required" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not require Boost for Radicle"

if "${AI_REPO}/scripts/doctor.sh" "${RADICLE_NEW}" >${LOGDIR}/doctor-radicle-new.log 2>&1; then
  pass "doctor on Radicle project exits 0"
else
  fail "doctor on Radicle project exits 0"
  cat ${LOGDIR}/doctor-radicle-new.log
fi
assert_grep "Playwright Mode A not required" ${LOGDIR}/doctor-radicle-new.log \
  "doctor does not force Playwright on Radicle projects"
assert_grep "Boost not applicable" ${LOGDIR}/doctor-radicle-new.log \
  "doctor does not require Boost on Radicle projects"

echo ""
echo "--- Bedrock WordPress without Sage/Acorn ---"
BEDROCK="${WORKDIR}/bedrock-only"
mkdir -p "${BEDROCK}"
cat > "${BEDROCK}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.2",
    "roots/wordpress": "^6.8"
  }
}
EOF

"${AI_REPO}/scripts/bootstrap-project.sh" "${BEDROCK}" >${LOGDIR}/boot-bedrock.log 2>&1
assert_grep "Detected profile: none" ${LOGDIR}/boot-bedrock.log \
  "Bedrock without Sage/Acorn is not roots-radicle"
assert_not_grep "Detected profile: roots-radicle" ${LOGDIR}/boot-bedrock.log \
  "Navi/Radicle profile is not imposed on plain Roots WordPress"

echo ""
echo "--- New Laravel project without Boost ---"
LARAVEL_NEW="${WORKDIR}/laravel-new"
mkdir -p "${LARAVEL_NEW}"
write_laravel_composer "${LARAVEL_NEW}" 0

"${AI_REPO}/scripts/bootstrap-project.sh" "${LARAVEL_NEW}" >${LOGDIR}/boot-laravel-new.log 2>&1

assert_file "${LARAVEL_NEW}/docs/contracts/features/browser-qa.md" \
  "new Laravel project received browser-QA draft"
assert_grep 'playwright-report' "${LARAVEL_NEW}/.gitignore" \
  "new Laravel gitignore includes Playwright artifacts"
assert_grep "Detected profile: laravel-webapp" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap detects laravel-webapp profile"
assert_not_grep "Detected profile: roots-radicle" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap does not treat Laravel as roots-radicle"
assert_grep "missing_package" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap diagnoses missing Boost package"
assert_grep "composer require laravel/boost --dev" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap prints native Boost install steps"
assert_grep "Do not add Boost to user-global" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap warns against user-global Boost MCP"

if "${AI_REPO}/scripts/doctor.sh" "${LARAVEL_NEW}" >${LOGDIR}/doctor-laravel-new.log 2>&1; then
  fail "doctor fails Laravel project with missing Boost"
else
  pass "doctor fails Laravel project with missing Boost"
fi
assert_grep "laravel/boost missing from composer.json" ${LOGDIR}/doctor-laravel-new.log \
  "doctor names missing Boost package"
assert_grep "Playwright Mode A expected" ${LOGDIR}/doctor-laravel-new.log \
  "doctor expects Playwright for Laravel web apps"
assert_grep "Playwright Mode A not present yet" ${LOGDIR}/doctor-laravel-new.log \
  "missing Playwright is a warning, not a silent skip"

echo ""
echo "--- Laravel with Boost declared, installed, and MCP-configured ---"
LARAVEL_OK="${WORKDIR}/laravel-ok"
mkdir -p "${LARAVEL_OK}/vendor/laravel/boost" "${LARAVEL_OK}/.cursor"
write_laravel_composer "${LARAVEL_OK}" 1
touch "${LARAVEL_OK}/artisan"
cat > "${LARAVEL_OK}/.cursor/mcp.json" <<'EOF'
{
  "mcpServers": {
    "laravel-boost": {
      "command": "php",
      "args": ["artisan", "boost:mcp"]
    }
  }
}
EOF

"${AI_REPO}/scripts/bootstrap-project.sh" "${LARAVEL_OK}" >${LOGDIR}/boot-laravel-ok.log 2>&1
assert_grep "Laravel Boost: ok" ${LOGDIR}/boot-laravel-ok.log \
  "bootstrap reports Boost ok when native setup is present"
assert_file "${LARAVEL_OK}/.cursor/mcp.json" "bootstrap did not remove Boost MCP config"
assert_grep "laravel-boost" "${LARAVEL_OK}/.cursor/mcp.json" \
  "bootstrap did not rewrite Boost MCP config"

if "${AI_REPO}/scripts/doctor.sh" "${LARAVEL_OK}" >${LOGDIR}/doctor-laravel-ok.log 2>&1; then
  pass "doctor passes Laravel project with working Boost setup"
else
  fail "doctor passes Laravel project with working Boost setup"
  cat ${LOGDIR}/doctor-laravel-ok.log
fi
assert_grep "Boost MCP configured" ${LOGDIR}/doctor-laravel-ok.log \
  "doctor reports Boost MCP configured"

echo ""
echo "--- Existing Laravel project (docs already present) ---"
LARAVEL_EXISTING="${WORKDIR}/laravel-existing"
mkdir -p "${LARAVEL_EXISTING}/docs/contracts/foundational"
write_laravel_composer "${LARAVEL_EXISTING}" 0
cat > "${LARAVEL_EXISTING}/docs/README.md" <<'EOF'
# Existing docs
UNIQUE_EXISTING_MARKER
EOF
printf 'do not overwrite\n' > "${LARAVEL_EXISTING}/docs/00-project-context.md"

"${AI_REPO}/scripts/bootstrap-project.sh" "${LARAVEL_EXISTING}" >${LOGDIR}/boot-existing.log 2>&1

assert_grep "UNIQUE_EXISTING_MARKER" "${LARAVEL_EXISTING}/docs/README.md" \
  "existing docs/README.md was not overwritten"
assert_grep "do not overwrite" "${LARAVEL_EXISTING}/docs/00-project-context.md" \
  "existing project context was not overwritten"
assert_file "${LARAVEL_EXISTING}/docs/contracts/features/browser-qa.md" \
  "existing Laravel project received missing browser-QA draft"
assert_file "${LARAVEL_EXISTING}/docs/contracts/foundational/platform-reconciliation.md" \
  "existing Laravel project received reconciliation draft"
assert_grep "Existing project" ${LOGDIR}/boot-existing.log \
  "bootstrap detected existing-project mode"
assert_grep "core/prompts/existing-project-bootstrap.md" ${LOGDIR}/boot-existing.log \
  "bootstrap points at existing-project prompt"

echo ""
echo "--- Idempotent re-run (generic) ---"
"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" >${LOGDIR}/boot-generic-2.log 2>&1
build_count="$(grep -cE '^\.build/?$' "${GENERIC}/.gitignore" || true)"
if [[ "${build_count}" -eq 1 ]]; then
  pass "re-run does not duplicate .build/ gitignore"
else
  fail "re-run does not duplicate .build/ gitignore (count=${build_count})"
fi

echo ""
echo "--- Summary ---"
echo "Passed: ${PASSES}"
echo "Failed: ${FAILURES}"
echo "Workdir: ${WORKDIR}"

if [[ "${FAILURES}" -gt 0 ]]; then
  exit 1
fi

exit 0
