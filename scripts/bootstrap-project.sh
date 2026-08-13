#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_DIR="${AI_REPO}/.cursor/rules"
SKILLS_LOCK="${AI_REPO}/skills-lock.json"

# shellcheck source=lib/project-capabilities.sh
source "${SCRIPT_DIR}/lib/project-capabilities.sh"

REQUIRED_SKILLS=()
MISSING_SKILLS=()
PRESENT_SKILLS=()

if [[ ! -d "${RULES_DIR}" ]] || [[ ! -f "${RULES_DIR}/00-platform.mdc" ]]; then
  echo "Error: AI Platform rules not found." >&2
  echo "Expected rules at: ${RULES_DIR}" >&2
  echo "This script must live inside the AI Platform repository." >&2
  exit 1
fi

# Target resolution priority:
# 1. Explicit path argument
# 2. Current working directory when invoked outside the AI Platform repo
# 3. Interactive prompt (fallback)
TARGET_INPUT=""
if [[ $# -ge 1 && -n "${1:-}" ]]; then
  TARGET_INPUT="$1"
elif [[ "${PWD}" != "${AI_REPO}" ]]; then
  TARGET_INPUT="${PWD}"
  echo "No target path supplied; using current directory: ${TARGET_INPUT}"
else
  read -r -p "Enter target project path: " TARGET_INPUT
  if [[ -z "${TARGET_INPUT}" ]]; then
    echo "Error: Target project path is required." >&2
    exit 1
  fi
fi

if [[ ! -d "${TARGET_INPUT}" ]]; then
  echo "Error: Target path does not exist or is not a directory: ${TARGET_INPUT}" >&2
  exit 1
fi

TARGET_PROJECT="$(cd "${TARGET_INPUT}" && pwd)"

if [[ "${TARGET_PROJECT}" == "${AI_REPO}" ]]; then
  echo "Error: Refusing to bootstrap the AI Platform repository itself." >&2
  echo "Bootstrap installs platform infrastructure into other projects." >&2
  echo "Run from a project root, or pass another project path." >&2
  exit 1
fi

TARGET_RULES_DIR="${TARGET_PROJECT}/.cursor/rules"
TARGET_SKILLS_DIR="${TARGET_PROJECT}/.agents/skills"
TARGET_SKILLS_LOCK="${TARGET_PROJECT}/skills-lock.json"
TARGET_SCRIPTS_DIR="${TARGET_PROJECT}/scripts"
EXPORT_SCRIPT="${AI_REPO}/scripts/export-chatgpt-context.sh"
DOCTOR_SCRIPT="${AI_REPO}/scripts/doctor.sh"
DOCS_TEMPLATES_DIR="${AI_REPO}/templates/docs"
BROWSER_QA_TEMPLATE="${AI_REPO}/templates/docs/contracts/features/browser-qa.md"
RECONCILIATION_TEMPLATE="${AI_REPO}/templates/existing-project/platform-reconciliation.md"
BOOTSTRAP_MODE=""

echo ""
echo "=== AI Platform Bootstrap ==="
echo "AI platform: ${AI_REPO}"
echo "Target project: ${TARGET_PROJECT}"
echo ""

# ---------------------------------------------------------------------------
# Link shared Cursor Project Rules
# ---------------------------------------------------------------------------

link_rules() {
  echo "--- Linking Cursor Project Rules ---"

  mkdir -p "${TARGET_RULES_DIR}"

  local linked=0
  local updated=0
  local skipped=0

  for rule in "${RULES_DIR}"/*.mdc; do
    [[ -f "${rule}" ]] || continue

    local name
    name="$(basename "${rule}")"
    local link_path="${TARGET_RULES_DIR}/${name}"

    if [[ -L "${link_path}" ]]; then
      local current_target
      current_target="$(readlink "${link_path}")"
      if [[ "${current_target}" != "${rule}" ]]; then
        ln -sf "${rule}" "${link_path}"
        echo "Updated link: ${link_path} -> ${rule}"
        updated=$((updated + 1))
      else
        echo "Already linked: ${link_path}"
      fi
    elif [[ -e "${link_path}" ]]; then
      read -r -p "Real file exists at ${link_path}. Replace with symlink? [y/N] " confirm
      if [[ "${confirm}" =~ ^[Yy]$ ]]; then
        rm "${link_path}"
        ln -s "${rule}" "${link_path}"
        echo "Replaced with link: ${link_path} -> ${rule}"
        updated=$((updated + 1))
      else
        echo "Skipped: ${link_path}"
        skipped=$((skipped + 1))
      fi
    else
      ln -s "${rule}" "${link_path}"
      echo "Linked: ${link_path} -> ${rule}"
      linked=$((linked + 1))
    fi
  done

  echo ""
  echo "Rules: linked ${linked}, updated ${updated}, skipped ${skipped}"
}

# ---------------------------------------------------------------------------
# Link ChatGPT context export script
# ---------------------------------------------------------------------------

link_export_script() {
  echo ""
  echo "--- Linking ChatGPT Context Export Script ---"

  if [[ ! -f "${EXPORT_SCRIPT}" ]]; then
    echo "Error: Export script not found at ${EXPORT_SCRIPT}" >&2
    return 1
  fi

  link_platform_script "${EXPORT_SCRIPT}" "export-chatgpt-context.sh"
}

link_platform_script() {
  local source_script="$1"
  local name="$2"
  local link_path="${TARGET_SCRIPTS_DIR}/${name}"

  if [[ ! -f "${source_script}" ]]; then
    echo "Error: Script not found at ${source_script}" >&2
    return 1
  fi

  mkdir -p "${TARGET_SCRIPTS_DIR}"

  if [[ -L "${link_path}" ]]; then
    local current_target
    current_target="$(readlink "${link_path}")"
    if [[ "${current_target}" != "${source_script}" ]]; then
      ln -sf "${source_script}" "${link_path}"
      echo "Updated link: ${link_path} -> ${source_script}"
    else
      echo "Already linked: ${link_path}"
    fi
  elif [[ -e "${link_path}" ]]; then
    read -r -p "Real file exists at ${link_path}. Replace with symlink? [y/N] " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
      rm "${link_path}"
      ln -s "${source_script}" "${link_path}"
      echo "Replaced with link: ${link_path} -> ${source_script}"
    else
      echo "Skipped: ${link_path}"
    fi
  else
    ln -s "${source_script}" "${link_path}"
    echo "Linked: ${link_path} -> ${source_script}"
  fi

  chmod +x "${source_script}"
}

link_doctor_script() {
  echo ""
  echo "--- Linking Doctor Script ---"
  link_platform_script "${DOCTOR_SCRIPT}" "doctor.sh"
}

# ---------------------------------------------------------------------------
# Bootstrap documentation contract templates
# ---------------------------------------------------------------------------

bootstrap_docs_templates() {
  echo ""
  echo "--- Bootstrapping Documentation Contracts ---"

  if [[ ! -d "${DOCS_TEMPLATES_DIR}" ]]; then
    echo "Warning: Documentation templates not found at ${DOCS_TEMPLATES_DIR}" >&2
    return 0
  fi

  local target_docs="${TARGET_PROJECT}/docs"
  BOOTSTRAP_MODE="$(project_bootstrap_mode "${TARGET_PROJECT}")"

  if [[ "${BOOTSTRAP_MODE}" == "existing" ]]; then
    echo "Existing project: documentation index already present."
    echo "Not overwriting project docs. Reconciling missing drafts only."
    add_missing_profile_templates
    return 0
  fi

  mkdir -p "${target_docs}"
  cp -R "${DOCS_TEMPLATES_DIR}/." "${target_docs}/"
  echo "Copied documentation templates to ${target_docs}/"

  if project_is_laravel_webapp "${TARGET_PROJECT}"; then
    echo "Laravel web application: keeping draft browser-QA contract."
    echo "Register docs/contracts/features/browser-qa.md in docs/README.md."
  else
    rm -f "${target_docs}/contracts/features/browser-qa.md"
    echo "Non-browser-capable profile: omitted Playwright browser-QA template."
  fi

  echo "Templates are placeholders — establish project-specific contracts next."
}

copy_if_missing() {
  local source="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -f "${source}" ]]; then
    echo "Warning: template missing: ${source}" >&2
    return 0
  fi

  if [[ -e "${dest}" ]]; then
    echo "Already present: ${dest}"
    return 0
  fi

  mkdir -p "$(dirname "${dest}")"
  cp "${source}" "${dest}"
  echo "Added draft ${label}: ${dest}"
  echo "Fill from this project's reality. Do not treat the draft as approval."
}

add_missing_profile_templates() {
  local target_docs="${TARGET_PROJECT}/docs"

  copy_if_missing \
    "${AI_REPO}/templates/docs/99-project-status.md" \
    "${target_docs}/99-project-status.md" \
    "project status"

  if project_is_laravel_webapp "${TARGET_PROJECT}"; then
    copy_if_missing \
      "${BROWSER_QA_TEMPLATE}" \
      "${target_docs}/contracts/features/browser-qa.md" \
      "browser QA contract"

    copy_if_missing \
      "${RECONCILIATION_TEMPLATE}" \
      "${target_docs}/contracts/foundational/platform-reconciliation.md" \
      "platform reconciliation"
  fi
}

ensure_gitignore_build() {
  local gitignore="${TARGET_PROJECT}/.gitignore"

  if [[ ! -f "${gitignore}" ]]; then
    printf '\n# ChatGPT context export output\n.build/\n' >> "${gitignore}"
    echo "Created ${gitignore} with .build/ entry"
    return 0
  fi

  if grep -qE '^\.build/?$' "${gitignore}" || grep -qE '^\.build/' "${gitignore}"; then
    echo ".build/ already listed in .gitignore"
    return 0
  fi

  printf '\n# ChatGPT context export output\n.build/\n' >> "${gitignore}"
  echo "Added .build/ to ${gitignore}"
}

ensure_playwright_gitignore() {
  if ! project_is_laravel_webapp "${TARGET_PROJECT}"; then
    return 0
  fi

  echo ""
  echo "--- Playwright artifact gitignore (Laravel web app) ---"

  local gitignore="${TARGET_PROJECT}/.gitignore"
  if [[ ! -f "${gitignore}" ]]; then
    touch "${gitignore}"
  fi

  local added=0
  if ! grep -qE '(^|/)playwright-report/?$' "${gitignore}"; then
    printf '\n# Playwright (Mode A browser QA)\n/playwright-report/\n' >> "${gitignore}"
    added=1
  fi
  if ! grep -qE '(^|/)test-results/?$' "${gitignore}"; then
    if [[ "${added}" -eq 0 ]]; then
      printf '\n# Playwright (Mode A browser QA)\n' >> "${gitignore}"
    fi
    printf '/test-results/\n' >> "${gitignore}"
    added=1
  fi
  if ! grep -qE '(^|/)blob-report/?$' "${gitignore}"; then
    printf '/blob-report/\n' >> "${gitignore}"
    added=1
  fi
  if ! grep -qE 'playwright/\.cache' "${gitignore}"; then
    printf '/playwright/.cache/\n' >> "${gitignore}"
    added=1
  fi

  if [[ "${added}" -eq 1 ]]; then
    echo "Ensured Playwright artifact paths in ${gitignore}"
  else
    echo "Playwright artifact paths already listed in .gitignore"
  fi
}

# ---------------------------------------------------------------------------
# Project skills (installed into the target project)
# ---------------------------------------------------------------------------

link_skills_lock() {
  if [[ ! -f "${SKILLS_LOCK}" ]]; then
    echo "Error: skills-lock.json not found at ${SKILLS_LOCK}" >&2
    return 1
  fi

  if [[ -L "${TARGET_SKILLS_LOCK}" ]]; then
    local current_target
    current_target="$(readlink "${TARGET_SKILLS_LOCK}")"
    if [[ "${current_target}" != "${SKILLS_LOCK}" ]]; then
      ln -sf "${SKILLS_LOCK}" "${TARGET_SKILLS_LOCK}"
      echo "Updated link: ${TARGET_SKILLS_LOCK} -> ${SKILLS_LOCK}"
    else
      echo "Already linked: ${TARGET_SKILLS_LOCK}"
    fi
  elif [[ -e "${TARGET_SKILLS_LOCK}" ]]; then
    read -r -p "Real file exists at ${TARGET_SKILLS_LOCK}. Replace with symlink? [y/N] " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
      rm "${TARGET_SKILLS_LOCK}"
      ln -s "${SKILLS_LOCK}" "${TARGET_SKILLS_LOCK}"
      echo "Replaced with link: ${TARGET_SKILLS_LOCK} -> ${SKILLS_LOCK}"
    else
      echo "Skipped: ${TARGET_SKILLS_LOCK}"
    fi
  else
    ln -s "${SKILLS_LOCK}" "${TARGET_SKILLS_LOCK}"
    echo "Linked: ${TARGET_SKILLS_LOCK} -> ${SKILLS_LOCK}"
  fi
}

get_locked_skills() {
  if [[ ! -f "${SKILLS_LOCK}" ]]; then
    echo "Error: skills-lock.json not found at ${SKILLS_LOCK}" >&2
    return 1
  fi

  python3 - "${SKILLS_LOCK}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

for name in sorted(data.get("skills", {})):
    print(name)
PY
}

skill_is_installed() {
  local skill_name="$1"
  [[ -f "${TARGET_SKILLS_DIR}/${skill_name}/SKILL.md" ]]
}

skill_dir_exists() {
  local skill_name="$1"
  [[ -d "${TARGET_SKILLS_DIR}/${skill_name}" ]]
}

has_existing_skill_dirs() {
  local skill
  for skill in "${REQUIRED_SKILLS[@]}"; do
    if skill_dir_exists "${skill}"; then
      return 0
    fi
  done
  return 1
}

detect_skills() {
  REQUIRED_SKILLS=()
  MISSING_SKILLS=()
  PRESENT_SKILLS=()

  local skill
  while IFS= read -r skill; do
    [[ -n "${skill}" ]] || continue
    REQUIRED_SKILLS+=("${skill}")

    if skill_is_installed "${skill}"; then
      PRESENT_SKILLS+=("${skill}")
    else
      MISSING_SKILLS+=("${skill}")
    fi
  done < <(get_locked_skills)

  if [[ ${#REQUIRED_SKILLS[@]} -eq 0 ]]; then
    echo "Error: No skills defined in ${SKILLS_LOCK}" >&2
    return 1
  fi
}

restore_skills() {
  echo ""
  echo "--- Restoring Project Skills ---"

  if [[ "${AI_BOOTSTRAP_SKIP_SKILLS:-}" == "1" ]]; then
    echo "Skipping skill restore (AI_BOOTSTRAP_SKIP_SKILLS=1)."
    return 0
  fi

  link_skills_lock

  detect_skills

  echo "Required skills (${#REQUIRED_SKILLS[@]}): ${REQUIRED_SKILLS[*]}"

  if [[ ${#MISSING_SKILLS[@]} -eq 0 ]]; then
    echo "All project skills are already installed."
    return 0
  fi

  echo "Missing skills (${#MISSING_SKILLS[@]}): ${MISSING_SKILLS[*]}"

  if [[ ${#PRESENT_SKILLS[@]} -gt 0 ]] || has_existing_skill_dirs; then
    if [[ ${#PRESENT_SKILLS[@]} -gt 0 ]]; then
      echo "Existing skills (${#PRESENT_SKILLS[@]}): ${PRESENT_SKILLS[*]}"
    else
      echo "Existing skill directories detected under ${TARGET_SKILLS_DIR}"
    fi
    read -r -p "Restore missing skills? This may overwrite existing project skills. [y/N] " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
      echo "Skipped skill restore."
      return 0
    fi
  fi

  # Skill install may rewrite skills-lock.json. Because the target lock is a
  # symlink into the AI Platform, snapshot and restore the platform file so
  # project bootstrap cannot mutate platform skill pins.
  local lock_snapshot
  lock_snapshot="$(mktemp)"
  cp "${SKILLS_LOCK}" "${lock_snapshot}"

  echo "Running: npx skills experimental_install"
  local install_status=0
  (
    cd "${TARGET_PROJECT}"
    npx skills experimental_install
  ) || install_status=$?

  if ! cmp -s "${SKILLS_LOCK}" "${lock_snapshot}"; then
    echo "Warning: Skill install modified AI Platform skills-lock.json via symlink; restoring original." >&2
    cp "${lock_snapshot}" "${SKILLS_LOCK}"
  fi
  rm -f "${lock_snapshot}"

  return "${install_status}"
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

verify_rules() {
  local failures=0
  local rule

  for rule in "${RULES_DIR}"/*.mdc; do
    [[ -f "${rule}" ]] || continue

    local name
    name="$(basename "${rule}")"
    local link_path="${TARGET_RULES_DIR}/${name}"

    if [[ ! -L "${link_path}" ]]; then
      echo "FAIL  Rule not linked: ${link_path}"
      failures=$((failures + 1))
      continue
    fi

    local current_target
    current_target="$(readlink "${link_path}")"
    if [[ "${current_target}" != "${rule}" ]]; then
      echo "FAIL  Rule link target mismatch: ${link_path} -> ${current_target}"
      failures=$((failures + 1))
      continue
    fi

    if [[ ! -f "${link_path}" ]]; then
      echo "FAIL  Broken rule symlink: ${link_path}"
      failures=$((failures + 1))
      continue
    fi

    echo "OK    Rule: ${name}"
  done

  return "${failures}"
}

verify_skills() {
  local failures=0
  local skill

  if [[ "${AI_BOOTSTRAP_SKIP_SKILLS:-}" == "1" ]]; then
    echo "SKIP  Skill verification (AI_BOOTSTRAP_SKIP_SKILLS=1)"
    return 0
  fi

  if [[ ! -d "${TARGET_SKILLS_DIR}" ]]; then
    echo "FAIL  Target skills directory missing: ${TARGET_SKILLS_DIR}"
    return 1
  fi

  echo "OK    Target skills directory: ${TARGET_SKILLS_DIR}"

  if [[ ! -f "${TARGET_SKILLS_LOCK}" ]]; then
    echo "FAIL  Target skills-lock.json missing: ${TARGET_SKILLS_LOCK}"
    failures=$((failures + 1))
  elif [[ ! -L "${TARGET_SKILLS_LOCK}" ]] || [[ "$(readlink "${TARGET_SKILLS_LOCK}")" != "${SKILLS_LOCK}" ]]; then
    echo "FAIL  Target skills-lock.json is not linked to AI Platform"
    failures=$((failures + 1))
  else
    echo "OK    skills-lock.json linked to AI Platform"
  fi

  while IFS= read -r skill; do
    [[ -n "${skill}" ]] || continue

    if skill_is_installed "${skill}"; then
      echo "OK    Skill: ${skill}"
    else
      echo "FAIL  Skill missing: ${skill}"
      failures=$((failures + 1))
    fi
  done < <(get_locked_skills)

  return "${failures}"
}

verify_export_script() {
  verify_linked_script "${EXPORT_SCRIPT}" "export-chatgpt-context.sh"
}

verify_doctor_script() {
  verify_linked_script "${DOCTOR_SCRIPT}" "doctor.sh"
}

verify_linked_script() {
  local source_script="$1"
  local name="$2"
  local failures=0
  local link_path="${TARGET_SCRIPTS_DIR}/${name}"

  if [[ ! -L "${link_path}" ]]; then
    echo "FAIL  Script not linked: ${link_path}"
    failures=$((failures + 1))
    return "${failures}"
  fi

  local current_target
  current_target="$(readlink "${link_path}")"
  if [[ "${current_target}" != "${source_script}" ]]; then
    echo "FAIL  Script link target mismatch: ${link_path} -> ${current_target}"
    failures=$((failures + 1))
    return "${failures}"
  fi

  if [[ ! -x "${link_path}" ]]; then
    echo "FAIL  Script is not executable: ${link_path}"
    failures=$((failures + 1))
    return "${failures}"
  fi

  echo "OK    Script: ${name}"
  return "${failures}"
}

verify_ai_platform_unchanged() {
  local failures=0

  if [[ ! -f "${SKILLS_LOCK}" ]]; then
    echo "FAIL  AI Platform skills-lock.json missing"
    failures=$((failures + 1))
  else
    echo "OK    AI Platform skills-lock.json intact"
  fi

  if [[ "${TARGET_PROJECT}" == "${AI_REPO}" ]]; then
    echo "OK    Target project is the AI Platform repository"
    return "${failures}"
  fi

  if [[ -L "${AI_REPO}/skills-lock.json" ]]; then
    echo "FAIL  AI Platform skills-lock.json was replaced with a symlink"
    failures=$((failures + 1))
  fi

  return "${failures}"
}

run_verification() {
  local rule_failures=0
  local skill_failures=0
  local script_failures=0
  local ai_failures=0

  echo ""
  echo "--- Verification ---"
  echo ""
  echo "Rules (${TARGET_RULES_DIR}):"

  if verify_rules; then
    rule_failures=0
  else
    rule_failures=$?
  fi

  echo ""
  echo "Skills (${TARGET_SKILLS_DIR}):"

  if verify_skills; then
    skill_failures=0
  else
    skill_failures=$?
  fi

  echo ""
  echo "Scripts (${TARGET_SCRIPTS_DIR}):"

  script_failures=0
  verify_export_script || script_failures=$((script_failures + $?))
  verify_doctor_script || script_failures=$((script_failures + $?))

  echo ""
  echo "AI Platform (${AI_REPO}):"

  if verify_ai_platform_unchanged; then
    ai_failures=0
  else
    ai_failures=$?
  fi

  echo ""

  if [[ "${rule_failures}" -eq 0 && "${skill_failures}" -eq 0 && "${script_failures}" -eq 0 && "${ai_failures}" -eq 0 ]]; then
    echo "Bootstrap complete. Rules, skills, and platform scripts are available in the target project."
    echo ""
    echo "Next: establish project-specific documentation contracts from the"
    echo "installed project reality before substantive feature work."
    if [[ "${BOOTSTRAP_MODE}" == "existing" ]]; then
      echo "Existing project: follow core/prompts/existing-project-bootstrap.md"
    else
      echo "See .cursor/rules/50-workflows.mdc (New Project Workflow)."
    fi
    return 0
  fi

  echo "Bootstrap finished with verification failures." >&2
  echo "  Rule failures: ${rule_failures}" >&2
  echo "  Skill failures: ${skill_failures}" >&2
  echo "  Script failures: ${script_failures}" >&2
  echo "  AI Platform failures: ${ai_failures}" >&2
  return 1
}

report_capabilities() {
  echo ""
  echo "--- Capability diagnosis ---"
  echo ""

  BOOTSTRAP_MODE="${BOOTSTRAP_MODE:-$(project_bootstrap_mode "${TARGET_PROJECT}")}"
  echo "Bootstrap mode: ${BOOTSTRAP_MODE}"

  if project_is_laravel "${TARGET_PROJECT}"; then
    echo "Detected profile: laravel-webapp"
    if project_uses_livewire "${TARGET_PROJECT}"; then
      echo "Livewire: declared"
    else
      echo "Livewire: not declared (profile still treats this as a Laravel web app)"
    fi

    local diagnosis
    diagnosis="$(boost_diagnosis "${TARGET_PROJECT}")"
    echo "Laravel Boost: ${diagnosis}"
    echo ""
    boost_next_steps "${diagnosis}"
    echo ""

    if playwright_present "${TARGET_PROJECT}"; then
      echo "Playwright Mode A: present"
    else
      echo "Playwright Mode A: expected for this profile, not present yet."
      echo "Do not add @playwright/test without approval."
      echo "Policy: AI Platform docs/contracts/features/browser-qa.md"
    fi
  elif project_is_roots_radicle "${TARGET_PROJECT}"; then
    echo "Detected profile: roots-radicle"
    echo "Playwright Mode A is not required by this profile."
    echo "Laravel Boost is not required."
  else
    echo "Detected profile: none (not Laravel or Roots/Radicle/Sage)."
    echo "Playwright Mode A is not required."
    echo "Laravel Boost is not required."
  fi

  echo ""
  if [[ "${BOOTSTRAP_MODE}" == "existing" ]]; then
    echo "Existing-project next steps: core/prompts/existing-project-bootstrap.md"
    echo "Document intentional differences; surface open deviations."
    echo "Do not migrate application code during bootstrap."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

BOOTSTRAP_MODE="$(project_bootstrap_mode "${TARGET_PROJECT}")"

link_rules
link_export_script
link_doctor_script
bootstrap_docs_templates
ensure_gitignore_build
ensure_playwright_gitignore
restore_skills
report_capabilities
run_verification
