#!/bin/bash
set -e

APP_NAME="Clove"
BUNDLE_ID="com.clove.app"
PLIST_LABEL="$BUNDLE_ID.launcher"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

echo "Uninstalling $APP_NAME..."

# Stop the app
pkill -x "$APP_NAME" 2>/dev/null || true

# Remove LaunchAgent
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"

# Remove app
rm -rf "/Applications/$APP_NAME.app"

# Remove data
rm -rf "$HOME/Library/Application Support/Clove"

echo "Done. $APP_NAME has been fully removed."
