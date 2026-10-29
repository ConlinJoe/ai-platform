#!/usr/bin/env bash

# Copy, Tailwind, and stack-native architecture checks for application sources.
# Default: git-changed and untracked files. Does not scan vendor or history.

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "${SCRIPT_PATH}" ]]; then
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
fi
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCANNER="${SCRIPT_DIR}/lib/check_guardrails.py"
ARCH_SCANNER="${SCRIPT_DIR}/lib/check_architecture.py"

usage() {
  cat <<'EOF'
Usage: check-guardrails.sh [TARGET] [--all] [--since REF] [--files FILE ...]
       check-guardrails.sh [TARGET] --write-architecture-baseline

Scan application sources for:
  - em dashes in generated copy (—, &mdash;, &#8212;, &#x2014;)
  - arbitrary Tailwind utilities such as text-[...], mt-[...], max-w-[...]
  - high-confidence template architecture violations when that profile applies
  - utility-replaceable custom CSS when a file is in a Tailwind scope

The command reports which profiles and checks ran. It does not prove
architecture compliance. Lint, tests, and build do not prove it either.

Default scope is git-changed files (tracked diffs vs HEAD plus untracked
files). This is the agent DONE path for applicable copy, template,
component, and styling work.

Options:
  TARGET     Project root. Defaults like doctor.sh: argument, else $PWD
             when outside the AI Platform clone, else the clone itself.
  --all      Scan every in-scope file (does not inspect git). Avoid this
             as a default on existing projects; historical files may fail.
  --since R  Scan files changed since git ref R (plus untracked files).
  --files    Scan only these paths (relative to TARGET or absolute).
  --write-architecture-baseline
             Write docs/architecture-baseline.txt from committed findings.
             Does not accept a file subset and does not baseline uncommitted
             violations. Review the file before committing it.
  -h, --help Show this help.

Exceptions (do not weaken the rule globally):
  Same line or previous line:
    guardrail-allow-em-dash
    guardrail-allow-arbitrary
    guardrail-allow-architecture: <concrete limitation>
  First 30 lines of a file:
    guardrail-allow-file: em-dash
    guardrail-allow-file: arbitrary
    guardrail-allow-file: em-dash, arbitrary

guardrail-allow-file cannot exempt architecture findings.
A file-level or generic architecture marker does not suppress a finding.

Lint, tests, and build passing do not imply this check ran.
A failed check is not a green completion.
EOF
}

if [[ ! -f "${SCANNER}" ]]; then
  echo "Error: scanner not found at ${SCANNER}" >&2
  exit 2
fi
if [[ ! -f "${ARCH_SCANNER}" ]]; then
  echo "Error: architecture scanner not found at ${ARCH_SCANNER}" >&2
  exit 2
fi

TARGET=""
SCAN_ALL=0
SINCE=""
WRITE_BASELINE=0
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --all)
      SCAN_ALL=1
      shift
      ;;
    --write-architecture-baseline)
      WRITE_BASELINE=1
      shift
      ;;
    --since)
      if [[ $# -lt 2 ]]; then
        echo "Error: --since requires a git ref" >&2
        exit 2
      fi
      SINCE="$2"
      shift 2
      ;;
    --files)
      shift
      while [[ $# -gt 0 ]]; do
        FILES+=("$1")
        shift
      done
      ;;
    --)
      shift
      FILES+=("$@")
      break
      ;;
    -*)
      echo "Error: unknown option $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "${TARGET}" ]]; then
        echo "Error: unexpected extra argument: $1" >&2
        exit 2
      fi
      TARGET="$1"
      shift
      ;;
  esac
done

resolve_target() {
  if [[ -n "${TARGET}" ]]; then
    if [[ ! -d "${TARGET}" ]]; then
      echo "Error: Target path does not exist or is not a directory: ${TARGET}" >&2
      exit 2
    fi
    cd "${TARGET}" && pwd
    return
  fi

  if [[ "${PWD}" != "${AI_REPO}" ]]; then
    pwd
    return
  fi

  echo "${AI_REPO}"
}

PROJECT_ROOT="$(resolve_target)"

if [[ "${WRITE_BASELINE}" -eq 1 ]]; then
  if [[ "${SCAN_ALL}" -eq 1 || -n "${SINCE}" || ${#FILES[@]} -gt 0 ]]; then
    echo "Error: --write-architecture-baseline does not take --all, --since, or --files." >&2
    exit 2
  fi
  exec python3 "${ARCH_SCANNER}" "${PROJECT_ROOT}" --write-baseline
fi

run_scanners() {
  local copy_status=0
  local arch_status=0
  set +e
  if [[ "${1:-}" == "--all" ]]; then
    python3 "${SCANNER}" "${PROJECT_ROOT}" --all
    copy_status=$?
    python3 "${ARCH_SCANNER}" "${PROJECT_ROOT}" --all
    arch_status=$?
  elif [[ "$#" -eq 0 ]]; then
    python3 "${SCANNER}" "${PROJECT_ROOT}" --files
    copy_status=$?
    python3 "${ARCH_SCANNER}" "${PROJECT_ROOT}" --files
    arch_status=$?
  else
    python3 "${SCANNER}" "${PROJECT_ROOT}" --files "$@"
    copy_status=$?
    python3 "${ARCH_SCANNER}" "${PROJECT_ROOT}" --files "$@"
    arch_status=$?
  fi
  set -e
  if [[ "${copy_status}" -eq 2 || "${arch_status}" -eq 2 ]]; then
    return 2
  fi
  if [[ "${copy_status}" -ne 0 || "${arch_status}" -ne 0 ]]; then
    return 1
  fi
  return 0
}

collect_git_files() {
  local root="$1"
  local since_ref="${2:-}"

  if ! git -C "${root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: ${root} is not a git repository. Pass --files or --all." >&2
    return 2
  fi

  local -a names=()
  if [[ -n "${since_ref}" ]]; then
    if ! git -C "${root}" rev-parse --verify "${since_ref}" >/dev/null 2>&1; then
      echo "Error: git ref not found: ${since_ref}" >&2
      return 2
    fi
    while IFS= read -r name; do
      [[ -n "${name}" ]] && names+=("${name}")
    done < <(git -C "${root}" diff --name-only --diff-filter=ACMR "${since_ref}" HEAD)
  else
    while IFS= read -r name; do
      [[ -n "${name}" ]] && names+=("${name}")
    done < <(git -C "${root}" diff --name-only --diff-filter=ACMR HEAD)
  fi

  while IFS= read -r name; do
    [[ -n "${name}" ]] && names+=("${name}")
  done < <(git -C "${root}" ls-files --others --exclude-standard)

  if [[ ${#names[@]} -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${names[@]}" | awk 'NF && !seen[$0]++'
}

if [[ ${#FILES[@]} -gt 0 ]]; then
  run_scanners "${FILES[@]}"
  exit $?
fi

if [[ "${SCAN_ALL}" -eq 1 ]]; then
  run_scanners --all
  exit $?
fi

set +e
file_list="$(collect_git_files "${PROJECT_ROOT}" "${SINCE}")"
status=$?
set -e
if [[ "${status}" -ne 0 ]]; then
  exit "${status}"
fi

CHANGED=()
if [[ -n "${file_list}" ]]; then
  while IFS= read -r name; do
    [[ -n "${name}" ]] && CHANGED+=("${name}")
  done <<< "${file_list}"
fi

if [[ ${#CHANGED[@]} -eq 0 ]]; then
  run_scanners
  exit $?
fi

run_scanners "${CHANGED[@]}"
exit $?
