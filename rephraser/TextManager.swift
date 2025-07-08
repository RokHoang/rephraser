//
//  TextManager.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation
import AppKit
import UserNotifications

class TextManager {
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func processSelectedText() {
        guard !appState.isProcessing else { 
            return 
        }
        
        // Validate preconditions
        guard !appState.claudeAPIKey.isEmpty else {
            appState.errorHandler.handle(RephraserError.apiKeyMissing, context: "processSelectedText")
            return
        }
        
        appState.isProcessing = true
        
        // Show visual feedback
        appState.processingIndicator.show(message: "Getting selected text...")
        
        // Capture the original app information at the start
        let originalApp = getCurrentApp()
        
        Task {
            do {
                let selectedText = try await getSelectedText()
                
                // Validate selected text
                try validateSelectedText(selectedText)
                
                // Update feedback message
                await MainActor.run {
                    appState.processingIndicator.updateMessage("Rephrasing with \(appState.selectedRephraseStyle.displayName) style...")
                }
                
                let rephrasedText = try await rephrase(text: selectedText)
                
                // Validate rephrased text
                guard !rephrasedText.isEmpty else {
                    throw RephraserError.apiError("Received empty response from Claude API")
                }
                
                // Update feedback message
                await MainActor.run {
                    appState.processingIndicator.updateMessage("Replacing text...")
                }
                
                // Switch back to original app before replacing text
                if let originalApp = originalApp {
                    do {
                        try await switchToApp(originalApp)
                    } catch {
                        // Log but don't fail - we can still show success
                        await MainActor.run {
                            appState.errorHandler.handle(RephraserError.appSwitchFailed, context: "switchToApp")
                        }
                    }
                }
                
                try await replaceSelectedText(with: rephrasedText)
                
                // Save to history
                await MainActor.run {
                    appState.history.addEntry(
                        original: selectedText,
                        rephrased: rephrasedText,
                        appName: originalApp?.localizedName
                    )
                }
                
                await MainActor.run {
                    appState.processingIndicator.hide()
                    appState.isProcessing = false
                    
                    // Show success notification with character count
                    let charCount = rephrasedText.count
                    let message = "Text rephrased successfully (\(charCount) characters)"
                    NotificationManager().showSuccessNotification(
                        message: message,
                        subtitle: "Style: \(appState.selectedRephraseStyle.displayName)"
                    )
                }
                
            } catch {
                await MainActor.run {
                    appState.processingIndicator.hide()
                    appState.isProcessing = false
                    appState.errorHandler.handle(error, context: "processSelectedText")
                }
            }
        }
    }
    
    private func validateSelectedText(_ text: String) throws {
        guard !text.isEmpty else {
            throw RephraserError.noTextSelected
        }
        
        guard text.count >= 3 else {
            throw RephraserError.textTooShort
        }
        
        guard text.count <= 4000 else {
            throw RephraserError.textTooLong(text.count)
        }
    }
    
    private func getSelectedText() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let pasteboard = NSPasteboard.general
            
            // Save original pasteboard contents as strings instead of objects
            let originalString = pasteboard.string(forType: .string)
            
            do {
                pasteboard.clearContents()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let source = CGEventSource(stateID: .hidSystemState)
                    
                    guard let cmdCDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true),
                          let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false) else {
                        continuation.resume(throwing: RephraserError.clipboardAccessFailed)
                        return
                    }
                    
                    cmdCDown.flags = .maskCommand
                    cmdCUp.flags = .maskCommand
                    
                    cmdCDown.post(tap: .cghidEventTap)
                    cmdCUp.post(tap: .cghidEventTap)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let selectedText = pasteboard.string(forType: .string) ?? ""
                        
                        // Restore original pasteboard contents
                        pasteboard.clearContents()
                        if let originalString = originalString {
                            pasteboard.setString(originalString, forType: .string)
                        }
                        
                        continuation.resume(returning: selectedText)
                    }
                }
            } catch {
                continuation.resume(throwing: RephraserError.clipboardAccessFailed)
            }
        }
    }
    
    private func rephrase(text: String) async throws -> String {
        let apiKey = await MainActor.run { appState.claudeAPIKey }
        let styleOption = await MainActor.run { appState.selectedRephraseStyle }
        let claudeAPI = ClaudeAPI(apiKey: apiKey)
        
        // Add timeout to prevent hanging
        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await claudeAPI.rephraseWithPrompt(text: text, prompt: styleOption.prompt)
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: 45_000_000_000) // 45 seconds
                throw RephraserError.processingTimeout
            }
            
            guard let result = try await group.next() else {
                throw RephraserError.processingTimeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private func replaceSelectedText(with text: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let pasteboard = NSPasteboard.general
            
            // Save original pasteboard contents as string
            let originalString = pasteboard.string(forType: .string)
            
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let source = CGEventSource(stateID: .hidSystemState)
                
                let cmdVDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
                let cmdVUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
                
                cmdVDown?.flags = .maskCommand
                cmdVUp?.flags = .maskCommand
                
                cmdVDown?.post(tap: .cghidEventTap)
                cmdVUp?.post(tap: .cghidEventTap)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Restore original pasteboard contents
                    pasteboard.clearContents()
                    if let originalString = originalString {
                        pasteboard.setString(originalString, forType: .string)
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    private func getCurrentApp() -> NSRunningApplication? {
        return NSWorkspace.shared.frontmostApplication
    }
    
    private func getCurrentAppName() -> String? {
        return getCurrentApp()?.localizedName
    }
    
    private func switchToApp(_ app: NSRunningApplication) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let success = app.activate(options: [])
                
                if !success {
                    continuation.resume(throwing: RephraserError.appSwitchFailed)
                    return
                }
                
                // Give the app time to become active
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    continuation.resume()
                }
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}