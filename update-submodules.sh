#!/usr/bin/env bash
set -euo pipefail

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

echo "Updating all submodules to latest upstream..."
git submodule update --remote --recursive

echo ""
git submodule status

if git diff --quiet; then
    echo "All submodules already up to date."
else
    echo ""
    echo "Submodules updated. Review changes with 'git diff' and commit when ready."
fi
