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
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

# Strip extended attributes that break codesign
xattr -cr "$APP_BUNDLE"

# Sign with the stable local identity if it exists (see Scripts/create-signing-cert.sh), so
# macOS keeps privacy grants like Full Disk Access across rebuilds. Otherwise fall back to
# ad-hoc signing, under which every build looks like a new app to macOS privacy settings.
SIGN_IDENTITY="${SIGN_IDENTITY:-BrowserChooser Local Signing}"
if security find-identity -p codesigning | grep -qF "\"$SIGN_IDENTITY\""; then
    echo "==> Code signing with \"$SIGN_IDENTITY\"..."
    codesign --force --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
else
    echo "==> Code signing ad-hoc (run Scripts/create-signing-cert.sh to keep Full Disk Access across rebuilds)..."
    codesign --force --sign - "$APP_BUNDLE"
fi

echo "==> Built: $APP_BUNDLE"

# Register URL scheme handler
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE"
echo "==> Registered URL schemes with Launch Services"
