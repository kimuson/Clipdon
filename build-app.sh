#!/bin/bash
# Builds a standalone Clipdon.app bundle (menu-bar agent, no Dock icon).
#
#   Local use (ad-hoc signed):
#     ./build-app.sh
#
#   Distributable build (signed + Hardened Runtime, ready to notarize):
#     CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build-app.sh
#
# A universal (Intel + Apple Silicon) binary is produced so it runs everywhere.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Clipdon"
BUNDLE_ID="org.nexaspark.clipdon"
VERSION="${VERSION:-1.0}"
COPYRIGHT="© 2026 NexaSpark"
# Default to ad-hoc ("-") so it runs locally without a paid account.
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

echo "==> Building universal release binary…"
swift build -c release --arch arm64 --arch x86_64

APP="${APP_NAME}.app"
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/${APP_NAME}"

echo "==> Assembling ${APP}…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/${APP_NAME}"

# Drop an icon in if present (see README for how to generate AppIcon.icns).
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
    ICON_LINE='<key>CFBundleIconFile</key><string>AppIcon</string>'
else
    ICON_LINE=''
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>     <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>      <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>      <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleVersion</key>         <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key> <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>  <string>14.0</string>
    <key>LSApplicationCategoryType</key> <string>public.app-category.productivity</string>
    <key>NSHumanReadableCopyright</key> <string>${COPYRIGHT}</string>
    <!-- Agent app: lives in the menu bar, no Dock icon. -->
    <key>LSUIElement</key>             <true/>
    ${ICON_LINE}
</dict>
</plist>
PLIST

if [ "$CODESIGN_IDENTITY" = "-" ]; then
    codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
    echo "==> Ad-hoc signed (local use only — not distributable)."
else
    # --options runtime enables Hardened Runtime, required for notarization.
    codesign --force --options runtime --timestamp \
        --sign "$CODESIGN_IDENTITY" "$APP"
    echo "==> Signed for distribution with: $CODESIGN_IDENTITY"
    echo "    Next: ./notarize.sh"
fi

echo "==> Done: $(pwd)/$APP"
echo "    Launch with:  open $APP"
echo "    Add to login items via System Settings ▸ General ▸ Login Items."
