#!/usr/bin/env bash

# Install the optional video-production workspace into a project.
# Does not render, publish, upload, or spend generation credits.
# Does not modify application dependencies.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/project-capabilities.sh
source "${SCRIPT_DIR}/lib/project-capabilities.sh"
# shellcheck source=lib/video.sh
source "${SCRIPT_DIR}/lib/video.sh"

if [[ ! -f "${AI_REPO}/.cursor/rules/00-platform.mdc" ]]; then
  echo "Error: this script must live inside the AI Platform repository." >&2
  exit 1
fi

MODE=""
TARGET_INPUT=""
for arg in "$@"; do
  case "${arg}" in
    --studio)
      if [[ "${MODE}" == "integrated" ]]; then
        echo "Error: --studio and --integrated cannot be combined." >&2
        exit 1
      fi
      MODE="studio"
      ;;
    --integrated)
      if [[ "${MODE}" == "studio" ]]; then
        echo "Error: --studio and --integrated cannot be combined." >&2
        exit 1
      fi
      MODE="integrated"
      ;;
    -h|--help)
      echo "Usage: $0 [--studio|--integrated] /path/to/project" >&2
      echo "Installs the optional video workspace. Does not render or publish." >&2
      exit 0
      ;;
    -*)
      echo "Error: unknown option: ${arg}" >&2
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

MODE="${MODE:-integrated}"

if [[ -z "${TARGET_INPUT}" ]]; then
  if [[ "${PWD}" != "${AI_REPO}" ]]; then
    TARGET_INPUT="${PWD}"
    echo "No target path supplied; using current directory: ${TARGET_INPUT}"
  else
    echo "Usage: $0 [--studio|--integrated] /path/to/project" >&2
    exit 1
  fi
fi

if [[ ! -d "${TARGET_INPUT}" ]]; then
  echo "Error: target path does not exist or is not a directory: ${TARGET_INPUT}" >&2
  exit 1
fi

TARGET_PROJECT="$(cd "${TARGET_INPUT}" && pwd)"

echo ""
echo "=== AI Platform video production ==="
echo "AI platform: ${AI_REPO}"
echo "Target project: ${TARGET_PROJECT}"
echo "This installer does not render, publish, or spend generation credits."
echo ""

video_install "${TARGET_PROJECT}" "${MODE}"
