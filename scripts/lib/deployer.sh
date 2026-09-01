#!/usr/bin/env bash
# Shared Deployer capability helpers for bootstrap, doctor, and
# install-deployer.sh. Source this file; do not execute it.
# Never invoke Deployer, SSH, or a remote deploy from these helpers.

DEPLOYER_PACKAGE="deployer/deployer"
DEPLOYER_PACKAGE_CONSTRAINT="^8.0"
DEPLOYER_STACK_MARKER="AI_PLATFORM_DEPLOYER_STACK"
DEPLOYER_PROMPT="Install Deployer deployment stack? [y/N] "

deployer_marker_line() {
  local profile="$1"
  echo "${DEPLOYER_STACK_MARKER}=${profile}"
}

deployer_has_root_recipe() {
  local dir="$1"
  [[ -f "${dir}/deploy.php" ]] && return 0
  [[ -f "${dir}/deploy.yaml" ]] && return 0
  [[ -f "${dir}/deploy.yml" ]] && return 0
  [[ -f "${dir}/deploy.maml" ]] && return 0
  return 1
}

deployer_is_harness_managed() {
  local dir="$1"
  [[ -f "${dir}/deploy.php" ]] || return 1
  grep -qE "${DEPLOYER_STACK_MARKER}=" "${dir}/deploy.php"
}

deployer_harness_profile_from_recipe() {
  local dir="$1"
  [[ -f "${dir}/deploy.php" ]] || return 1
  sed -n "s/.*${DEPLOYER_STACK_MARKER}=\\([a-z]*\\).*/\\1/p" "${dir}/deploy.php" | head -n 1
}

deployer_foreign_present() {
  local dir="$1"
  if deployer_has_root_recipe "${dir}" && ! deployer_is_harness_managed "${dir}"; then
    return 0
  fi
  return 1
}

deployer_conflict_paths() {
  local dir="$1"
  local path
  for path in deploy.php deploy.yaml deploy.yml deploy.maml; do
    if [[ -e "${dir}/${path}" ]] && ! deployer_is_harness_managed "${dir}"; then
      echo "${path}"
    fi
  done
}

deployer_detect_sage_theme_path() {
  local dir="$1"
  local theme
  if [[ -d "${dir}/web/app/themes" ]]; then
    for theme in "${dir}/web/app/themes"/*; do
      [[ -d "${theme}" ]] || continue
      if [[ -f "${theme}/package.json" ]]; then
        echo "web/app/themes/$(basename "${theme}")"
        return 0
      fi
    done
  fi
  echo "web/app/themes/CHANGE_ME"
}

# Detection order: Laravel, Roots/Sage/Radicle, Bedrock, conventional
# WordPress. Do not infer GitHub Actions, Forge, Envoyer, or other
# deployment strategies.
deployer_supported_profile() {
  local dir="$1"

  if project_is_laravel "${dir}"; then
    echo "laravel"
    return 0
  fi

  if project_is_roots_radicle "${dir}"; then
    echo "roots"
    return 0
  fi

  if project_is_bedrock "${dir}"; then
    echo "bedrock"
    return 0
  fi

  if project_is_conventional_wordpress "${dir}"; then
    echo "wordpress"
    return 0
  fi

  echo "unsupported"
  return 0
}

deployer_gitignore_has_runtime() {
  local gitignore="$1/.gitignore"
  [[ -f "${gitignore}" ]] || return 1
  grep -qE '(^|/)\.dep/?$' "${gitignore}" || return 1
  grep -qE '(^|/)deploy/hosts\.yaml$' "${gitignore}" || return 1
  return 0
}

deployer_ensure_gitignore() {
  local dir="$1"
  local gitignore="${dir}/.gitignore"

  if [[ ! -f "${gitignore}" ]]; then
    touch "${gitignore}"
  fi

  local added=0
  if ! grep -qE '(^|/)\.dep/?$' "${gitignore}"; then
    printf '\n# Deployer runtime state\n/.dep/\n' >> "${gitignore}"
    added=1
  fi
  if ! grep -qE '(^|/)deploy/hosts\.yaml$' "${gitignore}"; then
    if [[ "${added}" -eq 0 ]]; then
      printf '\n# Deployer host inventory (secrets live here)\n' >> "${gitignore}"
    fi
    printf '/deploy/hosts.yaml\n' >> "${gitignore}"
    added=1
  fi

  if [[ "${added}" -eq 1 ]]; then
    echo "Ensured Deployer gitignore entries in ${gitignore}"
  else
    echo "Deployer gitignore entries already present"
  fi
}

deployer_ensure_composer_dependency() {
  local dir="$1"
  local composer="${dir}/composer.json"

  if composer_has_package "${dir}" "${DEPLOYER_PACKAGE}"; then
    echo "Composer already declares ${DEPLOYER_PACKAGE}; leaving the existing constraint in place."
    return 0
  fi

  if [[ ! -f "${composer}" ]]; then
    cat > "${composer}" <<EOF
{
    "require-dev": {
        "${DEPLOYER_PACKAGE}": "${DEPLOYER_PACKAGE_CONSTRAINT}"
    }
}
EOF
    echo "Created ${composer} with ${DEPLOYER_PACKAGE} ${DEPLOYER_PACKAGE_CONSTRAINT} (require-dev)."
    echo "Run composer install later. This installer does not install packages or deploy."
    return 0
  fi

  python3 - "${composer}" "${DEPLOYER_PACKAGE}" "${DEPLOYER_PACKAGE_CONSTRAINT}" <<'PY'
import json
import sys

path, package, constraint = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

for key in ("require", "require-dev"):
    if package in data.get(key, {}):
        sys.exit(0)

data.setdefault("require-dev", {})[package] = constraint
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=4)
    handle.write("\n")
PY

  echo "Declared ${DEPLOYER_PACKAGE} ${DEPLOYER_PACKAGE_CONSTRAINT} in composer.json require-dev."
  echo "Run composer install later. This installer does not install packages or deploy."
}

deployer_profile_notes() {
  local profile="$1"
  case "${profile}" in
    laravel)
      cat <<'EOF'
Laravel profile notes:

- Document root: `public` (web server should serve `current/public`)
- Shared: `.env`, `storage`
- Writable: `bootstrap/cache`, `storage`
- Native Deployer Laravel recipe runs `artisan:migrate` on deploy
- npm/Vite is not in the default deploy flow (`assets:build` exists but
  is not hooked)
- PHP 8.3+ is required by Deployer 8
EOF
      ;;
    roots)
      cat <<'EOF'
Bedrock/Sage (Roots) profile notes:

- Document root: `web` (web server should serve `current/web`)
- Shared: `.env`, `web/app/uploads`
- Writable: `web/app/uploads`
- Composer vendors install on the server
- Sage theme assets build on the server in `theme_path` when that path
  is not CHANGE_ME
- Set `theme_path` in `deploy.php` or override it in `deploy/hosts.yaml`
- PHP 8.3+ is required by Deployer 8; Node is required for the Sage build
EOF
      ;;
    bedrock)
      cat <<'EOF'
Bedrock profile notes:

- Document root: `web` (web server should serve `current/web`)
- Shared: `.env`, `web/app/uploads`
- Writable: `web/app/uploads`
- Composer vendors install on the server
- No Sage theme build is included
- PHP 8.3+ is required by Deployer 8
EOF
      ;;
    wordpress)
      cat <<'EOF'
Conventional WordPress profile notes:

- Document root: the WordPress root (`current/`)
- Shared: `wp-config.php`, `wp-content/uploads`
- Writable: `wp-content/uploads`
- Keep `wp-config.php` out of the git repository
- PHP 8.3+ is required by Deployer 8
EOF
      ;;
    *)
      echo "No profile-specific notes."
      ;;
  esac
}

deployer_write_project_docs() {
  local dir="$1"
  local profile="$2"
  local dest="${dir}/docs/contracts/features/deployment.md"
  local template="${AI_REPO}/templates/deployer/deployment.md"

  if [[ -f "${dest}" ]]; then
    echo "Project-owned deployment document already present: ${dest}"
    echo "Left in place. Reconcile with the harness reference if needed:"
    echo "  ${AI_REPO}/docs/contracts/features/deployer.md"
    return 0
  fi

  if [[ -f "${dir}/docs/deployment.md" ]]; then
    echo "Existing project-owned docs/deployment.md preserved."
    echo "Writing harness notes to ${dest} instead. Reconcile the two documents."
  fi

  if [[ ! -f "${template}" ]]; then
    echo "Warning: deployment doc template missing: ${template}" >&2
    return 0
  fi

  mkdir -p "$(dirname "${dest}")"
  local notes tmp
  notes="$(deployer_profile_notes "${profile}")"
  tmp="$(mktemp)"
  python3 - "${template}" "${tmp}" "${profile}" "${notes}" "$(date +%Y-%m-%d)" <<'PY'
import sys
from pathlib import Path

src, dest, profile, notes, reviewed = sys.argv[1:6]
text = Path(src).read_text(encoding="utf-8")
text = text.replace("{{PROFILE}}", profile)
text = text.replace("{{PROFILE_NOTES}}", notes)
text = text.replace("{{LAST_REVIEWED}}", reviewed)
Path(dest).write_text(text, encoding="utf-8")
PY
  mv "${tmp}" "${dest}"
  echo "Wrote project deployment notes: ${dest}"
}

deployer_copy_recipe() {
  local dir="$1"
  local profile="$2"
  local src="${AI_REPO}/templates/deployer/${profile}/deploy.php"
  local dest="${dir}/deploy.php"

  if [[ ! -f "${src}" ]]; then
    echo "Error: missing Deployer recipe template: ${src}" >&2
    return 1
  fi

  if [[ "${profile}" == "roots" ]]; then
    local theme_path
    theme_path="$(deployer_detect_sage_theme_path "${dir}")"
    python3 - "${src}" "${dest}" "${theme_path}" <<'PY'
from pathlib import Path
import sys
src, dest, theme = sys.argv[1], sys.argv[2], sys.argv[3]
text = Path(src).read_text(encoding="utf-8").replace("{{THEME_PATH}}", theme)
Path(dest).write_text(text, encoding="utf-8")
PY
    echo "Installed roots Deployer recipe with theme_path=${theme_path}"
  else
    cp "${src}" "${dest}"
    echo "Installed ${profile} Deployer recipe: ${dest}"
  fi
}

deployer_copy_hosts() {
  local dir="$1"
  local example_src="${AI_REPO}/templates/deployer/hosts.yaml.example"
  local example_dest="${dir}/deploy/hosts.yaml.example"
  local hosts_dest="${dir}/deploy/hosts.yaml"

  mkdir -p "${dir}/deploy"

  if [[ ! -f "${example_src}" ]]; then
    echo "Error: missing hosts example: ${example_src}" >&2
    return 1
  fi

  if [[ -f "${example_dest}" ]]; then
    echo "Already present: ${example_dest}"
  else
    cp "${example_src}" "${example_dest}"
    echo "Wrote ${example_dest}"
  fi

  if [[ -f "${hosts_dest}" ]]; then
    echo "Existing ${hosts_dest} left in place."
  else
    cp "${example_src}" "${hosts_dest}"
    echo "Wrote ${hosts_dest} from the example. Fill in CHANGE_ME values."
    echo "This file is gitignored. Configuring it does not authorize deployment."
  fi
}

deployer_health() {
  local dir="$1"

  if deployer_foreign_present "${dir}"; then
    echo "foreign"
    return 0
  fi

  if ! deployer_is_harness_managed "${dir}"; then
    echo "absent"
    return 0
  fi

  local profile
  profile="$(deployer_harness_profile_from_recipe "${dir}")"
  if [[ -z "${profile}" ]]; then
    echo "partial"
    return 0
  fi

  if [[ ! -f "${dir}/deploy/hosts.yaml.example" ]]; then
    echo "partial"
    return 0
  fi

  if ! composer_has_package "${dir}" "${DEPLOYER_PACKAGE}"; then
    echo "partial"
    return 0
  fi

  if ! deployer_gitignore_has_runtime "${dir}"; then
    echo "partial"
    return 0
  fi

  echo "harness_ok"
}

deployer_install() {
  local dir="$1"
  local requested_profile="${2:-}"

  if deployer_is_harness_managed "${dir}"; then
    echo "Harness-managed Deployer stack already present. Leaving it in place."
    deployer_ensure_gitignore "${dir}"
    local existing_profile
    existing_profile="$(deployer_harness_profile_from_recipe "${dir}")"
    deployer_write_project_docs "${dir}" "${existing_profile:-unknown}"
    echo "Idempotent: existing recipe and host inventory were not overwritten."
    echo "Server configuration is still required before any deployment."
    echo "Installing Deployer does not authorize deployment."
    return 0
  fi

  local conflicts
  conflicts="$(deployer_conflict_paths "${dir}")"
  if [[ -n "${conflicts}" ]]; then
    echo "Existing Deployer configuration detected (${conflicts//$'\n'/, })." >&2
    echo "Stopping Deployer installation. Existing files were not overwritten." >&2
    echo "Current-First: the project's existing deployment strategy is preserved." >&2
    echo "Harness reference: ${AI_REPO}/docs/contracts/features/deployer.md" >&2
    return 2
  fi

  local profile
  profile="$(deployer_supported_profile "${dir}")"
  if [[ -n "${requested_profile}" ]]; then
    profile="${requested_profile}"
  fi

  if [[ "${profile}" == "unsupported" ]]; then
    echo "No supported Deployer profile detected (Laravel, Bedrock/Sage, Bedrock, or conventional WordPress)." >&2
    echo "Not installing Deployer. The rest of bootstrap is unaffected." >&2
    return 3
  fi

  echo "Installing harness-managed Deployer stack (profile: ${profile})."
  echo "This does not configure a server and does not deploy."

  deployer_copy_recipe "${dir}" "${profile}"
  deployer_copy_hosts "${dir}"
  deployer_ensure_composer_dependency "${dir}"
  deployer_ensure_gitignore "${dir}"
  deployer_write_project_docs "${dir}" "${profile}"

  echo ""
  echo "Deployer foundation installed. Next: fill deploy/hosts.yaml, run"
  echo "composer install, then follow docs/contracts/features/deployment.md."
  echo "Canonical reference: ${AI_REPO}/docs/contracts/features/deployer.md"
  echo "Server configuration is still required."
  echo "Installing Deployer does not authorize deployment."
  return 0
}

deployer_offer_or_install() {
  local dir="$1"
  local mode="${2:-}"

  if deployer_is_harness_managed "${dir}"; then
    echo ""
    echo "--- Deployer ---"
    echo "Harness-managed Deployer stack already present. Leaving it in place."
    return 0
  fi

  local conflicts
  conflicts="$(deployer_conflict_paths "${dir}")"
  if [[ -n "${conflicts}" ]]; then
    echo ""
    echo "--- Deployer ---"
    echo "Existing Deployer configuration detected (${conflicts//$'\n'/, })."
    echo "Leaving it in place (Current-First). Not installing the harness-managed stack."
    return 0
  fi

  local profile
  profile="$(deployer_supported_profile "${dir}")"

  local should_install=0
  case "${mode}" in
    with)
      should_install=1
      ;;
    without)
      echo ""
      echo "--- Deployer ---"
      echo "Skipping Deployer (--without-deployer)."
      return 0
      ;;
    *)
      if [[ "${AI_BOOTSTRAP_NONINTERACTIVE:-}" == "1" ]]; then
        echo ""
        echo "--- Deployer ---"
        echo "Skipping Deployer (non-interactive; pass --with-deployer to install)."
        return 0
      fi

      local confirm=""
      echo ""
      echo "--- Deployer ---"
      if [[ "${profile}" == "unsupported" ]]; then
        echo "No supported Deployer profile detected for this project."
        echo "Skipping Deployer. Install later with scripts/install-deployer.sh if the stack becomes supported."
        return 0
      fi

      if [[ -t 0 ]]; then
        read -r -p "${DEPLOYER_PROMPT}" confirm || confirm=""
      else
        printf '%s' "${DEPLOYER_PROMPT}" >&2
        read -r confirm || confirm=""
        echo >&2
      fi

      if [[ "${confirm}" =~ ^[Yy]$ ]]; then
        should_install=1
      else
        echo "Skipping Deployer. You can add it later with:"
        echo "  ${AI_REPO}/scripts/install-deployer.sh ${dir}"
        echo "Deployer is optional. Absence is valid."
        return 0
      fi
      ;;
  esac

  if [[ "${should_install}" -eq 1 ]]; then
    echo ""
    echo "--- Deployer ---"
    local status=0
    deployer_install "${dir}" || status=$?
    if [[ "${status}" -eq 3 && "${mode}" == "with" ]]; then
      echo " --with-deployer was set, but no supported profile was detected." >&2
    fi
    return 0
  fi
}

deployer_doctor_report() {
  local dir="$1"
  local health
  health="$(deployer_health "${dir}")"

  echo "--- Deployer ---"
  echo ""

  case "${health}" in
    absent)
      ok "Deployer not installed (optional capability)"
      ;;
    harness_ok)
      ok "Harness-managed Deployer stack is present"
      local profile
      profile="$(deployer_harness_profile_from_recipe "${dir}")"
      ok "Deployer profile: ${profile}"
      if [[ -f "${dir}/deploy/hosts.yaml" ]]; then
        ok "deploy/hosts.yaml present (gitignored; not validated for connectivity)"
      else
        ok "deploy/hosts.yaml not configured yet (expected until the developer fills it)"
      fi
      if [[ -x "${dir}/vendor/bin/dep" ]]; then
        ok "vendor/bin/dep present"
      else
        warn "vendor/bin/dep missing (run composer install; not required for a healthy harness install)"
      fi
      ;;
    partial)
      fail "Harness-managed Deployer stack is incomplete"
      if ! deployer_is_harness_managed "${dir}"; then
        echo "        deploy.php is missing the harness marker."
      fi
      if [[ ! -f "${dir}/deploy/hosts.yaml.example" ]]; then
        echo "        Missing deploy/hosts.yaml.example."
      fi
      if ! composer_has_package "${dir}" "${DEPLOYER_PACKAGE}"; then
        echo "        ${DEPLOYER_PACKAGE} is not declared in composer.json."
      fi
      if ! deployer_gitignore_has_runtime "${dir}"; then
        echo "        .gitignore is missing /.dep/ or /deploy/hosts.yaml."
      fi
      echo "        Re-run ${AI_REPO}/scripts/install-deployer.sh ${dir} after resolving the gap,"
      echo "        or restore the missing files by hand. Do not deploy until the stack is healthy."
      ;;
    foreign)
      ok "Existing non-harness Deployer configuration preserved"
      echo "      Doctor does not require it to match harness templates."
      ;;
    *)
      warn "Deployer diagnosis unknown: ${health}"
      ;;
  esac

  echo ""
}
