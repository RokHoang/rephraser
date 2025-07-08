//
//  AppState.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation
import SwiftUI
import ApplicationServices

class AppState: ObservableObject {
    @Published var claudeAPIKey: String = ""
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
    private let apiKeyItem = "claude-api-key"
    private let hotkeyItem = "custom-hotkey"
    private let rephraseStyleItem = "rephrase-style"
    private let rephraseStyleOptionItem = "rephrase-style-option"
    private var hotkeyManager: GlobalHotkeyManager?
    
    init() {
        loadAPIKey()
        loadHotkeyConfig()
        loadRephraseStyle()
        checkInitialPermissions()
        setupHotkeyManager()
    }
    
    func saveAPIKey(_ key: String) {
        claudeAPIKey = key
        KeychainHelper.save(key, service: keychainService, account: apiKeyItem)
    }
    
    private func loadAPIKey() {
        if let key = KeychainHelper.load(service: keychainService, account: apiKeyItem) {
            claudeAPIKey = key
        }
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
}