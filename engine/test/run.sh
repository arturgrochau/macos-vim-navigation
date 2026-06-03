#!/usr/bin/env bash
# Run the full offline verification suite (no Hammerspoon required).
# Usage: engine/test/run.sh
set -euo pipefail
cd "$(dirname "$0")/../.."   # repo root
ENGINE="$PWD/engine"

LUA="$(command -v luajit || command -v lua || true)"
if [ -z "$LUA" ]; then echo "need luajit or lua on PATH"; exit 1; fi

echo "== 1. Lua syntax =="
for f in engine/init.lua engine/config.lua engine/defaults.lua engine/lib/*.lua engine/modules/*.lua; do
  "$LUA" -e "assert(loadfile('$f'))" && echo "  ok   $f"
done

echo "== 2. JSON validity =="
for j in config/config.schema.json config/presets/*.json; do
  python3 -c "import json;json.load(open('$j'))" && echo "  ok   $j"
done

echo "== 3. Load harness (mock hs; every module setup runs) =="
"$LUA" engine/test/load_harness.lua "$ENGINE"

echo "== 4. Behavior harness (invokes callbacks; asserts effects) =="
"$LUA" engine/test/behavior_harness.lua "$ENGINE"

echo "== ALL CHECKS PASSED =="
