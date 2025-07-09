# Rephraser

Rephraser is a macOS menu bar application designed to help you rephrase text quickly and easily. Select any text, use a global hotkey, and get a rephrased version using the power of AI. Supports both Claude and OpenAI APIs with a modern, intuitive interface.

## Demo



https://github.com/user-attachments/assets/e4f7ba8b-6040-4ff8-a3af-3be8e0912c00



## Features

*   **Menu Bar Integration:** Access Rephraser directly from your menu bar with a clean, intuitive interface.
*   **Dual AI Provider Support:** Choose between Claude and OpenAI APIs for rephrasing with seamless switching.
*   **Global Hotkey:** Rephrase text from anywhere on your Mac with configurable global hotkeys (6 options available).
*   **Modern Grid Interface:** Navigate styles and hotkeys with intuitive 2x3 grid layouts for better user experience.
*   **Multiple Rephrase Styles:** Choose from 6 built-in styles:
    *   Standard - Clear and well-structured
    *   Formal - Professional and academic tone
    *   Casual - Relaxed and conversational
    *   Concise - Brief and to the point
    *   Creative - Engaging and expressive
    *   Professional - Business-appropriate language
*   **Custom Styles:** Create and manage your own custom rephrasing styles with personalized prompts.
*   **Direct Input Mode:** Rephrase text directly within the app without using global hotkeys.
*   **Comprehensive History:** View detailed history with provider information, timestamps, and success indicators.
*   **Secure Keychain Storage:** API keys stored securely in macOS Keychain with proper accessibility attributes.
*   **Accessibility Integration:** Seamlessly works with macOS accessibility features for text selection.
*   **Network Diagnostics:** Built-in network connectivity diagnostics for troubleshooting.
*   **Enhanced Error Handling:** Provider-specific error messages with detailed troubleshooting information.

## Installation

### Drag-and-Drop Installer (Recommended)
The easiest way to install Rephraser is using the modern drag-and-drop installer:

1. Download the latest `Install-Rephraser-1.0.0.dmg` from the `installer/` directory
2. Double-click the DMG file to mount it
3. Drag the Rephraser app to the Applications folder
4. Launch Rephraser from your Applications folder

### Alternative Installation Methods

**Traditional Package Installer:**
1. Download `Rephraser-1.0.0.pkg` from the `installer/` directory
2. Double-click the package file and follow the installation wizard

**Build from Source:**
```bash
./create_installer.sh --drag-drop  # Creates drag-and-drop installer
./create_installer.sh --pkg        # Creates traditional package installer
./create_installer.sh              # Creates both installer types
```

## Building from Source

### Requirements
- macOS 15.5 or later
- Xcode 16.0 or later
- Swift 5.0 or later

### Build Steps
1. Clone the repository
2. Open `rephraser.xcodeproj` in Xcode
3. Build the project (⌘+B)
4. Run the project (⌘+R) or archive for distribution

### Creating an Installer
The installer script supports multiple output formats:

```bash
# Create all installer types (recommended)
./create_installer.sh

# Create only drag-and-drop installer
./create_installer.sh --drag-drop

# Create only traditional package installer
./create_installer.sh --pkg
```

**Generated Files:**
- `Install-Rephraser-1.0.0.dmg` - Modern drag-and-drop installer
- `Rephraser-1.0.0.pkg` - Traditional macOS installer package
- `Rephraser-1.0.0-Installer.dmg` - Disk image with package installer and app
- `Rephraser-1.0.0-DragDrop.zip` - Zipped drag-and-drop installer
- `Rephraser-1.0.0.zip` - Zipped package installer

## Configuration

### API Key Setup
Rephraser supports both Claude and OpenAI APIs:

**For Claude:**
1. Obtain a Claude API key from [Anthropic Console](https://console.anthropic.com)
2. Launch Rephraser and open Settings
3. In the API tab, select "Claude" as your provider
4. Enter your Claude API key

**For OpenAI:**
1. Obtain an OpenAI API key from [OpenAI Platform](https://platform.openai.com)
2. Launch Rephraser and open Settings
3. In the API tab, select "OpenAI" as your provider
4. Enter your OpenAI API key

**Security:** All API keys are securely stored in your macOS Keychain with proper encryption and access controls.

### Hotkey Configuration
1. Open Settings from the menu bar
2. Navigate to the Hotkeys tab
3. Choose from 6 available hotkey options in the intuitive grid interface:
   - Cmd+C (3x), Cmd+B (3x), Cmd+T (3x), Cmd+R (3x)
   - Cmd+Shift+C (2x), Cmd+Shift+B (2x), Cmd+Shift+T (2x), Cmd+Shift+R (2x)
4. Your selection is saved automatically
5. The hotkey will work system-wide once accessibility permissions are granted

### Permissions
Rephraser requires accessibility permissions to:
- Read selected text from other applications
- Monitor global hotkeys

The app will guide you through granting these permissions on first launch.

## Usage

### Global Hotkey Method
1. Select any text in any application
2. Press your configured hotkey (default: Cmd+C pressed 3 times)
3. Choose your preferred rephrasing style from the grid interface
4. The rephrased text will replace your selection automatically

### Direct Input Method
1. Open Rephraser from the menu bar
2. Navigate to the "Direct Input" tab in Settings
3. Enter or paste your text directly
4. Click "Rephrase" to get the result
5. Copy the result or use it as input for further rephrasing

### Managing Styles and History
- **Styles:** Access the Styles tab for 6 built-in options in a 2x3 grid layout
- **History:** View comprehensive history with provider info, timestamps, and success indicators
- **Custom Styles:** Create and manage personalized rephrasing styles

## Testing

The project includes comprehensive test suites:

- **Unit Tests:** Run with `rephraserTests.swift`
- **UI Tests:** Run with `rephraserUITests.swift`
- **Manual Testing:** Use the provided AppleScript: `test_rephraser.applescript`

Additional testing scripts:
- `manual_test.sh` - Manual testing procedures
- `quick_test.sh` - Quick functionality tests
- `test_with_logs.sh` - Testing with detailed logging

## Project Structure

```
rephraser/
├── rephraser/           # Main application source
│   ├── rephraserApp.swift       # App entry point
│   ├── AppState.swift           # Global app state management
│   ├── ClaudeAPI.swift          # Claude API integration
│   ├── OpenAIAPI.swift          # OpenAI API integration
│   ├── RephraseStyle.swift      # Style management system
│   ├── GlobalHotkeyManager.swift # Hotkey handling
│   ├── HistoryView.swift        # History interface
│   ├── SettingsView.swift       # Settings interface with grid layouts
│   ├── KeychainHelper.swift     # Secure keychain operations
│   ├── ErrorHandling.swift      # Enhanced error handling
│   └── ...                      # Additional UI and utility files
├── rephraserTests/      # Unit tests
├── rephraserUITests/    # UI automation tests
├── installer/           # Pre-built installers
│   ├── Install-Rephraser-1.0.0.dmg     # Drag-and-drop installer
│   ├── Rephraser-1.0.0-DragDrop.zip    # Zipped drag-and-drop installer
│   └── ...                              # Additional installer formats
└── build/              # Build output directory
```

## Recent Improvements

### Version 1.0.0 - Major UI and Installer Enhancements

**🔐 Security Improvements:**
- Fixed repeated keychain password prompts with proper accessibility attributes
- Enhanced keychain storage with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Improved API key initialization and loading

**🎨 Modern UI Updates:**
- Converted style and hotkey selections to intuitive 2x3 grid layouts
- Enhanced visual organization with better spacing and selection indicators
- Improved settings view with proper state management

**🚀 Dual API Provider Support:**
- Full OpenAI API integration alongside existing Claude support
- Seamless provider switching with unified error handling
- Provider-specific error messages and troubleshooting

**📦 Enhanced Installation:**
- Modern drag-and-drop installer with custom DMG layout
- AppleScript-powered DMG window customization
- Flexible installer script supporting multiple output formats
- Professional installation experience with proper iconography

**🛠️ Technical Enhancements:**
- Improved error handling with provider-specific error conversion
- Better state management for dual API provider support
- Enhanced history tracking with provider information
- Optimized keychain operations for better performance

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
