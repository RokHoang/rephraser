//
//  AppState.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation
import SwiftUI
import ApplicationServices
import AppKit

class AppState: ObservableObject {
    @Published var claudeAPIKey: String = ""
    @Published var openaiAPIKey: String = ""
    @Published var selectedAPIProvider: APIProvider = .claude
    @Published var isProcessing: Bool = false
    @Published var lastError: String?
    @Published var shouldShowPermissionsOnStartup: Bool = false
    @Published var history = RephrasingHistory()
    @Published var customHotkey: HotkeyConfig = HotkeyConfig.defaultHotkey
    @Published var selectedRephraseStyle: RephraseStyleOption = .builtin(.standard)
    @ObservedObject var processingIndicator = ProcessingIndicatorManager()
    @ObservedObject var errorHandler = ErrorHandler()
    @ObservedObject var styleManager = RephraseStyleManager()
    
    private let keychainService = "com.rokhoang.rephraser"
    private let claudeAPIKeyItem = "claude-api-key"
    private let openaiAPIKeyItem = "openai-api-key"
    private let apiProviderItem = "api-provider"
    private let hotkeyItem = "custom-hotkey"
    private let rephraseStyleItem = "rephrase-style"
    private let rephraseStyleOptionItem = "rephrase-style-option"
    private var hotkeyManager: GlobalHotkeyManager?
    
    init() {
        loadAPIKeys()
        loadAPIProvider()
        loadHotkeyConfig()
        loadRephraseStyle()
        checkInitialPermissions()
        setupHotkeyManager()
        configureBackgroundBehavior()
    }
    
    func saveClaudeAPIKey(_ key: String) {
        claudeAPIKey = key
        KeychainHelper.save(key, service: keychainService, account: claudeAPIKeyItem)
    }
    
    func saveOpenAIAPIKey(_ key: String) {
        openaiAPIKey = key
        KeychainHelper.save(key, service: keychainService, account: openaiAPIKeyItem)
    }
    
    func saveAPIProvider(_ provider: APIProvider) {
        selectedAPIProvider = provider
        KeychainHelper.save(provider.rawValue, service: keychainService, account: apiProviderItem)
    }
    
    private func loadAPIKeys() {
        if let claudeKey = KeychainHelper.load(service: keychainService, account: claudeAPIKeyItem) {
            claudeAPIKey = claudeKey
        }
        if let openaiKey = KeychainHelper.load(service: keychainService, account: openaiAPIKeyItem) {
            openaiAPIKey = openaiKey
        }
    }
    
    private func loadAPIProvider() {
        if let providerString = KeychainHelper.load(service: keychainService, account: apiProviderItem),
           let provider = APIProvider(rawValue: providerString) {
            selectedAPIProvider = provider
        }
    }
    
    var currentAPIKey: String {
        switch selectedAPIProvider {
        case .claude:
            return claudeAPIKey
        case .openai:
            return openaiAPIKey
        }
    }
    
    var isAPIKeyConfigured: Bool {
        return !currentAPIKey.isEmpty
    }
    
    private func checkInitialPermissions() {
        // Check if accessibility permissions are granted
        let hasAccessibility = AXIsProcessTrusted()
        
        if !hasAccessibility {
            print("⚠️ Accessibility permissions not granted - will show permissions dialog")
            shouldShowPermissionsOnStartup = true
        } else {
            print("✅ All required permissions are granted")
        }
    }
    
    func saveHotkeyConfig(_ config: HotkeyConfig) {
        customHotkey = config
        if let data = try? JSONEncoder().encode(config) {
            KeychainHelper.save(String(data: data, encoding: .utf8) ?? "", service: keychainService, account: hotkeyItem)
        }
        
        // Restart hotkey manager with new config
        hotkeyManager?.stopMonitoring()
        setupHotkeyManager()
    }
    
    private func loadHotkeyConfig() {
        if let configData = KeychainHelper.load(service: keychainService, account: hotkeyItem),
           let data = configData.data(using: .utf8),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            customHotkey = config
        }
    }
    
    func saveRephraseStyle(_ style: RephraseStyleOption) {
        selectedRephraseStyle = style
        saveRephraseStyleOption(style)
    }
    
    private func saveRephraseStyleOption(_ option: RephraseStyleOption) {
        switch option {
        case .builtin(let style):
            // Save as legacy format for compatibility
            if let data = try? JSONEncoder().encode(style) {
                KeychainHelper.save(String(data: data, encoding: .utf8) ?? "", service: keychainService, account: rephraseStyleItem)
            }
            // Also save the option type
            let optionData = ["type": "builtin", "value": style.rawValue]
            if let data = try? JSONSerialization.data(withJSONObject: optionData),
               let jsonString = String(data: data, encoding: .utf8) {
                KeychainHelper.save(jsonString, service: keychainService, account: rephraseStyleOptionItem)
            }
        case .custom(let customStyle):
            // Save custom style ID reference
            let optionData = ["type": "custom", "value": customStyle.id.uuidString]
            if let data = try? JSONSerialization.data(withJSONObject: optionData),
               let jsonString = String(data: data, encoding: .utf8) {
                KeychainHelper.save(jsonString, service: keychainService, account: rephraseStyleOptionItem)
            }
        }
    }
    
    private func loadRephraseStyle() {
        // Try to load new format first
        if let optionData = KeychainHelper.load(service: keychainService, account: rephraseStyleOptionItem),
           let data = optionData.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let type = json["type"],
           let value = json["value"] {
            
            switch type {
            case "builtin":
                if let style = RephraseStyle(rawValue: value) {
                    selectedRephraseStyle = .builtin(style)
                }
            case "custom":
                if let uuid = UUID(uuidString: value),
                   let customStyle = styleManager.customStyles.first(where: { $0.id == uuid }) {
                    selectedRephraseStyle = .custom(customStyle)
                }
            default:
                break
            }
        } else {
            // Fallback to legacy format
            if let styleData = KeychainHelper.load(service: keychainService, account: rephraseStyleItem),
               let data = styleData.data(using: .utf8),
               let style = try? JSONDecoder().decode(RephraseStyle.self, from: data) {
                selectedRephraseStyle = .builtin(style)
            }
        }
    }
    
    private func setupHotkeyManager() {
        hotkeyManager = GlobalHotkeyManager(appState: self)
    }
    
    private func configureBackgroundBehavior() {
        // Configure the application to run in the background
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Prevent the application from terminating when the last window closes
        NSApplication.shared.servicesProvider = self
        
        // Register for application lifecycle notifications
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🔄 Application will terminate - cleaning up background services")
            self.hotkeyManager?.stopMonitoring()
        }
        
        // Keep the app running in background even when no windows are open
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("✅ Application became active - ensuring background services are running")
            if self.hotkeyManager == nil {
                self.setupHotkeyManager()
            }
        }
        
        print("🔄 Configured application for background operation")
    }
    
    // MARK: - Application Restart
    func restartApplication() {
        print("🔄 Restarting application...")
        
        // Clean up resources before restart
        cleanupBeforeRestart()
        
        // Get the current application bundle path
        let bundlePath = Bundle.main.bundlePath
        
        // Create a restart script that will:
        // 1. Wait for current process to terminate
        // 2. Launch the app again
        let restartScript = """
        #!/bin/bash
        sleep 0.5
        open "\(bundlePath)"
        """
        
        // Write the restart script to a temporary file
        let tempDir = NSTemporaryDirectory()
        let scriptPath = "\(tempDir)restart_rephraser.sh"
        
        do {
            try restartScript.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            
            // Make the script executable
            let fileManager = FileManager.default
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            // Execute the restart script in background
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = [scriptPath]
            task.launch()
            
            print("✅ Restart script launched successfully")
            
            // Terminate the current app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApplication.shared.terminate(nil)
            }
            
        } catch {
            print("❌ Failed to create restart script: \(error)")
            // Fallback: just terminate the app
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func cleanupBeforeRestart() {
        print("🧹 Cleaning up before restart...")
        
        // Stop hotkey monitoring
        hotkeyManager?.stopMonitoring()
        
        // Clear any temporary states
        isProcessing = false
        lastError = nil
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Save any pending data
        if !claudeAPIKey.isEmpty {
            saveClaudeAPIKey(claudeAPIKey)
        }
        if !openaiAPIKey.isEmpty {
            saveOpenAIAPIKey(openaiAPIKey)
        }
        saveAPIProvider(selectedAPIProvider)
        
        print("✅ Cleanup completed")
    }
    
    // MARK: - Direct Text Rephrasing
    @MainActor
    func rephraseText(_ text: String, style: RephraseStyleOption? = nil, provider: APIProvider? = nil) async -> Result<String, RephraserError> {
        // Check if API key is configured
        guard isAPIKeyConfigured else {
            return .failure(.apiKeyMissing)
        }
        
        // Validate input text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return .failure(.textTooShort)
        }
        
        guard trimmedText.count <= 4000 else {
            return .failure(.textTooLong(trimmedText.count))
        }
        
        // Use provided style or current selected style
        let useStyle = style ?? selectedRephraseStyle
        let useProvider = provider ?? selectedAPIProvider
        
        // Set processing state
        isProcessing = true
        lastError = nil
        
        do {
            let rephrasedText: String
            
            switch useProvider {
            case .claude:
                let claudeAPI = ClaudeAPI(apiKey: claudeAPIKey)
                rephrasedText = try await claudeAPI.rephraseWithPrompt(text: trimmedText, prompt: useStyle.prompt)
            case .openai:
                let openaiAPI = OpenAIAPI(apiKey: openaiAPIKey)
                rephrasedText = try await openaiAPI.rephraseWithPrompt(text: trimmedText, prompt: useStyle.prompt)
            }
            
            // Add successful entry to history
            history.addEntry(
                original: trimmedText,
                rephrased: rephrasedText,
                appName: "Direct Input",
                style: useStyle.displayName,
                apiProvider: useProvider
            )
            
            isProcessing = false
            return .success(rephrasedText)
            
        } catch {
            isProcessing = false
            let rephraserError = convertToRephraserError(error, provider: useProvider)
            lastError = rephraserError.errorDescription
            
            // Add failed entry to history
            history.addFailedEntry(
                original: trimmedText,
                errorMessage: rephraserError.errorDescription ?? "Unknown error",
                appName: "Direct Input",
                style: useStyle.displayName,
                apiProvider: useProvider
            )
            
            return .failure(rephraserError)
        }
    }
    
    private func convertToRephraserError(_ error: Error, provider: APIProvider) -> RephraserError {
        if let rephraserError = error as? RephraserError {
            return rephraserError
        }
        
        switch provider {
        case .claude:
            if let claudeError = error as? ClaudeAPIError {
                switch claudeError {
                case .networkError(let message):
                    return .networkError(message)
                case .apiError(let message):
                    if message.lowercased().contains("invalid") && message.lowercased().contains("api") {
                        return .apiKeyInvalid
                    }
                    return .apiError(message)
                case .httpError(let code):
                    if code == 401 {
                        return .apiKeyInvalid
                    } else if code >= 500 {
                        return .apiError("Claude server error (Code: \(code))")
                    } else {
                        return .apiError("Claude HTTP error (Code: \(code))")
                    }
                case .invalidResponse:
                    return .apiError("Invalid response from Claude API")
                case .noContent:
                    return .apiError("No content received from Claude API")
                }
            }
        case .openai:
            if let openaiError = error as? OpenAIAPIError {
                switch openaiError {
                case .networkError(let message):
                    return .networkError(message)
                case .apiError(let message):
                    if message.lowercased().contains("invalid") && message.lowercased().contains("api") {
                        return .apiKeyInvalid
                    }
                    return .apiError(message)
                case .httpError(let code):
                    if code == 401 {
                        return .apiKeyInvalid
                    } else if code >= 500 {
                        return .apiError("OpenAI server error (Code: \(code))")
                    } else {
                        return .apiError("OpenAI HTTP error (Code: \(code))")
                    }
                case .invalidResponse:
                    return .apiError("Invalid response from OpenAI API")
                case .noContent:
                    return .apiError("No content received from OpenAI API")
                }
            }
        }
        
        return .unexpectedError(error.localizedDescription)
    }
    
    // Alternative restart method using NSWorkspace (more reliable)
    func restartApplicationAlternative() {
        print("🔄 Restarting application (alternative method)...")
        
        cleanupBeforeRestart()
        
        let bundlePath = Bundle.main.bundlePath
        
        // Use NSWorkspace to relaunch the app
        let url = URL(fileURLWithPath: bundlePath)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true
        
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { (app, error) in
            if let error = error {
                print("❌ Failed to restart application: \(error)")
            } else {
                print("✅ Application restart initiated")
            }
            
            // Terminate current instance
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}