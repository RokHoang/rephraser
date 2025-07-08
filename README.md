# Rephraser

Rephraser is a macOS menu bar application designed to help you rephrase text quickly and easily. Select any text, use a global hotkey, and get a rephrased version using the power of the Claude API.

## Demo

https://github.com/RokHoang/rephraser/asset/demo.mov

<video src="asset/demo.mov" controls width="800">
  Your browser does not support the video tag.
</video>

## Features

*   **Menu Bar Integration:** Access Rephraser directly from your menu bar with a clean, intuitive interface.
*   **Global Hotkey:** Rephrase text from anywhere on your Mac with a configurable global hotkey (default: Cmd+C pressed 3 times).
*   **Multiple Rephrase Styles:** Choose from 6 built-in styles:
    *   Standard - Clear and well-structured
    *   Formal - Professional and academic tone
    *   Casual - Relaxed and conversational
    *   Concise - Brief and to the point
    *   Creative - Engaging and expressive
    *   Professional - Business-appropriate language
*   **Custom Styles:** Create and manage your own custom rephrasing styles with personalized prompts.
*   **History:** View a comprehensive history of your rephrased text with timestamps.
*   **Secure Storage:** API keys and settings are securely stored in the macOS Keychain.
*   **Accessibility Integration:** Seamlessly works with macOS accessibility features for text selection.
*   **Network Diagnostics:** Built-in network connectivity diagnostics for troubleshooting.
*   **Error Handling:** Comprehensive error handling and user feedback.

## Installation

### Pre-built Installer
The easiest way to install Rephraser is using the pre-built installer:

1. Download the latest `Rephraser-1.0.0-Installer.dmg` from the `installer/` directory
2. Double-click the DMG file to mount it
3. Follow the installation instructions

### Build and Install Script
You can also build and install from source using the provided script:

```bash
./build_and_install.sh
```

This will:
- Build the project using Xcode
- Install the app to `~/Applications/rephraser.app`
- Launch the application

## Building from Source

### Requirements
- macOS 10.15 or later
- Xcode 12.0 or later
- Swift 5.0 or later

### Build Steps
1. Clone the repository
2. Open `rephraser.xcodeproj` in Xcode
3. Build the project (⌘+B)
4. Run the project (⌘+R) or archive for distribution

### Creating an Installer
To create a distributable installer package:

```bash
./create_installer.sh
```

This will generate:
- `Rephraser-1.0.0.pkg` - macOS installer package
- `Rephraser-1.0.0.zip` - Zipped application bundle
- `Rephraser-1.0.0-Installer.dmg` - Disk image with installer

## Configuration

### API Key Setup
1. Obtain a Claude API key from Anthropic
2. Launch Rephraser and click on the settings icon
3. Enter your API key in the settings panel
4. The key is securely stored in your macOS Keychain

### Hotkey Configuration
1. Open settings from the menu bar
2. Click on the hotkey configuration section
3. Set your preferred key combination
4. The hotkey will work system-wide once accessibility permissions are granted

### Permissions
Rephraser requires accessibility permissions to:
- Read selected text from other applications
- Monitor global hotkeys

The app will guide you through granting these permissions on first launch.

## Usage

1. Select any text in any application
2. Press your configured hotkey (default: Cmd+C pressed 3 times)
3. Choose your preferred rephrasing style
4. The rephrased text will replace your selection automatically
5. View history and manage custom styles through the menu bar interface

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
│   ├── rephraserApp.swift      # App entry point
│   ├── AppState.swift          # Global app state management
│   ├── ClaudeAPI.swift         # Claude API integration
│   ├── RephraseStyle.swift     # Style management system
│   ├── GlobalHotkeyManager.swift # Hotkey handling
│   ├── HistoryView.swift       # History interface
│   ├── SettingsView.swift      # Settings interface
│   └── ...                     # Additional UI and utility files
├── rephraserTests/      # Unit tests
├── rephraserUITests/    # UI automation tests
├── installer/           # Pre-built installers
└── build/              # Build output directory
```

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
