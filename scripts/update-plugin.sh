#!/usr/bin/env bash
set -euo pipefail

# Update geniro-claude-plugin in Claude CLI — uninstalls, reinstalls, and verifies version
# Usage: ./scripts/update-plugin.sh

PLUGIN_NAME="geniro-claude-plugin"
MARKETPLACE_NAME="geniro-claude-marketplace"
FULL_ID="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
INSTALLED_PLUGINS_FILE="$HOME/.claude/plugins/installed_plugins.json"

# --- helpers ---
get_installed_version() {
  if [[ ! -f "$INSTALLED_PLUGINS_FILE" ]]; then
    echo ""
    return
  fi
  python3 -c "
import json, sys
data = json.load(open('$INSTALLED_PLUGINS_FILE'))
entries = data.get('plugins', {}).get('$FULL_ID', [])
if entries:
    print(entries[0].get('version', ''))
else:
    print('')
" 2>/dev/null || echo ""
}

get_marketplace_version() {
  REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
  if [[ -f "$MARKETPLACE_JSON" ]]; then
    python3 -c "import json; print(json.load(open('$MARKETPLACE_JSON'))['plugins'][0]['version'])" 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# --- main ---
echo "=== Geniro Claude Plugin Updater ==="
echo ""

# Step 1: Record current version
OLD_VERSION=$(get_installed_version)
if [[ -n "$OLD_VERSION" ]]; then
  echo "Current installed version: $OLD_VERSION"
else
  echo "Plugin not currently installed."
fi

LATEST_VERSION=$(get_marketplace_version)
echo "Latest version in marketplace: $LATEST_VERSION"
echo ""

# Step 2: Uninstall
echo "--- Uninstalling $PLUGIN_NAME ---"
if claude plugin uninstall "$PLUGIN_NAME" 2>&1; then
  echo "Uninstalled."
else
  echo "Uninstall failed or plugin was not installed — continuing anyway."
fi
echo ""

# Step 3: Update marketplace to fetch latest metadata
echo "--- Updating marketplace ---"
claude plugin marketplace update "$MARKETPLACE_NAME" 2>&1 || true
echo ""

# Step 4: Reinstall
echo "--- Installing $PLUGIN_NAME ---"
if ! claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}" 2>&1; then
  echo ""
  echo "ERROR: Installation failed!"
  exit 1
fi
echo ""

# Step 5: Verify
NEW_VERSION=$(get_installed_version)
echo "=== Result ==="
echo ""

if [[ -z "$NEW_VERSION" ]]; then
  echo "ERROR: Plugin does not appear in installed list after install."
  exit 1
fi

echo "Installed version: $NEW_VERSION"

if [[ "$NEW_VERSION" == "$LATEST_VERSION" ]]; then
  echo "Version matches marketplace latest ($LATEST_VERSION)."
else
  echo "WARNING: Installed version ($NEW_VERSION) does not match marketplace latest ($LATEST_VERSION)."
  echo "The marketplace cache may be stale. Try running:"
  echo "  claude plugin marketplace update $MARKETPLACE_NAME"
  echo "and re-run this script."
fi

echo ""
if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
  echo "No update — version unchanged ($NEW_VERSION)."
else
  if [[ -n "$OLD_VERSION" ]]; then
    echo "UPDATED: $OLD_VERSION -> $NEW_VERSION"
  else
    echo "INSTALLED: $NEW_VERSION (fresh install)"
  fi
fi

echo ""
echo "Restart Claude Code for changes to take effect."
