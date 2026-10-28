#!/usr/bin/env bash
# Optional video-production capability. Source this file; do not execute it.
# Requires project-capabilities.sh to be sourced first.
# These helpers do not render, upload, publish, or spend generation credits.

VIDEO_MARKER="ai-platform-video-production"

video_studio_file() {
  echo "${1}/video/studio.json"
}

video_is_harness_managed() {
  local file
  file="$(video_studio_file "$1")"
  [[ -f "${file}" ]] || return 1
  python3 - "${file}" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
except (OSError, json.JSONDecodeError):
    sys.exit(1)
sys.exit(0 if data.get("marker") == "ai-platform-video-production" else 1)
PY
}

video_mode_of() {
  local file
  file="$(video_studio_file "$1")"
  python3 - "${file}" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data.get("mode") or "integrated")
PY
}

video_is_application_project() {
  project_is_laravel "$1" && return 0
  project_is_roots_radicle "$1" && return 0
  project_is_bedrock "$1" && return 0
  project_is_conventional_wordpress "$1" && return 0
  return 1
}

video_write_studio_json() {
  local dir="$1"
  local mode="$2"
  python3 - "${dir}/video/studio.json" "${mode}" "${VIDEO_MARKER}" <<'PY'
import json, sys
path, mode, marker = sys.argv[1:]
payload = {
    "capability": "video-production",
    "engine": "harness",
    "mode": mode,
    "marker": marker,
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
}

video_ensure_gitignore() {
  local gitignore="${1}/.gitignore"
  if [[ ! -f "${gitignore}" ]]; then
    touch "${gitignore}"
  fi
  if grep -q 'video-production-ignore-start' "${gitignore}"; then
    echo "Video render gitignore already present"
    return 0
  fi
  cat >> "${gitignore}" <<'EOF'

# video-production-ignore-start
/video/.runtime/
/video/campaigns/*/renders/
# video-production-ignore-end
EOF
  echo "Added video render paths to ${gitignore}"
}

video_link_into() {
  local source="$1"
  local dest="$2"
  local label="$3"
  if [[ -L "${dest}" ]]; then
    ln -sfn "${source}" "${dest}"
    echo "Updated link: ${label}"
    return 0
  fi
  if [[ -e "${dest}" ]]; then
    echo "Left existing ${label} in place"
    return 0
  fi
  mkdir -p "$(dirname "${dest}")"
  ln -s "${source}" "${dest}"
  echo "Linked: ${label}"
}

video_link_capability() {
  local dir="$1"
  mkdir -p "${dir}/.agents/skills" "${dir}/.claude/skills" "${dir}/.grok/skills" "${dir}/video/bin"
  video_link_into \
    "${AI_REPO}/.agents/skills/video-production" \
    "${dir}/.agents/skills/video-production" \
    "video-production skill"
  video_link_into \
    "../../.agents/skills/video-production" \
    "${dir}/.claude/skills/video-production" \
    "Claude video-production skill"
  video_link_into \
    "../../.agents/skills/video-production" \
    "${dir}/.grok/skills/video-production" \
    "Grok video-production skill"
  video_link_into \
    "${AI_REPO}/scripts/video-render.sh" \
    "${dir}/video/bin/render" \
    "video render command"
  video_link_into \
    "${AI_REPO}/scripts/video-new-campaign.sh" \
    "${dir}/video/bin/new-campaign" \
    "video new-campaign command"
}

video_copy_record() {
  local dir="$1"
  local dest="${dir}/docs/contracts/features/video-production.md"
  if [[ -e "${dest}" ]]; then
    echo "Project video record already present"
    return 0
  fi
  if [[ ! -f "${dir}/docs/README.md" ]]; then
    echo "No docs/README.md yet. Skipping the project video record."
    return 0
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${AI_REPO}/templates/video/project-record.md" "${dest}"
  echo "Added project video record: ${dest}"
  python3 - "${dir}/docs/README.md" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
row = "| `contracts/features/video-production.md` | feature | active | This project's video campaigns, assets, and approvals |"
if "contracts/features/video-production.md" in text:
    sys.exit(0)
needle = "| `contracts/features/public-submissions.md` |"
if needle not in text:
    print("Register contracts/features/video-production.md in docs/README.md")
    sys.exit(0)
lines = text.splitlines()
out = []
for line in lines:
    out.append(line)
    if line.startswith(needle):
        out.append(row)
path.write_text("\n".join(out) + ("\n" if text.endswith("\n") else ""), encoding="utf-8")
print("Registered the video record in docs/README.md")
PY
}

video_install() {
  local dir="$1"
  local mode="${2:-integrated}"
  if [[ "${dir}" == "${AI_REPO}" ]]; then
    echo "Error: refusing to install video production into the AI Platform repository." >&2
    return 1
  fi
  if [[ "${mode}" != "integrated" && "${mode}" != "studio" ]]; then
    echo "Error: video mode must be integrated or studio." >&2
    return 1
  fi
  if [[ "${mode}" == "studio" ]] && video_is_application_project "${dir}"; then
    echo "Error: this directory is an application project. Install integrated mode instead of a video studio." >&2
    return 1
  fi
  if video_is_harness_managed "${dir}"; then
    echo "Video production already present ($(video_mode_of "${dir}")). Refreshing links."
    video_link_capability "${dir}"
    video_ensure_gitignore "${dir}"
    video_copy_record "${dir}"
    return 0
  fi
  if [[ -e "${dir}/video" ]]; then
    echo "Error: ${dir}/video already exists without the harness marker. Left it untouched." >&2
    return 2
  fi
  mkdir -p "${dir}/video/campaigns" "${dir}/video/bin"
  touch "${dir}/video/campaigns/.gitkeep"
  video_write_studio_json "${dir}" "${mode}"
  if [[ ! -f "${dir}/video/README.md" ]]; then
    cp "${AI_REPO}/templates/video/workspace-readme.md" "${dir}/video/README.md"
  fi
  video_link_capability "${dir}"
  video_ensure_gitignore "${dir}"
  video_copy_record "${dir}"
  echo "Video production installed (${mode})."
  echo "Local rendering does not spend Scenario credits."
  echo "Installing this capability does not authorize publication or paid generation."
  echo "Create a campaign with: ${AI_REPO}/scripts/video-new-campaign.sh ${dir} <slug> <template>"
  return 0
}

video_doctor_report() {
  local dir="$1"
  echo "--- Video production ---"
  echo ""
  if video_is_harness_managed "${dir}"; then
    ok "Video production installed ($(video_mode_of "${dir}"))"
    if [[ -L "${dir}/.agents/skills/video-production" || -d "${dir}/.agents/skills/video-production" ]]; then
      ok "video-production skill is available to this project"
    else
      warn "video-production skill link is missing. Re-run scripts/install-video-production.sh"
    fi
    ok "Local rendering does not spend Scenario credits"
    return 0
  fi
  if [[ -d "${dir}/video" ]]; then
    warn "video/ exists without the harness marker. Left untouched."
    return 0
  fi
  ok "Video production not installed (optional capability)"
}
