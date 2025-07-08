#!/bin/bash

echo "🚀 Starting automated test of Rephraser app..."

# Make sure the app is running
echo "📱 Launching Rephraser app..."
open /Users/rokhoang/Library/Developer/Xcode/DerivedData/rephraser-brueqtblshgtamglsthbeofwfevt/Build/Products/Debug/rephraser.app

# Wait for app to start
sleep 2

echo "⌨️  Running AppleScript test..."
osascript test_rephraser.applescript

echo "✅ Test completed!"