//
//  PermissionsManager.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation
import AppKit
import ApplicationServices

class PermissionsManager: ObservableObject {
    @Published var accessibilityPermissionGranted: Bool = false
    @Published var isCheckingPermissions: Bool = false
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        print("🔍 Checking accessibility permissions...")
        isCheckingPermissions = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let hasPermission = AXIsProcessTrusted()
            
            DispatchQueue.main.async {
                self.accessibilityPermissionGranted = hasPermission
                self.isCheckingPermissions = false
                print("✅ Accessibility permission status: \(hasPermission)")
            }
        }
    }
    
    func requestAccessibilityPermission() {
        print("🔓 Requesting accessibility permission...")
        
        // This will prompt the user to grant permissions if not already granted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            self.accessibilityPermissionGranted = hasPermission
            if hasPermission {
                print("✅ Accessibility permission granted!")
            } else {
                print("⚠️ User needs to manually grant accessibility permission")
            }
        }
    }
    
    func openSystemPreferences() {
        print("🔧 Opening System Settings - Accessibility...")
        
        // Try the modern way first (macOS 13+)
        if #available(macOS 13.0, *) {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else {
            // Fallback for older macOS versions
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
    
    func openApplicationFolder() {
        print("📁 Opening Applications folder...")
        
        if let applicationsURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") {
            let folderURL = URL(fileURLWithPath: "/Applications")
            NSWorkspace.shared.open(folderURL)
        }
    }
    
    var permissionStatusText: String {
        if isCheckingPermissions {
            return "Checking permissions..."
        } else if accessibilityPermissionGranted {
            return "✅ Accessibility permission granted"
        } else {
            return "❌ Accessibility permission required"
        }
    }
    
    var permissionStatusColor: NSColor {
        if isCheckingPermissions {
            return .systemOrange
        } else if accessibilityPermissionGranted {
            return .systemGreen
        } else {
            return .systemRed
        }
    }
}