#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_DIR="${AI_REPO}/.cursor/rules"
SKILLS_LOCK="${AI_REPO}/skills-lock.json"

# shellcheck source=lib/project-capabilities.sh
source "${SCRIPT_DIR}/lib/project-capabilities.sh"
# shellcheck source=lib/deployer.sh
source "${SCRIPT_DIR}/lib/deployer.sh"

REQUIRED_SKILLS=()
MISSING_SKILLS=()
PRESENT_SKILLS=()
DEPLOYER_MODE=""

if [[ ! -d "${RULES_DIR}" ]] || [[ ! -f "${RULES_DIR}/00-platform.mdc" ]]; then
  echo "Error: AI Platform rules not found." >&2
  echo "Expected rules at: ${RULES_DIR}" >&2
  echo "This script must live inside the AI Platform repository." >&2
  exit 1
fi

usage() {
  cat <<EOF
Usage: $0 [--with-deployer|--without-deployer] [project-path]

Installs AI Development Harness infrastructure into a project.
Does not deploy. Installing Deployer does not authorize deployment.

  --with-deployer       Install the optional Deployer stack (no prompt)
  --without-deployer    Skip the optional Deployer stack (no prompt)

Without either flag, interactive bootstrap prompts:
  ${DEPLOYER_PROMPT}
Default is N. Non-interactive runs skip Deployer unless --with-deployer
is set (AI_BOOTSTRAP_NONINTERACTIVE=1 also skips).
EOF
}

# Target resolution priority:
# 1. Explicit path argument
# 2. Current working directory when invoked outside the AI Platform repo
# 3. Interactive prompt (fallback)
TARGET_INPUT=""
for arg in "$@"; do
  case "${arg}" in
    --with-deployer)
      if [[ "${DEPLOYER_MODE}" == "without" ]]; then
        echo "Error: --with-deployer and --without-deployer cannot be combined." >&2
        exit 1
      fi
      DEPLOYER_MODE="with"
      ;;
    --without-deployer)
      if [[ "${DEPLOYER_MODE}" == "with" ]]; then
        echo "Error: --with-deployer and --without-deployer cannot be combined." >&2
        exit 1
      fi
      DEPLOYER_MODE="without"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: ${arg}" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "${TARGET_INPUT}" ]]; then
        echo "Error: unexpected argument: ${arg}" >&2
        exit 1
      fi
      TARGET_INPUT="${arg}"
      ;;
  esac
done

if [[ -z "${TARGET_INPUT}" ]]; then
  if [[ "${PWD}" != "${AI_REPO}" ]]; then
    TARGET_INPUT="${PWD}"
    echo "No target path supplied; using current directory: ${TARGET_INPUT}"
  else
    read -r -p "Enter target project path: " TARGET_INPUT
    if [[ -z "${TARGET_INPUT}" ]]; then
      echo "Error: Target project path is required." >&2
      exit 1
    fi
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
GUARDRAILS_SCRIPT="${AI_REPO}/scripts/check-guardrails.sh"
DOCS_TEMPLATES_DIR="${AI_REPO}/templates/docs"
BROWSER_QA_TEMPLATE="${AI_REPO}/templates/docs/contracts/features/browser-qa.md"
RECONCILIATION_TEMPLATE="${AI_REPO}/templates/existing-project/platform-reconciliation.md"
AGENT_CORE="${AI_REPO}/core/agent-core.md"
CLAUDE_TEMPLATE="${AI_REPO}/templates/agents/CLAUDE.md"
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

link_guardrails_script() {
  echo ""
  echo "--- Linking Guardrail Check Script ---"
  link_platform_script "${GUARDRAILS_SCRIPT}" "check-guardrails.sh"
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
  local fill_hint="${4:-}"

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
  if [[ -n "${fill_hint}" ]]; then
    echo "Added draft ${label}: ${dest}"
    echo "${fill_hint}"
  else
    echo "Added ${label}: ${dest}"
  fi
}

add_missing_profile_templates() {
  local target_docs="${TARGET_PROJECT}/docs"

  local fill_hint="Fill from this project's reality. Do not treat the draft as approval."

  copy_if_missing \
    "${AI_REPO}/templates/docs/99-project-status.md" \
    "${target_docs}/99-project-status.md" \
    "project status" \
    "${fill_hint}"

  copy_if_missing \
    "${AI_REPO}/templates/docs/working-mode.md" \
    "${target_docs}/working-mode.md" \
    "working mode" \
    "${fill_hint}"

  copy_if_missing \
    "${RECONCILIATION_TEMPLATE}" \
    "${target_docs}/contracts/foundational/platform-reconciliation.md" \
    "platform reconciliation" \
    "${fill_hint}"

  if project_is_laravel_webapp "${TARGET_PROJECT}"; then
    copy_if_missing \
      "${BROWSER_QA_TEMPLATE}" \
      "${target_docs}/contracts/features/browser-qa.md" \
      "browser QA contract" \
      "${fill_hint}"
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

ensure_roots_resources_images() {
  if ! project_is_roots_radicle "${TARGET_PROJECT}"; then
    return 0
  fi

  if [[ "${BOOTSTRAP_MODE}" != "new" ]]; then
    return 0
  fi

  echo ""
  echo "--- Roots/Radicle resources/images ---"

  local images_dir="${TARGET_PROJECT}/resources/images"
  mkdir -p "${images_dir}"
  if [[ ! -e "${images_dir}/.gitkeep" ]]; then
    touch "${images_dir}/.gitkeep"
  fi
  echo "Ensured ${images_dir} exists"
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

ensure_hallmark_gitignore() {
  local gitignore="${TARGET_PROJECT}/.gitignore"

  echo "--- Hallmark artifact gitignore ---"

  if [[ ! -f "${gitignore}" ]]; then
    touch "${gitignore}"
  fi

  if grep -qE '(^|/)\.hallmark/?$' "${gitignore}"; then
    echo ".hallmark/ already listed in .gitignore"
    return 0
  fi

  printf '\n# Hallmark operational artifacts (keep design.md tracked)\n.hallmark/\n' >> "${gitignore}"
  echo "Added .hallmark/ to ${gitignore}"
}

ensure_impeccable_gitignore() {
  local gitignore="${TARGET_PROJECT}/.gitignore"

  echo "--- Impeccable artifact gitignore ---"

  if [[ ! -f "${gitignore}" ]]; then
    touch "${gitignore}"
  fi

  if grep -qF '# impeccable-ignore-start' "${gitignore}"; then
    echo "Impeccable ignore block already present"
    return 0
  fi

  cat >> "${gitignore}" <<'EOF'

# impeccable-ignore-start
# Ephemeral Impeccable output. Shared config, design, surface, and critique
# artifacts remain tracked.
.impeccable/config.local.json
.impeccable/hook.cache.json
.impeccable/hook.pending.json
.impeccable/*.png
.impeccable/review/
.impeccable/questions/
.impeccable/live/server.json
.impeccable/live/sessions/
.impeccable/live/previews/
.impeccable/live/annotations/
.impeccable/live/cache/
.impeccable/live/manual-edit-apply-transaction.json
.impeccable/live/manual-edit-events.jsonl
.impeccable/live/manual-edit-evidence/
.impeccable/live/pending-manual-edits.json
.impeccable/live/deferred-svelte-component-accepts.json
.impeccable/live/*.png
# impeccable-ignore-end
EOF
  echo "Added Impeccable ignore block to ${gitignore}"
}

ensure_local_artifact_gitignore() {
  local gitignore="${TARGET_PROJECT}/.gitignore"

  echo "--- Local artifact gitignore ---"

  if [[ ! -f "${gitignore}" ]]; then
    touch "${gitignore}"
  fi

  local added=0
  local has_ds=0
  local has_nested_ds=0
  local has_ai=0

  if grep -qE '^\.DS_Store$' "${gitignore}"; then
    has_ds=1
  fi
  if grep -qE '^\*\*/\.DS_Store$' "${gitignore}"; then
    has_nested_ds=1
  fi
  if grep -qE '^\.ai/?$' "${gitignore}"; then
    has_ai=1
  fi

  if [[ "${has_ds}" -eq 0 || "${has_nested_ds}" -eq 0 ]]; then
    if [[ "${has_ds}" -eq 0 && "${has_nested_ds}" -eq 0 ]]; then
      printf '\n# macOS\n.DS_Store\n**/.DS_Store\n' >> "${gitignore}"
    else
      if [[ "${has_ds}" -eq 0 ]]; then
        printf '\n.DS_Store\n' >> "${gitignore}"
      fi
      if [[ "${has_nested_ds}" -eq 0 ]]; then
        printf '\n**/.DS_Store\n' >> "${gitignore}"
      fi
    fi
    added=1
  fi

  if [[ "${has_ai}" -eq 0 ]]; then
    printf '\n# AI Development Harness\n.ai/\n' >> "${gitignore}"
    added=1
  fi

  if [[ "${added}" -eq 1 ]]; then
    echo "Ensured local artifact paths in ${gitignore}"
  else
    echo "Local artifact paths already listed in .gitignore"
  fi
}

RETIRED_DESIGN_SKILLS=(
  frontend-design
  ui-ux-pro-max
  superdesign
)

prune_retired_design_skills() {
  echo ""
  echo "--- Pruning retired design skills ---"

  local name dest removed=0
  for name in "${RETIRED_DESIGN_SKILLS[@]}"; do
    for dest in \
      "${TARGET_SKILLS_DIR}/${name}" \
      "${TARGET_PROJECT}/.claude/skills/${name}" \
      "${TARGET_PROJECT}/.grok/skills/${name}"
    do
      if [[ -e "${dest}" || -L "${dest}" ]]; then
        rm -rf "${dest}"
        echo "Removed retired skill: ${dest}"
        removed=1
      fi
    done
  done

  if [[ "${removed}" -eq 0 ]]; then
    echo "No retired design skills to prune"
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

  prune_retired_design_skills

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
# Agent adapters (thin entrypoints; canonical rules stay in .cursor/rules)
# ---------------------------------------------------------------------------

link_if_missing_symlink() {
  local source="$1"
  local dest="$2"
  local label="$3"
  local source_exists=0

  # `source` is the symlink target string. Relative targets are resolved
  # from the destination directory, not from $PWD (bootstrap is often
  # invoked from the harness clone with an explicit project path).
  if [[ "${source}" == /* ]]; then
    if [[ -e "${source}" || -L "${source}" ]]; then
      source_exists=1
    fi
  else
    mkdir -p "$(dirname "${dest}")"
    if [[ -e "$(dirname "${dest}")/${source}" || -L "$(dirname "${dest}")/${source}" ]]; then
      source_exists=1
    fi
  fi

  if [[ "${source_exists}" -eq 0 ]]; then
    echo "Warning: missing source for ${label}: ${source}" >&2
    return 0
  fi

  if [[ -L "${dest}" ]]; then
    local current_target
    current_target="$(readlink "${dest}")"
    if [[ "${current_target}" != "${source}" ]]; then
      ln -sfn "${source}" "${dest}"
      echo "Updated link: ${dest} -> ${source}"
    else
      echo "Already linked: ${dest}"
    fi
    return 0
  fi

  if [[ -e "${dest}" ]]; then
    echo "Already present: ${dest} (left in place; not replaced with ${label})"
    return 0
  fi

  mkdir -p "$(dirname "${dest}")"
  ln -s "${source}" "${dest}"
  echo "Linked: ${dest} -> ${source}"
}

provision_agent_adapters() {
  echo ""
  echo "--- Agent adapters (Cursor, Grok Build, Codex, Claude Code, Hermes) ---"

  if [[ ! -f "${AGENT_CORE}" ]]; then
    echo "Warning: canonical agent core missing: ${AGENT_CORE}" >&2
  else
    link_if_missing_symlink \
      "${AGENT_CORE}" \
      "${TARGET_PROJECT}/AGENTS.md" \
      "AGENTS.md"
  fi

  copy_if_missing \
    "${CLAUDE_TEMPLATE}" \
    "${TARGET_PROJECT}/CLAUDE.md" \
    "CLAUDE.md"

  if [[ -e "${TARGET_PROJECT}/.hermes.md" || -e "${TARGET_PROJECT}/HERMES.md" ]]; then
    echo "Warning: .hermes.md / HERMES.md is present and would override AGENTS.md in Hermes Agent."
    echo "The AI Platform does not create these files. Prefer the shared AGENTS.md entrypoint."
  else
    echo "Hermes: no .hermes.md (intentional). Hermes consumes AGENTS.md."
  fi

  if project_is_laravel "${TARGET_PROJECT}" && [[ -f "${AGENT_CORE}" ]]; then
    link_if_missing_symlink \
      "${AGENT_CORE}" \
      "${TARGET_PROJECT}/.ai/guidelines/ai-platform.md" \
      "Boost AI Platform guideline"
    echo "Laravel Boost: .ai/guidelines/ai-platform.md -> core/agent-core.md"
    echo "Run php artisan boost:install or boost:update so generated AGENTS.md includes it."
    echo "Do not overwrite Boost-owned AGENTS.md by hand."
  fi

  local skill
  while IFS= read -r skill; do
    [[ -n "${skill}" ]] || continue
    local skill_src="${TARGET_SKILLS_DIR}/${skill}"
    [[ -d "${skill_src}" ]] || continue

    link_if_missing_symlink \
      "../../.agents/skills/${skill}" \
      "${TARGET_PROJECT}/.claude/skills/${skill}" \
      "Claude skill ${skill}"

    link_if_missing_symlink \
      "../../.agents/skills/${skill}" \
      "${TARGET_PROJECT}/.grok/skills/${skill}" \
      "Grok skill ${skill}"
  done < <(get_locked_skills)
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

verify_guardrails_script() {
  verify_linked_script "${GUARDRAILS_SCRIPT}" "check-guardrails.sh"
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

verify_agent_adapters() {
  local failures=0
  local agents_md="${TARGET_PROJECT}/AGENTS.md"
  local claude_md="${TARGET_PROJECT}/CLAUDE.md"

  echo ""
  echo "Agent adapters:"

  if [[ ! -e "${agents_md}" && ! -L "${agents_md}" ]]; then
    echo "FAIL  AGENTS.md missing"
    failures=$((failures + 1))
  elif [[ -L "${agents_md}" ]]; then
    if [[ "$(readlink "${agents_md}")" == "${AGENT_CORE}" ]]; then
      echo "OK    AGENTS.md linked to canonical agent-core"
    else
      echo "OK    AGENTS.md linked (project-owned target)"
    fi
  else
    echo "OK    AGENTS.md present (existing file left in place)"
  fi

  if [[ -f "${claude_md}" || -L "${claude_md}" ]]; then
    echo "OK    CLAUDE.md present"
  else
    echo "FAIL  CLAUDE.md missing"
    failures=$((failures + 1))
  fi

  if [[ -e "${TARGET_PROJECT}/.hermes.md" || -e "${TARGET_PROJECT}/HERMES.md" ]]; then
    echo "WARN  .hermes.md / HERMES.md present (overrides AGENTS.md in Hermes)"
  else
    echo "OK    no .hermes.md (Hermes uses AGENTS.md)"
  fi

  if project_is_laravel "${TARGET_PROJECT}"; then
    local boost_guideline="${TARGET_PROJECT}/.ai/guidelines/ai-platform.md"
    if [[ -L "${boost_guideline}" ]] && [[ "$(readlink "${boost_guideline}")" == "${AGENT_CORE}" ]]; then
      echo "OK    Laravel Boost guideline linked to agent-core"
    elif [[ -e "${boost_guideline}" ]]; then
      echo "OK    Laravel Boost guideline present"
    else
      echo "FAIL  Laravel Boost guideline missing: ${boost_guideline}"
      failures=$((failures + 1))
    fi
  fi

  return "${failures}"
}

run_verification() {
  local rule_failures=0
  local skill_failures=0
  local script_failures=0
  local adapter_failures=0
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
  verify_guardrails_script || script_failures=$((script_failures + $?))

  if verify_agent_adapters; then
    adapter_failures=0
  else
    adapter_failures=$?
  fi

  echo ""
  echo "AI Platform (${AI_REPO}):"

  if verify_ai_platform_unchanged; then
    ai_failures=0
  else
    ai_failures=$?
  fi

  echo ""

  if [[ "${rule_failures}" -eq 0 && "${skill_failures}" -eq 0 && "${script_failures}" -eq 0 && "${adapter_failures}" -eq 0 && "${ai_failures}" -eq 0 ]]; then
    echo "Bootstrap complete. Rules, skills, and platform scripts are available in the target project."
    echo ""
    if [[ "${BOOTSTRAP_MODE}" == "existing" ]]; then
      echo "Bootstrap provisioned the AI Platform. It did not adopt the project."
      echo "Next: start a fresh agent session in this project and follow:"
      echo "  ${AI_REPO}/core/prompts/project-adoption.md"
    else
      echo "Next: establish project-specific documentation contracts from the"
      echo "installed project reality before substantive feature work."
      echo "See .cursor/rules/50-workflows.mdc (New Project Workflow)."
    fi
    return 0
  fi

  echo "Bootstrap finished with verification failures." >&2
  echo "  Rule failures: ${rule_failures}" >&2
  echo "  Skill failures: ${skill_failures}" >&2
  echo "  Script failures: ${script_failures}" >&2
  echo "  Adapter failures: ${adapter_failures}" >&2
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
    echo "Preferred greenfield stack: ACF Pro, Keen Slider, WPForms Lite."

    if npm_has_package "${TARGET_PROJECT}" "keen-slider"; then
      echo "keen-slider: declared"
    else
      echo "keen-slider: not declared"
    fi

    if [[ -d "${TARGET_PROJECT}/resources/images" ]]; then
      echo "resources/images: present"
    else
      echo "resources/images: missing"
    fi

    echo "Platform bootstrap does not install npm packages or WordPress plugins."
    if [[ "${BOOTSTRAP_MODE}" == "existing" ]]; then
      echo "Existing project: inspect ACF, slider, and form architecture first."
      echo "Preserve intentional alternatives. Do not install or migrate during bootstrap."
      echo "Report divergence from the preferred stack."
    else
      echo "Greenfield next steps: follow core/project-profiles/roots-radicle.md."
      echo "Install keen-slider via npm. Install/activate WPForms Lite via WP-CLI once WordPress is available."
      echo "Install ACF Pro when authenticated installation is available; otherwise report the credential blocker and continue."
      echo "Do not commit license keys or secrets."
    fi
  else
    echo "Detected profile: none (not Laravel or Roots/Radicle/Sage)."
    echo "Playwright Mode A is not required."
    echo "Laravel Boost is not required."
  fi

  echo ""
  echo "GitHub CLI (gh) is optional. Bootstrap does not install or authenticate it."
  echo "Bootstrap does not copy or overwrite .github/ Issue or PR templates."
  echo "Deployer is an optional capability. Installing it does not authorize deployment."

  echo ""
  if [[ "${BOOTSTRAP_MODE}" == "existing" ]]; then
    echo "Existing-project next steps: ${AI_REPO}/core/prompts/project-adoption.md"
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
link_guardrails_script
bootstrap_docs_templates
ensure_gitignore_build
ensure_playwright_gitignore
ensure_hallmark_gitignore
ensure_impeccable_gitignore
ensure_local_artifact_gitignore
ensure_roots_resources_images
restore_skills
provision_agent_adapters
deployer_offer_or_install "${TARGET_PROJECT}" "${DEPLOYER_MODE}"
report_capabilities
run_verification
