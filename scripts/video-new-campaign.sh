#!/usr/bin/env bash

# Create one campaign inside an opted-in video workspace.
# Copies a brand-free template only. Does not copy another campaign.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/project-capabilities.sh
source "${SCRIPT_DIR}/lib/project-capabilities.sh"
# shellcheck source=lib/video.sh
source "${SCRIPT_DIR}/lib/video.sh"

FORMAT=""
ARGS=()
for arg in "$@"; do
  case "${arg}" in
    --format)
      shift_next=1
      ;;
    -h|--help)
      echo "Usage: $0 <project> <slug> <template> [--format landscape|vertical|square|social]" >&2
      exit 0
      ;;
    *)
      if [[ "${shift_next:-0}" -eq 1 ]]; then
        FORMAT="${arg}"
        shift_next=0
      else
        ARGS+=("${arg}")
      fi
      ;;
  esac
done

if [[ "${shift_next:-0}" -eq 1 || ${#ARGS[@]} -ne 3 ]]; then
  echo "Usage: $0 <project> <slug> <template> [--format landscape|vertical|square|social]" >&2
  exit 1
fi

TARGET_INPUT="${ARGS[0]}"
SLUG="${ARGS[1]}"
TEMPLATE="${ARGS[2]}"

if [[ ! "${SLUG}" =~ ^[a-z0-9][a-z0-9-]{0,40}$ ]]; then
  echo "Error: slug must be lowercase letters, numbers, and hyphens." >&2
  exit 1
fi

TEMPLATE_DIR="${AI_REPO}/templates/video/templates/${TEMPLATE}"
if [[ ! -f "${TEMPLATE_DIR}/spec.js" ]]; then
  echo "Error: unknown template: ${TEMPLATE}" >&2
  exit 1
fi

if [[ ! -d "${TARGET_INPUT}" ]]; then
  echo "Error: project path does not exist: ${TARGET_INPUT}" >&2
  exit 1
fi

PROJECT="$(cd "${TARGET_INPUT}" && pwd)"
if ! video_is_harness_managed "${PROJECT}"; then
  echo "Error: video production is not installed in ${PROJECT}." >&2
  echo "Run scripts/install-video-production.sh first." >&2
  exit 1
fi

DEST="${PROJECT}/video/campaigns/${SLUG}"
if [[ -e "${DEST}" ]]; then
  echo "Error: campaign already exists: ${DEST}" >&2
  exit 1
fi

mkdir -p "${DEST}/film" "${DEST}/assets" "${DEST}/reviews"
cp "${AI_REPO}/templates/video/runtime/index.html" "${DEST}/film/index.html"
cp "${AI_REPO}/templates/video/runtime/film.js" "${DEST}/film/film.js"
cp "${AI_REPO}/templates/video/runtime/motion.js" "${DEST}/film/motion.js"
cp "${AI_REPO}/templates/video/runtime/package.json" "${DEST}/film/package.json"
cp "${TEMPLATE_DIR}/spec.js" "${DEST}/film/spec.js"
cp "${TEMPLATE_DIR}/brief.md" "${DEST}/brief.md"
cp "${AI_REPO}/templates/video/brand.md" "${DEST}/brand.md"
touch "${DEST}/assets/.gitkeep" "${DEST}/reviews/.gitkeep"

if [[ -n "${FORMAT}" ]]; then
  python3 - "${DEST}/film/spec.js" "${FORMAT}" <<'PY'
import sys
from pathlib import Path
path, fmt = sys.argv[1:]
sizes = {
    "landscape": (1920, 1080),
    "vertical": (1080, 1920),
    "square": (1080, 1080),
    "social": (1080, 1350),
}
if fmt not in sizes:
    sys.exit(f"unknown format: {fmt}")
width, height = sizes[fmt]
text = Path(path).read_text(encoding="utf-8")
replacements = {
    "format": f"format: '{fmt}'",
    "width": f"width: {width}",
    "height": f"height: {height}",
}
lines = []
for line in text.splitlines():
    stripped = line.lstrip()
    key = stripped.split(":", 1)[0]
    if key in replacements and stripped.endswith(","):
        indent = line[: len(line) - len(stripped)]
        lines.append(f"{indent}{replacements[key]},")
    else:
        lines.append(line)
Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
fi

echo "Campaign ready: ${DEST}"
echo "Edit brief.md, brand.md, and film/spec.js. Render with:"
echo "  ${AI_REPO}/scripts/video-render.sh ${DEST}"
