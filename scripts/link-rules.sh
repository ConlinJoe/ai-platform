#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_DIR="${AI_REPO}/.cursor/rules"

if [[ ! -d "${RULES_DIR}" ]] || [[ ! -f "${RULES_DIR}/00-platform.mdc" ]]; then
  echo "Error: This script must be run from the AI platform repository." >&2
  echo "Expected rules at: ${RULES_DIR}" >&2
  exit 1
fi

read -r -p "Enter target project path: " TARGET_INPUT

if [[ -z "${TARGET_INPUT}" ]]; then
  echo "Error: Target project path is required." >&2
  exit 1
fi

if [[ ! -d "${TARGET_INPUT}" ]]; then
  echo "Error: Target path does not exist or is not a directory: ${TARGET_INPUT}" >&2
  exit 1
fi

TARGET_PROJECT="$(cd "${TARGET_INPUT}" && pwd)"
TARGET_RULES_DIR="${TARGET_PROJECT}/.cursor/rules"

mkdir -p "${TARGET_RULES_DIR}"

linked=0
updated=0
skipped=0

for rule in "${RULES_DIR}"/*.mdc; do
  [[ -f "${rule}" ]] || continue

  name="$(basename "${rule}")"
  link_path="${TARGET_RULES_DIR}/${name}"

  if [[ -L "${link_path}" ]]; then
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
echo "Done. Linked: ${linked}, updated: ${updated}, skipped: ${skipped}"
