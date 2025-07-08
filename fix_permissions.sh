#!/bin/bash

echo "🔧 Fixing Accessibility Permissions for Rephraser"
echo "================================================="
echo ""

APP_PATH="/Users/rokhoang/Library/Developer/Xcode/DerivedData/rephraser-brueqtblshgtamglsthbeofwfevt/Build/Products/Debug/rephraser.app"

echo "📱 App location: $APP_PATH"
echo ""

# Kill any running instances
echo "🛑 Stopping any running instances..."
pkill -f "rephraser" 2>/dev/null || true

echo "⚠️  MANUAL STEPS REQUIRED:"
echo ""
echo "1. Open System Settings (or System Preferences)"
echo "2. Go to: Privacy & Security → Accessibility"
echo "3. Look for 'rephraser' in the list"
echo "4. If found: Enable it (check the box)"
echo "5. If NOT found: Click '+' and add this app:"
echo "   $APP_PATH"
echo ""
echo "6. After granting permissions, press Enter to restart the app..."

read -p "Press Enter when you've granted accessibility permissions..."

echo ""
echo "🚀 Restarting app with permissions..."
open "$APP_PATH"

sleep 3

if pgrep -f "rephraser" > /dev/null; then
    echo "✅ App restarted successfully!"
    echo "🎯 Now try the test: Cmd+C+C+C on selected text"
else
    echo "❌ App didn't start. Try manually opening it from Finder."
fi

echo ""
echo "Alternative: Open this path in Finder and double-click the app:"
echo "$APP_PATH"