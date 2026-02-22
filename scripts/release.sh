#!/usr/bin/env bash
set -euo pipefail

# Release script — bumps version, builds .zip file, commits, and pushes
# Usage: ./scripts/release.sh [patch|minor|major] "commit message"
# Example: ./scripts/release.sh minor "feat: add Playwright visual verification"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUMP_TYPE="${1:-patch}"
COMMIT_MSG="${2:-}"

if [[ -z "$COMMIT_MSG" ]]; then
  echo "Usage: $0 [patch|minor|major] \"commit message\""
  echo ""
  echo "Examples:"
  echo "  $0 patch \"fix: correct orchestrator tool list\""
  echo "  $0 minor \"feat: add Playwright visual verification to web agent\""
  echo "  $0 major \"breaking: restructure plugin to marketplace format\""
  exit 1
fi

echo "=== Geniro Claude Plugin Release ==="
echo ""

# Step 1: Bump version
echo "--- Step 1: Bump version ($BUMP_TYPE) ---"
"$REPO_ROOT/scripts/bump-version.sh" "$BUMP_TYPE"
echo ""

# Step 2: Build .zip file
echo "--- Step 2: Build .zip file ---"
"$REPO_ROOT/scripts/build.sh"
echo ""

# Step 3: Commit and push
echo "--- Step 3: Commit and push ---"

# Read the new version from marketplace.json (single source of truth)
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
NEW_VERSION=$(python3 -c "import json; print(json.load(open('$MARKETPLACE_JSON'))['plugins'][0]['version'])")

cd "$REPO_ROOT"
git add -A
git commit -m "$COMMIT_MSG (v$NEW_VERSION)"
git push origin main

echo ""
echo "=== Released v$NEW_VERSION ==="
echo "  Commit: $COMMIT_MSG (v$NEW_VERSION)"
echo "  Plugin: dist/geniro-claude-marketplace-$NEW_VERSION.zip"
echo ""
echo "Upload the .zip file via Claude Desktop → Plugins → Upload local plugin"
