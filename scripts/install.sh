#!/usr/bin/env bash
# Install the KeyDeck Spoon into ~/.hammerspoon/Spoons and wire it into your
# init.lua. Safe and idempotent: your own config is never overwritten — the
# loader is appended once (marker-guarded) and init.lua is backed up first.
#
# This mirrors exactly what the KeyDeck app's "Set up" button does, so CLI and
# GUI installs converge on identical state.
#
# Usage:
#   scripts/install.sh [--config]    # --config also installs the example config
set -euo pipefail
cd "$(dirname "$0")/.."          # repo root
REPO="$PWD"
HS="$HOME/.hammerspoon"
INIT="$HS/init.lua"
MARKER="-- KeyDeck (added by the KeyDeck app)"
WITH_CONFIG=0

while [ $# -gt 0 ]; do
  case "$1" in
    --config) WITH_CONFIG=1; shift ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

echo "Installing KeyDeck.spoon -> $HS/Spoons"
mkdir -p "$HS/Spoons"
rm -rf "$HS/Spoons/KeyDeck.spoon"
cp -R "$REPO/Spoons/KeyDeck.spoon" "$HS/Spoons/KeyDeck.spoon"

# Back up init.lua once, then append the loader if it isn't already there.
if [ -f "$INIT" ] && [ ! -f "$INIT.keydeck-backup" ]; then
  cp "$INIT" "$INIT.keydeck-backup"
  echo "Backed up $INIT -> $INIT.keydeck-backup"
fi
if ! grep -qF "$MARKER" "$INIT" 2>/dev/null; then
  printf '\n%s\nhs.loadSpoon("KeyDeck")\nspoon.KeyDeck:start()\n' "$MARKER" >> "$INIT"
  echo "Added KeyDeck loader to $INIT"
fi

if [ "$WITH_CONFIG" = 1 ] && [ ! -f "$HS/keydeck-config.json" ]; then
  cp "$REPO/config/keydeck-config.example.json" "$HS/keydeck-config.json"
  echo "Installed example config -> $HS/keydeck-config.json"
fi

echo
echo "Done. Quit and reopen Hammerspoon (or Reload Config) to activate."
