#!/usr/bin/env bash
set -euo pipefail

# Build script — packages the plugin into a .zip file for local upload
# Usage: ./scripts/build.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/geniro-claude-plugin"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
DIST_DIR="$REPO_ROOT/dist"

# Read version from marketplace.json (single source of truth)
if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required to parse marketplace.json"
  exit 1
fi

VERSION=$(python3 -c "import json; print(json.load(open('$MARKETPLACE_JSON'))['plugins'][0]['version'])")
NAME=$(python3 -c "import json; print(json.load(open('$MARKETPLACE_JSON'))['plugins'][0]['name'])")

echo "Building $NAME v$VERSION..."

# Create dist directory
mkdir -p "$DIST_DIR"

OUTPUT_FILE="$DIST_DIR/${NAME}-${VERSION}.zip"

# Remove old builds
rm -f "$DIST_DIR/${NAME}-"*.zip

# Package as zip archive
# The archive contains the plugin contents at the root level
cd "$PLUGIN_DIR"
zip -r "$OUTPUT_FILE" . \
  -x ".git/*" \
  -x "*.DS_Store" \
  -x "__pycache__/*" \
  -x "node_modules/*"

echo ""
echo "✓ Built: $OUTPUT_FILE"
echo "  Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo ""
echo "Upload via Claude Desktop → Plugins → Upload local plugin"
