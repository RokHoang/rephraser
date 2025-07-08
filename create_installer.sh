#!/bin/bash

# Rephraser App Installer Creator
# This script creates a macOS installer package (.pkg) for the Rephraser app

set -e

echo "🔨 Building Rephraser installer..."

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

# Build the package
echo "📦 Creating installer package..."
pkgbuild \
    --root "$PACKAGE_ROOT" \
    --scripts "$TEMP_DIR/scripts" \
    --identifier "$BUNDLE_ID" \
    --version "$APP_VERSION" \
    --install-location "/" \
    "$INSTALLER_DIR/Rephraser-$APP_VERSION.pkg"

# Create a distributable DMG (optional)
echo "💿 Creating DMG disk image..."
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

# Create a simple zip archive as well
echo "🗜️  Creating ZIP archive..."
cd "$INSTALLER_DIR"
zip -r "Rephraser-$APP_VERSION.zip" "Rephraser-$APP_VERSION.pkg"
cd ..

# Clean up temporary files
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Installer creation complete!"
echo ""
echo "Created files:"
echo "  📦 $INSTALLER_DIR/Rephraser-$APP_VERSION.pkg - Main installer package"
echo "  💿 $INSTALLER_DIR/$DMG_NAME.dmg - Disk image with installer and app"
echo "  🗜️  $INSTALLER_DIR/Rephraser-$APP_VERSION.zip - ZIP archive of installer"
echo ""
echo "Distribution options:"
echo "  • Share the .pkg file for simple installation"
echo "  • Share the .dmg file for a complete package"
echo "  • Share the .zip file for easy download"
echo ""
echo "Recipients can:"
echo "  1. Double-click the .pkg file to install"
echo "  2. Or mount the .dmg and run the installer"
echo "  3. Or drag the app directly to Applications (from DMG)"