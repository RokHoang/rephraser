//
//  MenuBarView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var permissionsManager = PermissionsManager()
    @State private var showingPermissions = false
    @State private var showingHistory = false
    @State private var showingStylePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "text.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rephraser")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("AI-powered text enhancement")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if appState.isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                
                // Status Cards
                VStack(spacing: 8) {
                    StatusCard(
                        icon: "key.fill",
                        title: "API Key",
                        status: appState.claudeAPIKey.isEmpty ? "Not configured" : "Ready",
                        isPositive: !appState.claudeAPIKey.isEmpty,
                        action: { 
                            // Open Settings to configure API key
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    )
                    
                    StatusCard(
                        icon: "lock.shield.fill",
                        title: "Accessibility",
                        status: permissionsManager.accessibilityPermissionGranted ? "Enabled" : "Required",
                        isPositive: permissionsManager.accessibilityPermissionGranted,
                        action: { showingPermissions = true }
                    )
                    
                    StylePickerCard(
                        selectedStyle: appState.selectedRephraseStyle,
                        onStyleChange: { newStyle in
                            appState.saveRephraseStyle(newStyle)
                        },
                        showingStylePicker: $showingStylePicker
                    )
                    .environmentObject(appState)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Usage Instructions
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("How to use")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("Select text and press \(appState.customHotkey.displayName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Menu Items
            VStack(spacing: 2) {
                MenuButton(
                    icon: "clock.arrow.circlepath",
                    title: "History",
                    shortcut: "H",
                    action: { showingHistory = true }
                )
                
                MenuButton(
                    icon: "shield.checkered",
                    title: "Permissions",
                    shortcut: "P",
                    action: { showingPermissions = true }
                )
                
                MenuButton(
                    icon: "gearshape.fill",
                    title: "Settings",
                    shortcut: ",",
                    action: { },
                    isSettingsLink: true
                )
                
                Divider()
                    .padding(.horizontal, 12)
                
                MenuButton(
                    icon: "power",
                    title: "Quit Rephraser",
                    shortcut: "Q",
                    action: { NSApplication.shared.terminate(nil) },
                    isDestructive: true
                )
            }
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionsManager.checkPermissions()
            
            // Show permissions dialog on startup if needed
            if appState.shouldShowPermissionsOnStartup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingPermissions = true
                    appState.shouldShowPermissionsOnStartup = false
                }
            }
        }
        .sheet(isPresented: $showingPermissions) {
            PermissionsView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $appState.errorHandler.showingErrorDetails) {
            if let error = appState.errorHandler.lastError {
                ErrorDetailView(
                    error: error,
                    onDismiss: {
                        appState.errorHandler.showingErrorDetails = false
                    },
                    onAction: {
                        handleErrorAction(for: error)
                    }
                )
            }
        }
    }
    
    private func handleErrorAction(for error: RephraserError) {
        switch error.category {
        case .configuration:
            // Open Settings window
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        case .permissions:
            // Open System Settings
            showingPermissions = true
        default:
            // For other errors, just dismiss (user can manually retry)
            break
        }
    }
}

// MARK: - Custom Components

struct StatusCard: View {
    let icon: String
    let title: String
    let status: String
    let isPositive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .orange)
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(isPositive ? .green : .orange)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.quaternaryLabelColor))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let shortcut: String
    let action: () -> Void
    var isSettingsLink: Bool = false
    var isDestructive: Bool = false
    
    var body: some View {
        Group {
            if isSettingsLink {
                SettingsLink {
                    MenuButtonContent(
                        icon: icon,
                        title: title,
                        shortcut: shortcut,
                        isDestructive: isDestructive
                    )
                }
                .keyboardShortcut(",")
            } else {
                Button(action: action) {
                    MenuButtonContent(
                        icon: icon,
                        title: title,
                        shortcut: shortcut,
                        isDestructive: isDestructive
                    )
                }
                .keyboardShortcut(KeyEquivalent(Character(shortcut.lowercased())))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MenuButtonContent: View {
    let icon: String
    let title: String
    let shortcut: String
    let isDestructive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(isDestructive ? .red : .primary)
                .frame(width: 16, height: 16)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(isDestructive ? .red : .primary)
            
            Spacer()
            
            Text("⌘\(shortcut)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Style Picker Card
struct StylePickerCard: View {
    let selectedStyle: RephraseStyleOption
    let onStyleChange: (RephraseStyleOption) -> Void
    @Binding var showingStylePicker: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: {
            showingStylePicker.toggle()
        }) {
            HStack(spacing: 10) {
                Image(systemName: selectedStyle.icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Style")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(selectedStyle.displayName)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(showingStylePicker ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: showingStylePicker)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.quaternaryLabelColor))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .popover(isPresented: $showingStylePicker, arrowEdge: .bottom) {
            StylePickerPopover(
                selectedStyle: selectedStyle,
                onStyleChange: { newStyle in
                    onStyleChange(newStyle)
                    showingStylePicker = false
                },
                onCreateCustom: {
                    showingStylePicker = false
                    // Open Settings window to create custom style
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            )
            .environmentObject(appState)
        }
    }
}

// MARK: - Style Picker Popover
struct StylePickerPopover: View {
    let selectedStyle: RephraseStyleOption
    let onStyleChange: (RephraseStyleOption) -> Void
    let onCreateCustom: () -> Void
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Choose Style")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Create Custom") {
                    onCreateCustom()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Style List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(appState.styleManager.allStyles) { style in
                        StyleOptionRow(
                            style: style,
                            isSelected: style.id == selectedStyle.id,
                            onSelect: {
                                onStyleChange(style)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Style Option Row
struct StyleOptionRow: View {
    let style: RephraseStyleOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(style.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        if style.isCustom {
                            Text("CUSTOM")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .orange)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(isSelected ? Color.white.opacity(0.2) : Color.orange.opacity(0.1))
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            // Add subtle hover effect for non-selected items
            if !isSelected {
                // Handle hover state if needed
            }
        }
    }
}