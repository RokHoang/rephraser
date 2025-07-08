#!/bin/bash

APP_PATH="/Users/rokhoang/Library/Developer/Xcode/DerivedData/rephraser-brueqtblshgtamglsthbeofwfevt/Build/Products/Debug/rephraser.app"

echo "🔧 Setting up Rephraser App with Accessibility Permissions"
echo "=========================================================="
echo ""

# Kill any existing instances
pkill -f "rephraser" 2>/dev/null || true

echo "📱 App built at: $APP_PATH"
echo ""

echo "🔓 Opening System Settings for Accessibility permissions..."
echo "   Please grant accessibility permissions to 'rephraser'"
echo ""

# Open system settings to accessibility
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo "⚠️  IMPORTANT STEPS:"
echo "1. In System Settings, go to Privacy & Security → Accessibility"
echo "2. Click the '+' button"
echo "3. Navigate to and select:"
echo "   $APP_PATH"
echo "4. Make sure it's ENABLED (checked)"
echo ""

read -p "Press Enter when you've granted accessibility permissions..."

echo ""
echo "🚀 Launching Rephraser app..."
open "$APP_PATH"

sleep 3

echo ""
if pgrep -f "rephraser" > /dev/null; then
    echo "✅ App is running! Look for the text badge icon in your menu bar."
    echo ""
    echo "🧪 TEST IT NOW:"
    echo "1. Open TextEdit"
    echo "2. Type: 'This is a very long and unnecessarily complicated sentence that could definitely be made much shorter.'"
    echo "3. Select all text (Cmd+A)"
    echo "4. Press Cmd+C three times quickly"
    echo "5. Wait for the text to be rephrased!"
    echo ""
    echo "Expected: The text should be replaced with a shorter version"
    echo "Expected: You should see a success notification"
else
    echo "❌ App failed to start. Check the Console app for errors."
    echo "💡 Try manually opening: $APP_PATH"
fi