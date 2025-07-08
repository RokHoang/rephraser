#!/bin/bash

echo "🚀 Manual Test Instructions for Rephraser App"
echo "=============================================="
echo ""

# Launch the app
echo "📱 1. Launching Rephraser app..."
open "/Users/rokhoang/Library/Developer/Xcode/DerivedData/rephraser-brueqtblshgtamglsthbeofwfevt/Build/Products/Debug/rephraser.app"

sleep 2

echo "✅ App launched! Look for the text badge icon in your menu bar."
echo ""
echo "📋 2. Manual Test Steps:"
echo "   a) Open TextEdit (or any text editor)"
echo "   b) Type this sample text:"
echo "      'This is a very long and unnecessarily complicated sentence that could definitely be made much shorter and more concise and easier to understand for readers.'"
echo "   c) Select all the text (Cmd+A)"
echo "   d) Press Cmd+C three times quickly (within 0.5 seconds)"
echo "   e) Wait 2-3 seconds for the API response"
echo "   f) The text should be automatically replaced with a rephrased version"
echo ""
echo "🔍 3. What to expect:"
echo "   - Notification: 'Rephraser: Text rephrased successfully'"
echo "   - The selected text will be automatically replaced"
echo "   - If there's an error, you'll see an error notification"
echo ""
echo "⚠️  4. Troubleshooting:"
echo "   - If nothing happens, check System Settings > Privacy & Security > Accessibility"
echo "   - Make sure 'rephraser' is enabled in the accessibility list"
echo "   - Try the keyboard shortcut again (timing matters!)"
echo ""
echo "🎯 5. Test complete when:"
echo "   - You see the original long sentence replaced with a shorter, clearer version"
echo "   - You receive a success notification"
echo ""

# Check if app is running
sleep 3
if pgrep -f "rephraser" > /dev/null; then
    echo "✅ App is running in the background"
    echo "🔍 You should see the text badge icon in your menu bar"
else
    echo "❌ App may not have started properly"
    echo "💡 Try running it manually from Finder"
fi

echo ""
echo "Ready to test! Follow the steps above."