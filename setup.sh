#!/bin/bash
set -e

APP_NAME="Clove"
BUNDLE_ID="com.clove.app"
INSTALL_DIR="/Applications"
PLIST_LABEL="$BUNDLE_ID.launcher"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

echo "Setting up $APP_NAME..."

# Install xcodegen if missing
if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen via Homebrew..."
    brew install xcodegen
fi

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate --quiet

# Build release binary from CLI (no Xcode GUI needed)
echo "Building $APP_NAME (this may take a minute)..."
xcodebuild -project Clove.xcodeproj \
    -scheme Clove \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    -quiet

# Find and install the built app
BUILT_APP="build/Build/Products/Release/$APP_NAME.app"
if [ ! -d "$BUILT_APP" ]; then
    echo "Error: Build failed - $BUILT_APP not found"
    exit 1
fi

echo "Installing to $INSTALL_DIR..."
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi
cp -R "$BUILT_APP" "$INSTALL_DIR/"

# Set up LaunchAgent for auto-start at login
echo "Configuring auto-start at login..."
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>$INSTALL_DIR/$APP_NAME.app</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

# Clean up build artifacts
rm -rf build

echo ""
echo "Done! $APP_NAME is installed and will start automatically at login."
echo "Launching now..."
open -a "$INSTALL_DIR/$APP_NAME.app"
