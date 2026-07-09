#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${AI_REPO}"

echo "Updating AI skills..."

npx skills update -p -y

echo ""
echo "Done."
echo ""
echo "Review the git diff before committing."