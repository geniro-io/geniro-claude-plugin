#!/usr/bin/env bash
set -euo pipefail

# Build script — packages the plugin into a .zip file for local upload
# Usage: ./scripts/build.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/geniro-claude-plugin"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
DIST_DIR="$REPO_ROOT/dist"

# Read version from plugin.json
if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required to parse plugin.json"
  exit 1
fi

VERSION=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])")
NAME=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['name'])")

echo "Building $NAME v$VERSION..."

# Create dist directory
mkdir -p "$DIST_DIR"

OUTPUT_FILE="$DIST_DIR/${NAME}-${VERSION}.zip"

# Remove old versioned builds (keep latest.zip for overwrite)
rm -f "$DIST_DIR/${NAME}-"*.zip

LATEST_FILE="$DIST_DIR/${NAME}-latest.zip"

# Package as zip archive
# The archive contains the plugin contents at the root level
cd "$PLUGIN_DIR"
zip -r "$OUTPUT_FILE" . \
  -x ".git/*" \
  -x "*.DS_Store" \
  -x "__pycache__/*" \
  -x "node_modules/*"

# Also create/overwrite a latest.zip (same path every time for easy UI re-upload)
cp "$OUTPUT_FILE" "$LATEST_FILE"

echo ""
echo "✓ Built: $OUTPUT_FILE"
echo "✓ Latest: $LATEST_FILE"
echo "  Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo ""
echo "Upload via Claude Desktop → Plugins → Upload local plugin"
echo "  Use '${NAME}-latest.zip' for quick updates (same path every time)"
