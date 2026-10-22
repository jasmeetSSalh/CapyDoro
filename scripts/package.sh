#!/bin/bash
#
# Builds a shareable CapyDoro-<version>.zip in dist/.
# Same result as Xcode's Product → Archive → Distribute App → Custom → Copy App,
# then zipping the .app.
#
# The app is ad-hoc signed ("Sign to Run Locally"), not notarized, so friends must
# approve it once: System Settings → Privacy & Security → Open Anyway.
#
# Usage (from the CapyDoro folder):  ./scripts/package.sh
set -euo pipefail

cd "$(dirname "$0")/.."
BUILD_DIR="$(mktemp -d)"
ARCHIVE="$BUILD_DIR/CapyDoro.xcarchive"
mkdir -p dist

echo "Archiving (Release)…"
xcodebuild archive \
  -scheme CapyDoro \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE" \
  -quiet

APP="$ARCHIVE/Products/Applications/CapyDoro.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ZIP="dist/CapyDoro-$VERSION.zip"

echo "Checking the signature…"
codesign --verify --deep --strict "$APP"

# ditto keeps the code signature intact (some zip tools break it).
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
rm -rf "$BUILD_DIR"

echo "Done: $ZIP ($(du -h "$ZIP" | cut -f1))"
