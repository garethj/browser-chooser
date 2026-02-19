#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="BrowserChooser"
APP_BUNDLE="$PROJECT_DIR/.build/$APP_NAME.app"
INSTALL_DIR="/Applications"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found. Run 'make bundle' first."
    exit 1
fi

echo "==> Installing $APP_NAME to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_DIR/$APP_NAME.app"

echo "==> Installed. Set BrowserChooser as your default browser in System Settings > Desktop & Dock."
echo "==> Starting $APP_NAME..."
open "$INSTALL_DIR/$APP_NAME.app"
