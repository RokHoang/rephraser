#!/bin/bash

echo "🔧 Fixing Xcode Accessibility Permissions"
echo "========================================="
echo ""

echo "The 'Failed to create event tap' error occurs because Xcode needs"
echo "accessibility permissions to run apps that monitor global events."
echo ""

echo "📝 MANUAL STEPS REQUIRED:"
echo ""
echo "1. Open System Settings (or System Preferences)"
echo "2. Go to: Privacy & Security → Accessibility" 
echo "3. Look for 'Xcode' in the list"
echo "4. If found: Enable it (check the box)"
echo "5. If NOT found: Click '+' and add Xcode:"
echo "   /Applications/Xcode.app"
echo ""
echo "6. ALSO add your built app:"
echo "   /Users/rokhoang/Library/Developer/Xcode/DerivedData/rephraser-brueqtblshgtamglsthbeofwfevt/Build/Products/Debug/rephraser.app"
echo ""

echo "🚀 Opening System Settings..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
read -p "Press Enter when you've granted permissions to BOTH Xcode AND the app..."

echo ""
echo "✅ Permissions should now be set!"
echo ""
echo "🎯 NOW TRY:"
echo "1. Run the app from Xcode (Cmd+R)"
echo "2. OR run the standalone app we built earlier"
echo ""
echo "The 'Failed to create event tap' error should be resolved."