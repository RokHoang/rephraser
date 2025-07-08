//
//  SettingsView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKeyInput: String = ""
    @State private var showingPermissions = false
    @State private var isTestingConnection = false
    @State private var testResult: String = ""
    @State private var showingDiagnostics = false
    @StateObject private var networkDiagnostics = NetworkDiagnostics()
    @State private var selectedHotkey: HotkeyConfig = HotkeyConfig.defaultHotkey
    @State private var selectedStyle: RephraseStyleOption = .builtin(.standard)
    @State private var showingCustomStyleEditor = false
    @State private var editingCustomStyle: CustomRephraseStyle?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Rephraser Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            TabView {
                // API Configuration Tab
                VStack(alignment: .leading, spacing: 16) {
                    Text("Claude API Configuration")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SecureField("Enter your Claude API key", text: $apiKeyInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack(spacing: 12) {
                            Button("Save") {
                                if validateAPIKey(apiKeyInput) {
                                    appState.saveAPIKey(apiKeyInput)
                                    testResult = "✅ API key saved successfully"
                                } else {
                                    testResult = "❌ Invalid API key format"
                                }
                            }
                            .disabled(apiKeyInput.isEmpty)
                            .buttonStyle(.borderedProminent)
                            
                            Button("Test Connection") {
                                testConnection()
                            }
                            .disabled(apiKeyInput.isEmpty || isTestingConnection)
                            .buttonStyle(.bordered)
                            
                            Button("Network Diagnostics") {
                                showingDiagnostics = true
                            }
                            .buttonStyle(.bordered)
                            
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if !testResult.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: testResult.contains("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(testResult.contains("✅") ? .green : .red)
                                    Text(testResult.contains("✅") ? "Connection Test Successful" : "Connection Test Failed")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(testResult.contains("✅") ? .green : .red)
                                }
                                
                                if testResult.contains("✅") {
                                    ScrollView {
                                        Text(testResult)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .textSelection(.enabled)
                                    }
                                    .frame(maxHeight: 60)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                } else {
                                    Text(testResult)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Get your API key from: https://console.anthropic.com/")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .tabItem {
                    Label("API", systemImage: "key")
                }
                
                // Permissions Tab
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Permissions")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                            Text("Accessibility Access")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("Rephraser needs accessibility permissions to monitor keyboard shortcuts and manipulate text.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button("Check Permissions") {
                            showingPermissions = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
                
                // Usage Tab
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Use")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Instructions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("1.")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .frame(width: 20, alignment: .leading)
                                Text("Select text in any application")
                            }
                            
                            HStack {
                                Text("2.")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .frame(width: 20, alignment: .leading)
                                Text("Press Cmd+C three times quickly")
                            }
                            
                            HStack {
                                Text("3.")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .frame(width: 20, alignment: .leading)
                                Text("The selected text will be replaced with a rephrased version")
                            }
                        }
                        
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Note: Make sure accessibility permissions are granted for the app to work.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .tabItem {
                    Label("Usage", systemImage: "questionmark.circle")
                }
                
                // Hotkey Settings Tab
                VStack(alignment: .leading, spacing: 16) {
                    Text("Hotkey Configuration")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundColor(.blue)
                            Text("Custom Shortcut")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("Choose a keyboard shortcut to trigger text rephrasing.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available Shortcuts:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(HotkeyConfig.availableHotkeys, id: \.displayName) { hotkey in
                                    Button(action: {
                                        selectedHotkey = hotkey
                                        appState.saveHotkeyConfig(hotkey)
                                    }) {
                                        HStack {
                                            Text(hotkey.displayName)
                                                .font(.system(.body, design: .monospaced))
                                            Spacer()
                                            if selectedHotkey == hotkey {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedHotkey == hotkey ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Current shortcut: \(selectedHotkey.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
                
                // Rephrase Style Tab
                VStack(alignment: .leading, spacing: 16) {
                    Text("Rephrase Styles")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.word.spacing")
                                .foregroundColor(.blue)
                            Text("Writing Style")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("Choose how you want your text to be rephrased.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(appState.styleManager.allStyles) { styleOption in
                                Button(action: {
                                    selectedStyle = styleOption
                                    appState.saveRephraseStyle(styleOption)
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: styleOption.icon)
                                                .foregroundColor(selectedStyle == styleOption ? .white : .blue)
                                                .frame(width: 20)
                                            Text(styleOption.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedStyle == styleOption ? .white : .primary)
                                            Spacer()
                                            if selectedStyle == styleOption {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                            }
                                            if styleOption.isCustom {
                                                Button(action: {
                                                    if case .custom(let customStyle) = styleOption {
                                                        editingCustomStyle = customStyle
                                                        showingCustomStyleEditor = true
                                                    }
                                                }) {
                                                    Image(systemName: "pencil")
                                                        .foregroundColor(selectedStyle == styleOption ? .white : .secondary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        
                                        Text(styleOption.description)
                                            .font(.caption)
                                            .foregroundColor(selectedStyle == styleOption ? .white.opacity(0.8) : .secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(12)
                                    .background(selectedStyle == styleOption ? Color.blue : Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Button("Create Custom Style") {
                                    editingCustomStyle = nil
                                    showingCustomStyleEditor = true
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("Current style: \(selectedStyle.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .tabItem {
                    Label("Styles", systemImage: "text.word.spacing")
                }
            
            // History Tab
            VStack(spacing: 0) {
                HistoryTabContent()
                    .environmentObject(appState)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
        }
        .frame(width: 650, height: 550)
        .onAppear {
            apiKeyInput = appState.claudeAPIKey
            selectedHotkey = appState.customHotkey
            selectedStyle = appState.selectedRephraseStyle
        }
        .sheet(isPresented: $showingPermissions) {
            PermissionsView()
        }
        .sheet(isPresented: $showingDiagnostics) {
            NetworkDiagnosticsView()
        }
        .sheet(isPresented: $showingCustomStyleEditor) {
            CustomStyleEditorView(
                style: editingCustomStyle,
                onSave: { customStyle in
                    if editingCustomStyle != nil {
                        appState.styleManager.updateCustomStyle(customStyle)
                    } else {
                        appState.styleManager.addCustomStyle(customStyle)
                    }
                },
                onDelete: { customStyle in
                    appState.styleManager.removeCustomStyle(customStyle)
                    // If the deleted style was selected, switch to standard
                    if case .custom(let selectedCustom) = selectedStyle, selectedCustom.id == customStyle.id {
                        selectedStyle = .builtin(.standard)
                        appState.saveRephraseStyle(.builtin(.standard))
                    }
                }
            )
        }
    }
}
    
    private func testConnection() {
        isTestingConnection = true
        testResult = ""
        
        Task {
            do {
                let claudeAPI = ClaudeAPI(apiKey: apiKeyInput)
                let startTime = Date()
                let response = try await claudeAPI.rephraseWithPrompt(text: "Hello world", prompt: selectedStyle.prompt)
                let endTime = Date()
                let responseTime = Int((endTime.timeIntervalSince(startTime)) * 1000)
                
                DispatchQueue.main.async {
                    self.testResult = "✅ Connection successful! Response: \"\(response)\" (⚡ \(responseTime)ms)"
                    self.isTestingConnection = false
                }
            } catch {
                DispatchQueue.main.async {
                    let rephraserError = self.convertToRephraserError(error)
                    self.testResult = "❌ \(rephraserError.errorDescription ?? "Unknown error")"
                    if let recovery = rephraserError.recoverySuggestion {
                        self.testResult += "\n💡 \(recovery)"
                    }
                    self.isTestingConnection = false
                }
            }
        }
    }
    
    private func validateAPIKey(_ key: String) -> Bool {
        // Basic validation for Claude API key format
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Claude API keys typically start with "sk-ant-" and are around 100+ characters
        return trimmedKey.hasPrefix("sk-ant-") && trimmedKey.count > 50
    }
    
    private func convertToRephraserError(_ error: Error) -> RephraserError {
        if let rephraserError = error as? RephraserError {
            return rephraserError
        }
        
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
                    return .apiError("Server error (Code: \(code))")
                } else {
                    return .apiError("HTTP error (Code: \(code))")
                }
            case .invalidResponse:
                return .apiError("Invalid response from Claude API")
            case .noContent:
                return .apiError("No content received from Claude API")
            }
        }
        
        return .unexpectedError(error.localizedDescription)
    }
}

// MARK: - Custom Style Editor
struct CustomStyleEditorView: View {
    let style: CustomRephraseStyle?
    let onSave: (CustomRephraseStyle) -> Void
    let onDelete: ((CustomRephraseStyle) -> Void)?
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var prompt: String = ""
    @State private var selectedIcon: String = "text.cursor"
    @Environment(\.dismiss) private var dismiss
    
    private let availableIcons = [
        "text.cursor", "text.alignleft", "graduationcap", "message",
        "text.word.spacing", "paintbrush", "briefcase", "star",
        "heart", "bolt", "crown", "flame"
    ]
    
    var isEditing: Bool {
        style != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(isEditing ? "Edit Custom Style" : "Create Custom Style")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style Name")
                            .font(.headline)
                        TextField("Enter style name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        TextField("Brief description of this style", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Icon selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Prompt field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Prompt")
                            .font(.headline)
                        
                        Text("This prompt will be sent to Claude AI. Include instructions for how to rephrase the text.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $prompt)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Tip: End your prompt with 'Only return the rephrased text, nothing else:' for best results.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                if isEditing, let style = style {
                    Button("Delete Style") {
                        onDelete?(style)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button(isEditing ? "Update" : "Create") {
                    let newStyle = CustomRephraseStyle(
                        name: name,
                        description: description,
                        prompt: prompt,
                        icon: selectedIcon
                    )
                    onSave(newStyle)
                    dismiss()
                }
                .disabled(name.isEmpty || description.isEmpty || prompt.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 600)
        .onAppear {
            if let style = style {
                name = style.name
                description = style.description
                prompt = style.prompt
                selectedIcon = style.icon
            } else {
                // Set default prompt template
                prompt = "Please rephrase the following text to [describe your style here]. Only return the rephrased text, nothing else:"
            }
        }
    }
}

// MARK: - History Tab Content
struct HistoryTabContent: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedEntry: RephrasingEntry? = nil
    
    var filteredEntries: [RephrasingEntry] {
        if searchText.isEmpty {
            return appState.history.entries
        } else {
            return appState.history.entries.filter { entry in
                entry.originalText.localizedCaseInsensitiveContains(searchText) ||
                entry.rephrasedText.localizedCaseInsensitiveContains(searchText) ||
                (entry.appName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with search and clear
            VStack(spacing: 12) {
                HStack {
                    Text("Rephrasing History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(appState.history.entries.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Clear All") {
                        appState.history.clearHistory()
                    }
                    .disabled(appState.history.entries.isEmpty)
                    .buttonStyle(.bordered)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search history...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
            
            // History list
            if filteredEntries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No rephrasing history yet" : "No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Start rephrasing text to see history here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredEntries) { entry in
                            CompactHistoryEntryView(entry: entry) {
                                appState.history.deleteEntry(entry)
                            }
                            .onTapGesture {
                                selectedEntry = entry
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            HistoryDetailView(entry: entry)
        }
    }
}

// MARK: - Compact History Entry for Settings Tab
struct CompactHistoryEntryView: View {
    let entry: RephrasingEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp and app info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let appName = entry.appName {
                    Text(appName)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(3)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            // Text content
            VStack(alignment: .leading, spacing: 6) {
                // Original text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Original")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(entry.shortOriginal)
                        .font(.caption)
                        .lineLimit(2)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(3)
                }
                
                // Rephrased text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rephrased")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(entry.shortRephrased)
                        .font(.caption)
                        .lineLimit(2)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(3)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete this entry")
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
        .contentShape(Rectangle())
    }
}