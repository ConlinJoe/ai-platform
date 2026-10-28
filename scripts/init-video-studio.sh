#!/usr/bin/env bash

# Create a video-only project and opt it into the shared video capability.
# Does not install an application framework. Does not render or publish.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ $# -ne 1 || "${1}" == "-h" || "${1}" == "--help" ]]; then
  echo "Usage: $0 <new-or-empty-directory>" >&2
  echo "Bootstraps a video studio. Does not render, publish, or spend credits." >&2
  exit 1
fi

TARGET_INPUT="$1"
mkdir -p "${TARGET_INPUT}"
TARGET="$(cd "${TARGET_INPUT}" && pwd)"

if [[ "${TARGET}" == "${AI_REPO}" ]]; then
  echo "Error: refusing to turn the AI Platform repository into a video studio." >&2
  exit 1
fi

if [[ -f "${TARGET}/composer.json" || -f "${TARGET}/package.json" || -f "${TARGET}/wp-config.php" || -f "${TARGET}/artisan" ]]; then
  echo "Error: ${TARGET} already looks like an application." >&2
  echo "Use scripts/install-video-production.sh for an existing project." >&2
  exit 1
fi

export AI_BOOTSTRAP_NONINTERACTIVE=1
"${AI_REPO}/scripts/bootstrap-project.sh" --without-deployer "${TARGET}"
"${AI_REPO}/scripts/install-video-production.sh" --studio "${TARGET}"

echo ""
echo "Video studio ready: ${TARGET}"
echo "Detected profile: video-studio"
echo "Create a campaign with: ${AI_REPO}/scripts/video-new-campaign.sh ${TARGET} <slug> <template>"
