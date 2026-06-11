#!/usr/bin/env bash
# Build KeyDeck and wrap it in a minimal, proper macOS .app bundle so it launches
# as a real GUI app (dock icon, window, menu) instead of a bare CLI executable.
# Output: app/KeyDeck.app
set -euo pipefail
cd "$(dirname "$0")"   # app/

CONFIG="${1:-release}"   # release | debug
echo "Building KeyDeck ($CONFIG)…"
swift build -c "$CONFIG"

BIN=".build/$CONFIG/KeyDeck"
[ -f "$BIN" ] || BIN="$(swift build -c "$CONFIG" --show-bin-path)/KeyDeck"

APP="KeyDeck.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/KeyDeck"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>KeyDeck</string>
    <key>CFBundleDisplayName</key>     <string>KeyDeck</string>
    <key>CFBundleIdentifier</key>      <string>com.arturgrochau.keydeck</string>
    <key>CFBundleExecutable</key>      <string>KeyDeck</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleVersion</key>         <string>0.1.0</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>NSPrincipalClass</key>        <string>NSApplication</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSUIElement</key>             <false/>
</dict>
</plist>
PLIST

# Bundle the canonical Spoon inside the app's Resources, so the in-app
# "Set up engine" can install it into ~/.hammerspoon/Spoons.
SPOON="$APP/Contents/Resources/KeyDeck.spoon"
rm -rf "$SPOON"
cp -R ../Spoons/KeyDeck.spoon "$SPOON"

# Ad-hoc codesign so macOS lets it launch locally (no notarization yet).
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "Built $PWD/$APP"
