#!/usr/bin/env bash

# Render one campaign locally. Does not spend Scenario credits.
# Does not publish, upload, or delete an existing master unless --replace
# is passed.

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "${SCRIPT_PATH}" ]]; then
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
fi
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

for arg in "$@"; do
  case "${arg}" in
    --scenario|--generate|--generate-video|--generate-audio|--txt2video|--txt2audio|--txt2img)
      echo "Refusing a paid generation flag." >&2
      echo "This command is local rendering. It does not spend Scenario credits." >&2
      echo "Paid image, video, or audio generation needs a named provider, a verified price, and explicit authorization." >&2
      echo "This command will not spend credits, including on a retry." >&2
      exit 2
      ;;
  esac
done

CAMPAIGN=""
EXTRA=()
expect_resolution=0
for arg in "$@"; do
  case "${arg}" in
    --replace|--resolution)
      if [[ "${arg}" == "--resolution" ]]; then
        expect_resolution=1
      fi
      EXTRA+=("${arg}")
      ;;
    *)
      if [[ "${expect_resolution}" -eq 1 ]]; then
        EXTRA+=("${arg}")
        expect_resolution=0
      elif [[ -z "${CAMPAIGN}" ]]; then
        CAMPAIGN="${arg}"
      else
        echo "Error: unexpected argument: ${arg}" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${CAMPAIGN}" || ! -d "${CAMPAIGN}" ]]; then
  echo "Usage: $0 <video/campaigns/slug> [--replace] [--resolution 1080|4k]" >&2
  exit 1
fi

CAMPAIGN="$(cd "${CAMPAIGN}" && pwd)"
if [[ ! -f "${CAMPAIGN}/film/index.html" || ! -f "${CAMPAIGN}/film/spec.js" ]]; then
  echo "Error: ${CAMPAIGN} is not a campaign (missing film/index.html or film/spec.js)." >&2
  exit 1
fi

VIDEO_ROOT="$(cd "${CAMPAIGN}/../.." && pwd)"
if [[ "$(basename "${VIDEO_ROOT}")" != "video" ]]; then
  echo "Error: a campaign must live in <project>/video/campaigns/<slug>." >&2
  exit 1
fi

command -v ffmpeg >/dev/null 2>&1 || { echo "Error: ffmpeg is required for local rendering." >&2; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo "Error: ffprobe is required for local rendering." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Error: Node.js is required for local rendering." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required for technical validation." >&2; exit 1; }

RUNTIME="${VIDEO_ROOT}/.runtime"
mkdir -p "${RUNTIME}"
if [[ ! -f "${RUNTIME}/package.json" ]]; then
  cp "${AI_REPO}/templates/video/runtime-package.json" "${RUNTIME}/package.json"
fi
if [[ ! -d "${RUNTIME}/node_modules/playwright" ]]; then
  echo "Installing the isolated Playwright package into video/.runtime (no browser download)."
  npm install --prefix "${RUNTIME}" --ignore-scripts --no-fund --no-audit
fi

if [[ ${#EXTRA[@]} -eq 0 ]]; then
  exec node "${AI_REPO}/scripts/video/render.mjs" "${CAMPAIGN}"
fi
exec node "${AI_REPO}/scripts/video/render.mjs" "${CAMPAIGN}" "${EXTRA[@]}"
