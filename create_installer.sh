#!/bin/bash

# Rephraser App Installer Creator
# This script creates macOS installers for the Rephraser app
# Supports both traditional .pkg installers and drag-and-drop DMG installers

set -e

# Parse command line arguments
INSTALLER_TYPE="all"
if [ "$1" = "--drag-drop" ]; then
    INSTALLER_TYPE="drag-drop"
    echo "🔨 Building Rephraser drag-and-drop installer..."
elif [ "$1" = "--pkg" ]; then
    INSTALLER_TYPE="pkg"
    echo "🔨 Building Rephraser .pkg installer..."
else
    echo "🔨 Building Rephraser installers (all types)..."
fi

# Configuration
APP_NAME="Rephraser"
APP_VERSION="1.0.0"
BUNDLE_ID="rokhoang.rephraser"
BUILD_DIR="build/Release"
INSTALLER_DIR="installer"
TEMP_DIR="temp_installer"

# Clean up previous builds
echo "🧹 Cleaning up previous builds..."
rm -rf "$INSTALLER_DIR" "$TEMP_DIR"
mkdir -p "$INSTALLER_DIR" "$TEMP_DIR"

# Build the app in Release mode
echo "🔨 Building app..."
xcodebuild -project rephraser.xcodeproj -target rephraser -configuration Release clean build

# Verify the app was built
if [ ! -d "$BUILD_DIR/rephraser.app" ]; then
    echo "❌ App build failed - rephraser.app not found"
    exit 1
fi

echo "✅ App built successfully"

# Create temporary package structure
PACKAGE_ROOT="$TEMP_DIR/package_root"
mkdir -p "$PACKAGE_ROOT/Applications"

# Copy the app to the package
echo "📦 Preparing package contents..."
cp -R "$BUILD_DIR/rephraser.app" "$PACKAGE_ROOT/Applications/"

# Create package info files
mkdir -p "$TEMP_DIR/scripts"

# Create postinstall script to set permissions
cat > "$TEMP_DIR/scripts/postinstall" << 'EOF'
#!/bin/bash

# Set proper ownership and permissions
chown -R root:admin "/Applications/rephraser.app"
chmod -R 755 "/Applications/rephraser.app"

# Make the executable actually executable
chmod +x "/Applications/rephraser.app/Contents/MacOS/rephraser"

echo "Rephraser installed successfully!"
echo "You can find it in your Applications folder or menu bar."

exit 0
EOF

chmod +x "$TEMP_DIR/scripts/postinstall"

# Create .pkg installer if requested
if [ "$INSTALLER_TYPE" = "pkg" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    echo "📦 Creating installer package..."
    pkgbuild \
        --root "$PACKAGE_ROOT" \
        --scripts "$TEMP_DIR/scripts" \
        --identifier "$BUNDLE_ID" \
        --version "$APP_VERSION" \
        --install-location "/" \
        "$INSTALLER_DIR/Rephraser-$APP_VERSION.pkg"
fi

# Create drag-and-drop installer if requested
if [ "$INSTALLER_TYPE" = "drag-drop" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    echo "💿 Creating drag-and-drop installer..."
    
    # Create drag-and-drop DMG staging directory
    DRAG_DROP_STAGING="$TEMP_DIR/drag_drop_staging"
    mkdir -p "$DRAG_DROP_STAGING"
    
    # Copy the app to staging
    cp -R "$BUILD_DIR/rephraser.app" "$DRAG_DROP_STAGING/"
    
    # Create symbolic link to Applications folder
    ln -s /Applications "$DRAG_DROP_STAGING/Applications"
    
    # Create installation instructions
    cat > "$DRAG_DROP_STAGING/Install Instructions.txt" << EOF
Rephraser - AI-Powered Text Enhancement

INSTALLATION:
Drag the Rephraser.app icon to the Applications folder icon.

SETUP:
1. Open Rephraser from your Applications folder
2. Configure your Claude API key in Settings > API tab
3. Grant accessibility permissions when prompted
4. Select any text and press Cmd+C three times quickly to rephrase it

REQUIREMENTS:
- macOS 15.5 or later
- Claude AI API key (get one at console.anthropic.com)

For support, visit: https://github.com/rokhoang/rephraser
EOF
    
    # Create temporary drag-and-drop DMG
    DRAG_DROP_DMG_NAME="Install-Rephraser-$APP_VERSION"
    TEMP_DRAG_DROP_DMG="$TEMP_DIR/temp_drag_drop.dmg"
    hdiutil create -volname "$DRAG_DROP_DMG_NAME" -srcfolder "$DRAG_DROP_STAGING" -ov -format UDRW "$TEMP_DRAG_DROP_DMG"
    
    # Mount and customize the DMG
    MOUNT_DIR="/Volumes/$DRAG_DROP_DMG_NAME"
    hdiutil attach "$TEMP_DRAG_DROP_DMG" -quiet
    sleep 2
    
    # Create AppleScript to customize the DMG window
    cat > "$TEMP_DIR/customize_dmg.applescript" << 'EOF'
tell application "Finder"
    tell disk "Install-Rephraser-1.0.0"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        
        -- Position the app icon and Applications folder
        set position of item "rephraser.app" of container window to {150, 150}
        set position of item "Applications" of container window to {350, 150}
        set position of item "Install Instructions.txt" of container window to {150, 280}
        
        close
        open
        
        -- Update the display
        update without registering applications
        delay 2
    end tell
end tell
EOF
    
    # Run the AppleScript to customize the DMG
    osascript "$TEMP_DIR/customize_dmg.applescript" || echo "Warning: Could not customize DMG appearance"
    
    # Sync and unmount
    sync
    hdiutil detach "$MOUNT_DIR" -quiet
    
    # Convert to compressed read-only DMG
    FINAL_DRAG_DROP_DMG="$INSTALLER_DIR/$DRAG_DROP_DMG_NAME.dmg"
    hdiutil convert "$TEMP_DRAG_DROP_DMG" -format UDZO -o "$FINAL_DRAG_DROP_DMG"
fi

# Create traditional DMG with installer (if .pkg was created)
if [ "$INSTALLER_TYPE" = "pkg" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    echo "💿 Creating traditional DMG with installer..."
    DMG_NAME="Rephraser-$APP_VERSION-Installer"
    DMG_PATH="$INSTALLER_DIR/$DMG_NAME.dmg"

    # Create temporary DMG directory
    DMG_TEMP="$TEMP_DIR/dmg_temp"
    mkdir -p "$DMG_TEMP"

    # Copy installer and app to DMG
    cp "$INSTALLER_DIR/Rephraser-$APP_VERSION.pkg" "$DMG_TEMP/"
    cp -R "$BUILD_DIR/rephraser.app" "$DMG_TEMP/"

    # Create a README for the DMG
    cat > "$DMG_TEMP/README.txt" << EOF
Rephraser - AI-Powered Text Enhancement

Installation Options:
1. Run the Rephraser-$APP_VERSION.pkg installer (Recommended)
2. Or drag rephraser.app to your Applications folder

Requirements:
- macOS 15.5 or later
- Claude AI API key (get one at console.anthropic.com)

Usage:
1. Open the app and configure your Claude API key in Settings
2. Grant accessibility permissions when prompted
3. Select any text and press Cmd+C three times quickly to rephrase it

For support, visit: https://github.com/rokhoang/rephraser
EOF

    # Create the DMG
    hdiutil create -volname "$DMG_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DMG_PATH"
fi

# Create ZIP archives
echo "🗜️  Creating ZIP archives..."
cd "$INSTALLER_DIR"
if [ "$INSTALLER_TYPE" = "pkg" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    zip -r "Rephraser-$APP_VERSION.zip" "Rephraser-$APP_VERSION.pkg"
fi
if [ "$INSTALLER_TYPE" = "drag-drop" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    zip -r "Rephraser-$APP_VERSION-DragDrop.zip" "Install-Rephraser-$APP_VERSION.dmg"
fi
cd ..

# Clean up temporary files
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Installer creation complete!"
echo ""
echo "Created files:"

if [ "$INSTALLER_TYPE" = "pkg" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    echo "  📦 $INSTALLER_DIR/Rephraser-$APP_VERSION.pkg - Traditional installer package"
    echo "  💿 $INSTALLER_DIR/$DMG_NAME.dmg - Disk image with installer and app"
    echo "  🗜️  $INSTALLER_DIR/Rephraser-$APP_VERSION.zip - ZIP archive of installer"
fi

if [ "$INSTALLER_TYPE" = "drag-drop" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    echo "  💿 $INSTALLER_DIR/Install-Rephraser-$APP_VERSION.dmg - Drag-and-drop installer"
    echo "  🗜️  $INSTALLER_DIR/Rephraser-$APP_VERSION-DragDrop.zip - ZIP archive of drag-and-drop installer"
fi

echo ""
echo "Usage:"

if [ "$INSTALLER_TYPE" = "pkg" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    echo "Traditional installer (.pkg):"
    echo "  1. Double-click the .pkg file to install"
    echo "  2. Or mount the .dmg and run the installer"
    echo "  3. Or drag the app directly to Applications (from DMG)"
fi

if [ "$INSTALLER_TYPE" = "drag-drop" ] || [ "$INSTALLER_TYPE" = "all" ]; then
    echo "Drag-and-drop installer (.dmg):"
    echo "  1. Double-click the Install-Rephraser-$APP_VERSION.dmg file"
    echo "  2. Drag the Rephraser app to the Applications folder"
    echo "  3. Eject the disk image and launch from Applications"
fi

echo ""
echo "Command line options:"
echo "  ./create_installer.sh           - Create all installer types"
echo "  ./create_installer.sh --pkg     - Create only .pkg installer"
echo "  ./create_installer.sh --drag-drop - Create only drag-and-drop installer"