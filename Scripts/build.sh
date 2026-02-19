#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="BrowserChooser"
APP_BUNDLE="$PROJECT_DIR/.build/$APP_NAME.app"

echo "==> Building $APP_NAME..."
cd "$PROJECT_DIR"
swift build -c release
BUILD_DIR="$(swift build -c release --show-bin-path)"
echo "==> Binary at: $BUILD_DIR/$APP_NAME"

echo "==> Assembling $APP_NAME.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Strip extended attributes that break codesign
xattr -cr "$APP_BUNDLE"

# Ad-hoc codesign so macOS will run it
echo "==> Code signing..."
codesign --force --sign - "$APP_BUNDLE"

echo "==> Built: $APP_BUNDLE"

# Register URL scheme handler
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE"
echo "==> Registered URL schemes with Launch Services"
