#!/usr/bin/env bash
# Run the full offline verification suite (no Hammerspoon required).
# Usage: test/run.sh
set -euo pipefail
cd "$(dirname "$0")/.."   # repo root
SPOON="$PWD/Spoons/KeyDeck.spoon"

LUA="$(command -v luajit || command -v lua || true)"
if [ -z "$LUA" ]; then echo "need luajit or lua on PATH"; exit 1; fi

echo "== 1. Lua syntax =="
for f in Spoons/KeyDeck.spoon/*.lua Spoons/KeyDeck.spoon/lib/*.lua Spoons/KeyDeck.spoon/modules/*.lua; do
  "$LUA" -e "assert(loadfile('$f'))" && echo "  ok   $f"
done

echo "== 2. JSON validity =="
for j in config/*.json; do
  python3 -c "import json;json.load(open('$j'))" && echo "  ok   $j"
done

echo "== 3. Load harness (mock hs; every module setup runs) =="
"$LUA" test/load_harness.lua "$SPOON"

echo "== 4. Behavior harness (invokes callbacks; asserts effects) =="
"$LUA" test/behavior_harness.lua "$SPOON"

echo "== ALL CHECKS PASSED =="
