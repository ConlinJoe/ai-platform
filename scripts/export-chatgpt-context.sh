#!/usr/bin/env bash

# Export project AI context for ChatGPT Projects.
# Run from the project root. Includes documentation, Cursor rules, agent
# skills, and project AI metadata. Never exports source code, vendor, tests,
# or generated files.

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "${SCRIPT_PATH}" ]]; then
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
fi
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"

resolve_project_root() {
  if [[ -d "${PWD}/docs" ]]; then
    echo "${PWD}"
  elif [[ -d "${SCRIPT_DIR}/../docs" ]] && [[ "${SCRIPT_DIR}" == *"/scripts" ]]; then
    cd "${SCRIPT_DIR}/.." && pwd
  else
    echo "${PWD}"
  fi
}

PROJECT_ROOT="$(resolve_project_root)"
OUTPUT_DIR="${PROJECT_ROOT}/.build/chatgpt-context"
ZIP_FILE="${PROJECT_ROOT}/.build/chatgpt-context.zip"

if [[ ! -d "${PROJECT_ROOT}/docs" ]]; then
  echo "Error: docs/ directory not found at ${PROJECT_ROOT}/docs" >&2
  echo "Run this script from a bootstrapped project root." >&2
  exit 1
fi

if [[ ! -f "${PROJECT_ROOT}/docs/README.md" ]]; then
  echo "Error: docs/README.md not found. It is required as the documentation index." >&2
  exit 1
fi

echo "=== ChatGPT Context Export ==="
echo "Project: ${PROJECT_ROOT}"
echo ""
echo "Including:"

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

copy_path() {
  local rel="$1"
  local src="${PROJECT_ROOT}/${rel}"

  if [[ ! -e "${src}" ]]; then
    return 0
  fi

  local dest_parent="${OUTPUT_DIR}/$(dirname "${rel}")"
  mkdir -p "${dest_parent}"
  cp -RL "${src}" "${dest_parent}/"
  echo "  ${rel}"
}

copy_path "docs"

if [[ -d "${PROJECT_ROOT}/.cursor/rules" ]]; then
  copy_path ".cursor/rules"
fi

if [[ -d "${PROJECT_ROOT}/.agents" ]]; then
  copy_path ".agents"
fi

OPTIONAL_FILES=(
  "skills-lock.json"
  "AGENTS.md"
  "CLAUDE.md"
  ".cursorrules"
)

for rel in "${OPTIONAL_FILES[@]}"; do
  copy_path "${rel}"
done

rm -f "${ZIP_FILE}"
(
  cd "${OUTPUT_DIR}"
  zip -qr "${ZIP_FILE}" .
)

echo ""
echo "Created: ${ZIP_FILE}"
echo "Upload chatgpt-context.zip to your ChatGPT Project."
echo ""
echo "Excluded by design: app/, bootstrap/, config/, database/, public/,"
echo "resources/, routes/, tests/, vendor/, node_modules/, storage/, .git/,"
echo "and build artifacts."
