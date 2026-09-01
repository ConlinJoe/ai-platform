#!/usr/bin/env bash

# Install the optional harness-managed Deployer stack into an already
# bootstrapped project. Does not run bootstrap, does not deploy, and
# does not connect to a server.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/project-capabilities.sh
source "${SCRIPT_DIR}/lib/project-capabilities.sh"
# shellcheck source=lib/deployer.sh
source "${SCRIPT_DIR}/lib/deployer.sh"

if [[ ! -d "${AI_REPO}/.cursor/rules" ]] || [[ ! -f "${AI_REPO}/.cursor/rules/00-platform.mdc" ]]; then
  echo "Error: AI Platform rules not found." >&2
  echo "This script must live inside the AI Platform repository." >&2
  exit 1
fi

TARGET_INPUT=""
if [[ $# -ge 1 && -n "${1:-}" ]]; then
  TARGET_INPUT="$1"
elif [[ "${PWD}" != "${AI_REPO}" ]]; then
  TARGET_INPUT="${PWD}"
  echo "No target path supplied; using current directory: ${TARGET_INPUT}"
else
  echo "Usage: $0 /path/to/project" >&2
  echo "Installs the optional Deployer stack. Does not deploy." >&2
  exit 1
fi

if [[ ! -d "${TARGET_INPUT}" ]]; then
  echo "Error: Target path does not exist or is not a directory: ${TARGET_INPUT}" >&2
  exit 1
fi

TARGET_PROJECT="$(cd "${TARGET_INPUT}" && pwd)"

if [[ "${TARGET_PROJECT}" == "${AI_REPO}" ]]; then
  echo "Error: Refusing to install Deployer into the AI Platform repository itself." >&2
  exit 1
fi

echo ""
echo "=== AI Platform Deployer installer ==="
echo "AI platform: ${AI_REPO}"
echo "Target project: ${TARGET_PROJECT}"
echo "This installer does not deploy and does not connect to a server."
echo ""

status=0
deployer_install "${TARGET_PROJECT}" || status=$?

if [[ "${status}" -eq 2 ]]; then
  exit 2
fi
if [[ "${status}" -eq 3 ]]; then
  exit 1
fi
if [[ "${status}" -ne 0 ]]; then
  exit "${status}"
fi

exit 0
