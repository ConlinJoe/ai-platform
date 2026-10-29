#!/usr/bin/env bash

# Scan a checkout against an explicit base revision.
# Uses the harness checkout that contains this script. Does not follow a
# project's scripts/check-guardrails.sh symlink, which is an absolute path
# to a developer machine.

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "${SCRIPT_PATH}" ]]; then
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
fi
DEFAULT_HARNESS="$(cd "$(dirname "${SCRIPT_PATH}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: ci-guardrails.sh PROJECT_ROOT BASE_SHA [HARNESS_ROOT]

Scan PROJECT_ROOT for changes between BASE_SHA and HEAD using the harness
checkers in HARNESS_ROOT. HARNESS_ROOT defaults to the repository that
contains this script.

A missing or all-zero base revision exits 2. The command does not fall
back to an empty worktree diff, which would skip a pull request's
committed changes on a clean checkout.

The same checkers as scripts/check-guardrails.sh run. A passing result
does not prove architecture compliance. This command does not write
docs/architecture-baseline.txt.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

PROJECT="${1:-}"
BASE="${2:-}"
HARNESS="${3:-${DEFAULT_HARNESS}}"

if [[ -z "${PROJECT}" || -z "${BASE}" ]]; then
  usage >&2
  exit 2
fi

if [[ ! -d "${PROJECT}" ]]; then
  echo "Error: project root is not a directory: ${PROJECT}" >&2
  exit 2
fi
if [[ ! -f "${HARNESS}/scripts/check-guardrails.sh" || ! -f "${HARNESS}/scripts/lib/check_architecture.py" ]]; then
  echo "Error: harness root does not contain the guardrail checkers: ${HARNESS}" >&2
  echo "CI must check out the harness repository. Do not use the project's absolute symlink." >&2
  exit 2
fi

ZERO="0000000000000000000000000000000000000000"
if [[ "${BASE}" == "${ZERO}" ]]; then
  echo "Error: no base revision. Refusing to report success for an empty checkout diff." >&2
  echo "The scan did not run, so changed files were not skipped." >&2
  exit 2
fi

if ! git -C "${PROJECT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: ${PROJECT} is not a git repository." >&2
  exit 2
fi

if ! RESOLVED="$(git -C "${PROJECT}" rev-parse --verify "${BASE}^{commit}" 2>/dev/null)"; then
  echo "Error: base revision ${BASE} is not in this checkout. Fetch the base before scanning." >&2
  echo "The scan did not run, so changed files were not skipped." >&2
  exit 2
fi

echo "CI guardrails"
echo "Project: ${PROJECT}"
echo "Harness: ${HARNESS}"
echo "Range: ${RESOLVED}..HEAD"
CHANGED_COUNT="$(git -C "${PROJECT}" diff --name-only --diff-filter=ACMR "${RESOLVED}" HEAD | awk 'NF' | wc -l | tr -d ' ')"
echo "Changed paths in range: ${CHANGED_COUNT}"
echo ""

exec "${HARNESS}/scripts/check-guardrails.sh" "${PROJECT}" --since "${RESOLVED}"
