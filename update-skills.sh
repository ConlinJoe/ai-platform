#!/bin/bash

set -e

echo "Updating AI skills..."

npx skills update -p -y

echo ""
echo "Done."
echo ""
echo "Review the git diff before committing."