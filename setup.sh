#!/bin/bash
set -e

echo "Setting up Clove..."

if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen..."
    brew install xcodegen
fi

xcodegen generate
echo ""
echo "Done. Open Clove.xcodeproj in Xcode and hit Run (Cmd+R)."
echo "The app will appear as a bag icon in your menu bar."
