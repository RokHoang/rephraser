#!/bin/bash

echo "🚀 Final Test - Rephraser App with Logging"
echo "=========================================="
echo ""

# Kill any existing instances
pkill -f "rephraser" 2>/dev/null || true

echo "📱 Starting app in background with logging enabled..."
APP_PATH="/Users/rokhoang/Library/Developer/Xcode/DerivedData/rephraser-brueqtblshgtamglsthbeofwfevt/Build/Products/Debug/rephraser.app"

# Start the app in background
"$APP_PATH/Contents/MacOS/rephraser" > app_log.txt 2>&1 &
APP_PID=$!

sleep 2

echo "✅ App started with PID: $APP_PID"
echo "📄 Logs are being written to: app_log.txt"
echo ""
echo "🎯 TEST INSTRUCTIONS:"
echo "1. Open TextEdit (Cmd+Space, type 'TextEdit')"
echo "2. Type some sample text:"
echo "   'This is a very long sentence that could be shortened.'"
echo "3. Select all text (Cmd+A)"
echo "4. Press Cmd+C three times quickly (within 0.5 seconds)"
echo "5. Wait for the text to be replaced"
echo ""
echo "📊 To see live logs while testing:"
echo "   tail -f app_log.txt"
echo ""
echo "🛑 To stop the app:"
echo "   kill $APP_PID"
echo ""

echo "App is running... Test the shortcut now!"
echo "Press Enter when done testing to see the final logs..."
read

echo ""
echo "📄 Final log output:"
echo "==================="
cat app_log.txt

# Kill the app
kill $APP_PID 2>/dev/null || true
echo ""
echo "✅ App stopped. Log saved in app_log.txt"