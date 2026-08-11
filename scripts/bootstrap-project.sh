#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_DIR="${AI_REPO}/.cursor/rules"
SKILLS_LOCK="${AI_REPO}/skills-lock.json"

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
DOCS_TEMPLATES_DIR="${AI_REPO}/templates/docs"

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

  mkdir -p "${TARGET_SCRIPTS_DIR}"

  local link_path="${TARGET_SCRIPTS_DIR}/export-chatgpt-context.sh"

  if [[ -L "${link_path}" ]]; then
    local current_target
    current_target="$(readlink "${link_path}")"
    if [[ "${current_target}" != "${EXPORT_SCRIPT}" ]]; then
      ln -sf "${EXPORT_SCRIPT}" "${link_path}"
      echo "Updated link: ${link_path} -> ${EXPORT_SCRIPT}"
    else
      echo "Already linked: ${link_path}"
    fi
  elif [[ -e "${link_path}" ]]; then
    read -r -p "Real file exists at ${link_path}. Replace with symlink? [y/N] " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
      rm "${link_path}"
      ln -s "${EXPORT_SCRIPT}" "${link_path}"
      echo "Replaced with link: ${link_path} -> ${EXPORT_SCRIPT}"
    else
      echo "Skipped: ${link_path}"
    fi
  else
    ln -s "${EXPORT_SCRIPT}" "${link_path}"
    echo "Linked: ${link_path} -> ${EXPORT_SCRIPT}"
  fi

  chmod +x "${EXPORT_SCRIPT}"
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

  if [[ -f "${target_docs}/README.md" ]]; then
    echo "Documentation index already exists: ${target_docs}/README.md"
    echo "Skipping template copy to avoid overwriting project docs."
    return 0
  fi

  mkdir -p "${target_docs}"
  cp -R "${DOCS_TEMPLATES_DIR}/." "${target_docs}/"
  echo "Copied documentation templates to ${target_docs}/"
  echo "Templates are placeholders — establish project-specific contracts next."
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
  local failures=0
  local link_path="${TARGET_SCRIPTS_DIR}/export-chatgpt-context.sh"

  if [[ ! -L "${link_path}" ]]; then
    echo "FAIL  Export script not linked: ${link_path}"
    failures=$((failures + 1))
    return "${failures}"
  fi

  local current_target
  current_target="$(readlink "${link_path}")"
  if [[ "${current_target}" != "${EXPORT_SCRIPT}" ]]; then
    echo "FAIL  Export script link target mismatch: ${link_path} -> ${current_target}"
    failures=$((failures + 1))
    return "${failures}"
  fi

  if [[ ! -x "${link_path}" ]]; then
    echo "FAIL  Export script is not executable: ${link_path}"
    failures=$((failures + 1))
    return "${failures}"
  fi

  echo "OK    Export script: export-chatgpt-context.sh"
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

  if verify_export_script; then
    script_failures=0
  else
    script_failures=$?
  fi

  echo ""
  echo "AI Platform (${AI_REPO}):"

  if verify_ai_platform_unchanged; then
    ai_failures=0
  else
    ai_failures=$?
  fi

  echo ""

  if [[ "${rule_failures}" -eq 0 && "${skill_failures}" -eq 0 && "${script_failures}" -eq 0 && "${ai_failures}" -eq 0 ]]; then
    echo "Bootstrap complete. Rules, skills, and export script are available in the target project."
    echo ""
    echo "Next: establish project-specific documentation contracts from the"
    echo "installed project reality before substantive feature work."
    echo "See .cursor/rules/50-workflows.mdc (New Project Workflow)."
    return 0
  fi

  echo "Bootstrap finished with verification failures." >&2
  echo "  Rule failures: ${rule_failures}" >&2
  echo "  Skill failures: ${skill_failures}" >&2
  echo "  Script failures: ${script_failures}" >&2
  echo "  AI Platform failures: ${ai_failures}" >&2
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

link_rules
link_export_script
bootstrap_docs_templates
ensure_gitignore_build
restore_skills
run_verification
