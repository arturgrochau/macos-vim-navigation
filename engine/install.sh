#!/usr/bin/env bash
# Safely install the KeyDeck engine as your Hammerspoon config, backing up any
# existing ~/.hammerspoon first. Reversible: the backup path is printed at the end.
#
# Usage:
#   engine/install.sh [--preset default|developer|minimal]
#
# After running, open Hammerspoon and Reload Config (or press ⌥R).
set -euo pipefail
cd "$(dirname "$0")/.."          # repo root
REPO="$PWD"
HS="$HOME/.hammerspoon"
PRESET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --preset) PRESET="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

if [ -e "$HS" ]; then
  BACKUP="$HOME/.hammerspoon.backup.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing $HS -> $BACKUP"
  mv "$HS" "$BACKUP"
fi

echo "Installing engine -> $HS"
cp -R "$REPO/engine" "$HS"

if [ -n "$PRESET" ]; then
  SRC="$REPO/config/presets/$PRESET.json"
  [ -f "$SRC" ] || { echo "no such preset: $PRESET"; exit 1; }
  echo "Installing preset '$PRESET' -> $HS/keydeck-config.json"
  cp "$SRC" "$HS/keydeck-config.json"
fi

echo
echo "Done. Open Hammerspoon and Reload Config (⌥R)."
[ -n "${BACKUP:-}" ] && echo "To restore your old config:  rm -rf '$HS' && mv '$BACKUP' '$HS'"
