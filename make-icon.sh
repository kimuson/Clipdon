#!/bin/bash
# Generates Clipdon's icons from tools/make-icon.swift:
#   - AppIcon.icns                          → used by build-app.sh (direct distribution)
#   - Assets.xcassets/AppIcon.appiconset/*  → used by the Xcode / App Store build
set -euo pipefail
cd "$(dirname "$0")"

MAKER="/tmp/clipdon-iconmaker"
ICONSET="AppIcon.iconset"
APPICONSET="Assets.xcassets/AppIcon.appiconset"

echo "==> Compiling renderer…"
swiftc -O tools/make-icon.swift -o "$MAKER"

echo "==> Building AppIcon.icns…"
rm -rf "$ICONSET"; mkdir "$ICONSET"
"$MAKER" 16   "$ICONSET/icon_16x16.png"
"$MAKER" 32   "$ICONSET/icon_16x16@2x.png"
"$MAKER" 32   "$ICONSET/icon_32x32.png"
"$MAKER" 64   "$ICONSET/icon_32x32@2x.png"
"$MAKER" 128  "$ICONSET/icon_128x128.png"
"$MAKER" 256  "$ICONSET/icon_128x128@2x.png"
"$MAKER" 256  "$ICONSET/icon_256x256.png"
"$MAKER" 512  "$ICONSET/icon_256x256@2x.png"
"$MAKER" 512  "$ICONSET/icon_512x512.png"
"$MAKER" 1024 "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o AppIcon.icns
rm -rf "$ICONSET"

echo "==> Rendering asset-catalog icons…"
mkdir -p "$APPICONSET"
for px in 16 32 64 128 256 512 1024; do
    "$MAKER" "$px" "$APPICONSET/icon_${px}.png"
done

# Keep a 1024 preview for quick visual checks.
"$MAKER" 1024 icon-preview.png

echo "==> Done: AppIcon.icns + $APPICONSET/*.png"
