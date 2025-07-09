//
//  SettingsView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAPIProvider: APIProvider = .claude
    @State private var claudeAPIKey = ""
    @State private var openaiAPIKey = ""
    @State private var selectedStyle: RephraseStyleOption = .builtin(.standard)
    @State private var isTestingConnection = false
    @State private var testResult = ""
    @State private var directInputText = ""
    @State private var directRephraseResult = ""
    @State private var showingDirectResult = false
    @State private var showingCustomStyleEditor = false
    @State private var editingCustomStyle: CustomRephraseStyle?
    
    private var currentAPIKeyValue: String {
        switch selectedAPIProvider {
        case .claude:
            return claudeAPIKey
        case .openai:
            return openaiAPIKey
        }
    }
    
    @ViewBuilder
    private var currentAPIKeyInput: some View {
        switch selectedAPIProvider {
        case .claude:
            claudeAPIKeyInput
        case .openai:
            openaiAPIKeyInput
        }
    }
    
    private var claudeAPIKeyInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Claude API Key")
                .font(.subheadline)
                .fontWeight(.medium)
            
            SecureField("Enter your Claude API key", text: $claudeAPIKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var openaiAPIKeyInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OpenAI API Key")
                .font(.subheadline)
                .fontWeight(.medium)
            
            SecureField("Enter your OpenAI API key", text: $openaiAPIKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    var body: some View {
        settingsContent
            .onAppear {
                // Initialize values when the view appears
                selectedAPIProvider = appState.selectedAPIProvider
                selectedStyle = appState.selectedRephraseStyle
                
                // Load the appropriate API keys
                claudeAPIKey = appState.claudeAPIKey
                openaiAPIKey = appState.openaiAPIKey
            }
    }
    
    private var settingsContent: some View {
        VStack(spacing: 0) {
            headerView
            settingsTabView
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            Text("Rephraser Settings")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var settingsTabView: some View {
        TabView {
            apiConfigurationTab
                .tabItem {
                    Label("API", systemImage: "key")
                }
            stylesTab
                .tabItem {
                    Label("Styles", systemImage: "textformat")
                }
            directInputTab
                .tabItem {
                    Label("Direct Input", systemImage: "text.cursor")
                }
            historyTab
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            hotkeysTab
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var apiConfigurationTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI API Configuration")
                .font(.headline)
                .padding(.bottom, 8)
                    
            // API Provider Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Provider")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("API Provider", selection: $selectedAPIProvider) {
                    ForEach(APIProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName)
                            .tag(provider)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedAPIProvider) { newProvider in
                    // Load the appropriate API key when provider changes
                    switch newProvider {
                    case .claude:
                        claudeAPIKey = appState.claudeAPIKey
                    case .openai:
                        openaiAPIKey = appState.openaiAPIKey
                    }
                }
            }
            
            // API Key Input
            VStack(alignment: .leading, spacing: 12) {
                currentAPIKeyInput
                
                HStack {
                    Button("Save API Key") {
                        // Save the API key to the app state
                        switch selectedAPIProvider {
                        case .claude:
                            appState.claudeAPIKey = claudeAPIKey
                        case .openai:
                            appState.openaiAPIKey = openaiAPIKey
                        }
                        
                        // Test the connection if key is valid
                        if validateAPIKey(currentAPIKeyValue, provider: selectedAPIProvider) {
                            testConnection()
                        }
                    }
                    .disabled(currentAPIKeyValue.isEmpty)
                    .buttonStyle(.borderedProminent)
                    
                    if !currentAPIKeyValue.isEmpty {
                        Button("Test Connection") {
                            testConnection()
                        }
                        .disabled(isTestingConnection)
                    }
                }
                
                // Test Result
                if !testResult.isEmpty {
                    ScrollView {
                        Text(testResult)
                            .font(.caption)
                            .foregroundColor(testResult.hasPrefix("✅") ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            
            if isTestingConnection {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Testing connection...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var stylesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rephrase Styles")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Default Style Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Default Style")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // 2x3 Grid for style selection
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(appState.styleManager.allStyles.prefix(6), id: \.self) { style in
                        Button(action: {
                            selectedStyle = style
                            appState.selectedRephraseStyle = style
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: style.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedStyle == style ? .white : .blue)
                                
                                Text(style.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedStyle == style ? .white : .primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .padding(.vertical, 8)
                            .background(selectedStyle == style ? Color.blue : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Text("Selected: \(selectedStyle.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Style Management
            VStack(alignment: .leading, spacing: 12) {
                Text("Style Management")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Button("Create Custom Style") {
                        showingCustomStyleEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Import Styles") {
                        // TODO: Implement import functionality
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
                
                // Custom Styles List
                if !appState.styleManager.customStyles.isEmpty {
                    Text("Custom Styles:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(appState.styleManager.customStyles) { style in
                                HStack {
                                    Image(systemName: style.icon)
                                        .foregroundColor(.orange)
                                    Text(style.name)
                                    Spacer()
                                    Button("Edit") {
                                        editingCustomStyle = style
                                        showingCustomStyleEditor = true
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var directInputTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Direct Input")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Input text area
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter text to rephrase:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextEditor(text: $directInputText)
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Rephrase button
            HStack {
                Button("Rephrase") {
                    Task {
                        await performDirectRephrase()
                    }
                }
                .disabled(directInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            
            // Result area
            if !directRephraseResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView {
                        Text(directRephraseResult)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                    
                    HStack {
                        Button("Copy Result") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(directRephraseResult, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Use as Input") {
                            directInputText = directRephraseResult
                            directRephraseResult = ""
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var historyTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rephrase History")
                .font(.headline)
                .padding(.bottom, 8)
            
            // History Controls
            HStack {
                Text("\(appState.history.entries.count) entries")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Clear History") {
                    appState.history.clearHistory()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            
            Divider()
            
            // History List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(appState.history.entries.prefix(50)) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: entry.apiProvider.icon)
                                    .foregroundColor(.blue)
                                Text(entry.displayTimestamp)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let appName = entry.appName {
                                    Text(appName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(entry.shortOriginal)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text(entry.shortRephrased)
                                .font(.caption)
                                .foregroundColor(entry.isSuccess ? .blue : .red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .frame(maxHeight: 300)
            
            if appState.history.entries.count > 50 {
                Text("Showing most recent 50 entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var hotkeysTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hotkeys")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Main Hotkey Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Main Rephrase Hotkey")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // 2x3 Grid for hotkey selection
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(HotkeyConfig.availableHotkeys.prefix(6), id: \.displayName) { hotkey in
                        Button(action: {
                            appState.customHotkey = hotkey
                            appState.saveHotkeyConfig(hotkey)
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "keyboard")
                                    .font(.title2)
                                    .foregroundColor(appState.customHotkey.displayName == hotkey.displayName ? .white : .blue)
                                
                                Text(hotkey.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(appState.customHotkey.displayName == hotkey.displayName ? .white : .primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .padding(.vertical, 8)
                            .background(appState.customHotkey.displayName == hotkey.displayName ? Color.blue : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Text("Selected: \(appState.customHotkey.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Press this key combination when text is selected to rephrase it")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Accessibility Note
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessibility Permission Required")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Hotkeys require accessibility permission to function. Click the button below to grant permission.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Open System Settings") {
                    // Open System Settings to Privacy & Security > Accessibility
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Rephraser")
                .font(.headline)
                .padding(.bottom, 8)
            
            // App Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "text.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Rephraser")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("AI-powered text enhancement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                Text("Features")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Multiple AI providers (Claude, OpenAI)")
                            .font(.caption)
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Customizable rephrase styles")
                            .font(.caption)
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Global hotkey support")
                            .font(.caption)
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("History tracking")
                            .font(.caption)
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Direct input mode")
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            // Usage Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Usage Tips")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Select text and press your hotkey to rephrase")
                        .font(.caption)
                    Text("• Use Direct Input for standalone text rephrasing")
                        .font(.caption)
                    Text("• Create custom styles for specific tones")
                        .font(.caption)
                    Text("• Check History to review past rephrasings")
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Helper Functions
    
    private func validateAPIKey(_ key: String, provider: APIProvider) -> Bool {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return false }
        
        switch provider {
        case .claude:
            // Claude API keys typically start with "sk-ant-" and are around 100+ characters
            return trimmedKey.hasPrefix("sk-ant-") && trimmedKey.count > 50
        case .openai:
            // OpenAI API keys typically start with "sk-" and are around 50+ characters
            return trimmedKey.hasPrefix("sk-") && trimmedKey.count > 40
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = ""
        
        Task {
            do {
                let startTime = Date()
                let response: String
                
                switch selectedAPIProvider {
                case .claude:
                    let claudeAPI = ClaudeAPI(apiKey: currentAPIKeyValue)
                    response = try await claudeAPI.rephraseWithPrompt(text: "Hello world", prompt: selectedStyle.prompt)
                case .openai:
                    let openaiAPI = OpenAIAPI(apiKey: currentAPIKeyValue)
                    response = try await openaiAPI.rephraseWithPrompt(text: "Hello world", prompt: selectedStyle.prompt)
                }
                
                let duration = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    testResult = "✅ Connection successful! Response time: \(String(format: "%.2f", duration))s\n\nResponse: \(response)"
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ Connection failed: \(error.localizedDescription)"
                    isTestingConnection = false
                }
            }
        }
    }
    
    private func performDirectRephrase() async {
        let result = await appState.rephraseText(directInputText, style: selectedStyle)
        
        switch result {
        case .success(let rephrasedText):
            directRephraseResult = rephrasedText
        case .failure(let error):
            appState.errorHandler.handle(error, context: "Direct Input - Settings")
        }
    }
}