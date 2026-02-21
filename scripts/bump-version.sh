#!/usr/bin/env bash
set -euo pipefail

# Version bump script — bumps version in both plugin.json and marketplace.json
# Usage: ./scripts/bump-version.sh [patch|minor|major]
# Default: patch

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_JSON="$REPO_ROOT/plugins/geniro-claude-plugin/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

BUMP_TYPE="${1:-patch}"

if [[ "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
  echo "Usage: $0 [patch|minor|major]"
  echo "  patch  — bug fixes, wording improvements (default)"
  echo "  minor  — new features, significant behavior changes"
  echo "  major  — breaking changes, removed functionality"
  exit 1
fi

# Read current version
CURRENT=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])")

# Calculate new version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case "$BUMP_TYPE" in
  patch) PATCH=$((PATCH + 1)) ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "Bumping version: $CURRENT → $NEW_VERSION ($BUMP_TYPE)"

# Update plugin.json
python3 -c "
import json
with open('$PLUGIN_JSON', 'r') as f:
    data = json.load(f)
data['version'] = '$NEW_VERSION'
with open('$PLUGIN_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

# Update marketplace.json
python3 -c "
import json
with open('$MARKETPLACE_JSON', 'r') as f:
    data = json.load(f)
data['plugins'][0]['version'] = '$NEW_VERSION'
with open('$MARKETPLACE_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

echo "✓ Updated plugin.json → $NEW_VERSION"
echo "✓ Updated marketplace.json → $NEW_VERSION"
echo ""
echo "Ready to commit:"
echo "  git add -A && git commit -m \"chore: bump version to $NEW_VERSION\" && git push origin main"
