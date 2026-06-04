#!/bin/bash
# Notarizes and staples Clipdon.app, then produces a distributable zip.
#
# Prerequisites (one-time):
#   1. Apple Developer Program membership.
#   2. A "Developer ID Application" certificate in your keychain.
#   3. An app-specific password saved as a notarytool keychain profile:
#        xcrun notarytool store-credentials clipdon-notary \
#          --apple-id "you@example.com" --team-id "TEAMID" --password "xxxx-xxxx-xxxx-xxxx"
#
# Build first with a real identity, then run this:
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build-app.sh
#   ./notarize.sh
set -euo pipefail
cd "$(dirname "$0")"

APP="Clipdon.app"
ZIP="Clipdon.zip"
PROFILE="${NOTARY_PROFILE:-clipdon-notary}"

[ -d "$APP" ] || { echo "Build $APP first (see header)."; exit 1; }

echo "==> Zipping for submission…"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Submitting to Apple notary service (a few minutes)…"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "==> Stapling the ticket onto the app…"
xcrun stapler staple "$APP"

echo "==> Re-zipping the stapled app for distribution…"
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Verifying Gatekeeper will accept it…"
spctl -a -vvv "$APP" || true

echo "==> Done. Distribute: $(pwd)/$ZIP"
