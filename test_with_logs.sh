#!/bin/bash

echo "🚀 Testing Rephraser App with Detailed Logging"
echo "============================================="
echo ""

# Kill any existing instances
pkill -f "rephraser" 2>/dev/null || true

echo "📱 Launching app with console output..."
echo ""

APP_PATH="/Users/rokhoang/Library/Developer/Xcode/DerivedData/rephraser-brueqtblshgtamglsthbeofwfevt/Build/Products/Debug/rephraser.app"

# Launch the app and capture output
"$APP_PATH/Contents/MacOS/rephraser" &
APP_PID=$!

echo "✅ App launched with PID: $APP_PID"
echo ""
echo "🎯 Now test the shortcut:"
echo "1. Open TextEdit"
echo "2. Type some text"
echo "3. Select the text (Cmd+A)"
echo "4. Press Cmd+C three times quickly"
echo ""
echo "📊 Watch the console output above to see what happens..."
echo ""
echo "Press Ctrl+C to stop the app when done testing."

# Wait for the app process
wait $APP_PID