#!/bin/bash

echo "🔨 Building Rephraser..."
xcodebuild -project rephraser.xcodeproj -target rephraser -configuration Release build

echo "📦 Installing to ~/Applications..."
# Remove existing app if it exists
if [ -d ~/Applications/rephraser.app ]; then
    rm -rf ~/Applications/rephraser.app
fi
cp -R build/Release/rephraser.app ~/Applications/

echo "✅ Rephraser installed to ~/Applications/rephraser.app"
echo "🚀 Launching app..."
open ~/Applications/rephraser.app
