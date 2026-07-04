#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="BrowserChooser"
APP_BUNDLE="$PROJECT_DIR/.build/$APP_NAME.app"
INSTALL_DIR="/Applications"
LAUNCH_AGENT_LABEL="com.garethj.browserchooser"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_LABEL.plist"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found. Run 'make bundle' first."
    exit 1
fi

echo "==> Installing $APP_NAME to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_DIR/$APP_NAME.app"

echo "==> Installing login item so $APP_NAME starts automatically at login..."
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$LAUNCH_AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LAUNCH_AGENT_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LAUNCH_AGENT_LABEL" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PLIST"

echo "==> Installed and started (also set to launch automatically at login)."

# macOS doesn't allow apps to silently set themselves as the default browser
# (to prevent hijacking), so open the right settings pane for a one-click pick.
echo "==> Opening System Settings so you can pick BrowserChooser as your default browser..."
open "x-apple.systempreferences:com.apple.Desktop-Settings.extension"
