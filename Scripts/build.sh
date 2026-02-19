#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="BrowserChooser"
APP_BUNDLE="$PROJECT_DIR/.build/$APP_NAME.app"

echo "==> Building $APP_NAME..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Assembling $APP_NAME.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Ad-hoc codesign so macOS will run it
echo "==> Code signing..."
codesign --force --sign - "$APP_BUNDLE"

echo "==> Built: $APP_BUNDLE"

# Register URL scheme handler
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE"
echo "==> Registered URL schemes with Launch Services"
