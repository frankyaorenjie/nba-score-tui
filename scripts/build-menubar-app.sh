#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
PACKAGE_DIR="$ROOT_DIR/macos-menubar"
OUTPUT_DIR="$ROOT_DIR/dist"
APP_NAME="NBAScoreMenubar"
ARCH=$(uname -m)
DIST_APP_NAME="$APP_NAME-$ARCH"
APP_BUNDLE="$OUTPUT_DIR/$DIST_APP_NAME.app"
LEGACY_APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"

swift build \
  --package-path "$PACKAGE_DIR" \
  --configuration release \
  --product "$APP_NAME"

BIN_DIR=$(swift build \
  --package-path "$PACKAGE_DIR" \
  --configuration release \
  --show-bin-path)

rm -rf "$APP_BUNDLE"
rm -rf "$LEGACY_APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp -f "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>NBAScoreMenubar</string>
  <key>CFBundleIdentifier</key>
  <string>com.frankyaorenjie.nbascoremenubar</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>NBAScoreMenubar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

echo "Built $APP_BUNDLE"
