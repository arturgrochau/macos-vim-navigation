#!/usr/bin/env bash
# Verify the KeyDeck app: build the SwiftUI executable, then run the core-logic
# assertions. The assertions run WITHOUT XCTest (which ships only with full Xcode),
# so this works on Command Line Tools alone. If XCTest is available, `swift test`
# is run too.
set -euo pipefail
cd "$(dirname "$0")/.."   # app/

echo "== 1. swift build (compiles KeyDeckCore + the SwiftUI app) =="
swift build

echo "== 2. core-logic assertions (no XCTest needed) =="
SDK="$(xcrun --sdk macosx --show-sdk-path)"
TGT="arm64-apple-macosx13.0"
OUT="$(mktemp -d)/kd_checks"
xcrun swiftc -sdk "$SDK" -target "$TGT" Sources/KeyDeckCore/*.swift test/checks/main.swift -o "$OUT"
"$OUT"

echo "== 3. swift test (XCTest; requires full Xcode) =="
if swift test 2>/tmp/kd_swifttest.log; then
  echo "  swift test passed"
else
  if grep -q "no such module 'XCTest'" /tmp/kd_swifttest.log; then
    echo "  skipped: XCTest unavailable (Command Line Tools only — install Xcode to run)"
  else
    echo "  swift test FAILED:"; tail -20 /tmp/kd_swifttest.log; exit 1
  fi
fi

echo "== APP CHECKS PASSED =="
