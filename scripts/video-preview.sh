#!/usr/bin/env bash

# Serve one campaign for local preview.
# Binds to 127.0.0.1 and serves only that campaign directory.
# Does not render, publish, upload, or spend generation credits.

set -euo pipefail

CAMPAIGN="${1:-}"
PORT="${2:-5671}"

if [[ -z "${CAMPAIGN}" || ! -d "${CAMPAIGN}" ]]; then
  echo "Usage: $0 <video/campaigns/slug> [port]" >&2
  exit 1
fi

if [[ ! "${PORT}" =~ ^[0-9]+$ ]] || [[ "${PORT}" -lt 1 || "${PORT}" -gt 65535 ]]; then
  echo "Error: port must be an integer from 1 to 65535." >&2
  exit 1
fi

CAMPAIGN="$(cd "${CAMPAIGN}" && pwd)"
if [[ ! -f "${CAMPAIGN}/film/index.html" || ! -f "${CAMPAIGN}/film/spec.js" ]]; then
  echo "Error: ${CAMPAIGN} is not a campaign (missing film/index.html or film/spec.js)." >&2
  exit 1
fi

PARENT="$(basename "$(dirname "${CAMPAIGN}")")"
VIDEO_ROOT="$(basename "$(dirname "$(dirname "${CAMPAIGN}")")")"
if [[ "${PARENT}" != "campaigns" || "${VIDEO_ROOT}" != "video" ]]; then
  echo "Error: preview only serves <project>/video/campaigns/<slug>." >&2
  exit 1
fi

command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required for the local preview server." >&2; exit 1; }

echo "Local preview. No Scenario credits."
echo "http://127.0.0.1:${PORT}/film/"
echo "Bound to 127.0.0.1. This campaign only. Not publication."
exec python3 -m http.server "${PORT}" --bind 127.0.0.1 --directory "${CAMPAIGN}"
