//
//  ErrorHandling.swift
//  rephraser
//
//  Created by Rok Hoang on 7/8/25.
//

import Foundation
import SwiftUI
import UserNotifications

enum RephraserError: LocalizedError {
    case noTextSelected
    case accessibilityPermissionDenied
    case apiKeyMissing
    case apiKeyInvalid
    case networkError(String)
    case apiError(String)
    case textTooLong(Int)
    case textTooShort
    case unexpectedError(String)
    case processingTimeout
    case clipboardAccessFailed
    case appSwitchFailed
    
    var errorDescription: String? {
        switch self {
        case .noTextSelected:
            return "No text selected. Please select some text and try again."
        case .accessibilityPermissionDenied:
            return "Accessibility permission required. Please enable it in System Settings > Security & Privacy > Accessibility."
        case .apiKeyMissing:
            return "Claude API key not configured. Please add your API key in Settings."
        case .apiKeyInvalid:
            return "Invalid Claude API key. Please check your API key in Settings."
        case .networkError(let message):
            return "Network error: \(message). Please check your internet connection."
        case .apiError(let message):
            return "Claude API error: \(message)"
        case .textTooLong(let length):
            return "Text too long (\(length) characters). Please select a shorter text (max 4000 characters)."
        case .textTooShort:
            return "Text too short. Please select at least 3 characters."
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        case .processingTimeout:
            return "Processing timed out. Please try again with shorter text."
        case .clipboardAccessFailed:
            return "Unable to access clipboard. Please ensure the app has proper permissions."
        case .appSwitchFailed:
            return "Unable to switch back to the original application."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noTextSelected:
            return "Select some text in any application and try the hotkey again."
        case .accessibilityPermissionDenied:
            return "Open System Settings > Security & Privacy > Accessibility and enable Rephraser."
        case .apiKeyMissing:
            return "Click the settings button and add your Claude API key from https://console.anthropic.com/"
        case .apiKeyInvalid:
            return "Verify your API key is correct in Settings or generate a new one."
        case .networkError:
            return "Check your internet connection and try again."
        case .apiError:
            return "Try again in a moment. If the problem persists, check your API key."
        case .textTooLong:
            return "Select a shorter portion of text (under 4000 characters)."
        case .textTooShort:
            return "Select at least a few words to rephrase."
        case .unexpectedError:
            return "Try restarting the app. If the problem persists, contact support."
        case .processingTimeout:
            return "Try again with a shorter text or check your internet connection."
        case .clipboardAccessFailed:
            return "Restart the app or check system permissions."
        case .appSwitchFailed:
            return "The text was rephrased but couldn't be automatically pasted. Copy it manually from notifications."
        }
    }
    
    var category: ErrorCategory {
        switch self {
        case .noTextSelected, .textTooLong, .textTooShort:
            return .userInput
        case .accessibilityPermissionDenied, .clipboardAccessFailed:
            return .permissions
        case .apiKeyMissing, .apiKeyInvalid:
            return .configuration
        case .networkError, .processingTimeout:
            return .network
        case .apiError:
            return .api
        case .unexpectedError, .appSwitchFailed:
            return .system
        }
    }
    
    var icon: String {
        switch category {
        case .userInput:
            return "text.cursor"
        case .permissions:
            return "lock.shield"
        case .configuration:
            return "key"
        case .network:
            return "wifi.exclamationmark"
        case .api:
            return "cloud.fill"
        case .system:
            return "exclamationmark.triangle"
        }
    }
}

enum ErrorCategory {
    case userInput
    case permissions
    case configuration
    case network
    case api
    case system
}

// Enhanced error handling manager
class ErrorHandler: ObservableObject {
    @Published var lastError: RephraserError?
    @Published var showingErrorDetails = false
    
    private let notificationManager = NotificationManager()
    
    func handle(_ error: Error, context: String = "") {
        let rephraserError = convertToRephraserError(error)
        lastError = rephraserError
        
        // Log error for debugging
        logError(rephraserError, context: context)
        
        // Show appropriate user feedback
        showUserFeedback(for: rephraserError)
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
    
    private func logError(_ error: RephraserError, context: String) {
        print("🚨 Error in \(context): \(error.errorDescription ?? "Unknown error")")
        if let recovery = error.recoverySuggestion {
            print("💡 Recovery suggestion: \(recovery)")
        }
    }
    
    private func showUserFeedback(for error: RephraserError) {
        // Show notification
        notificationManager.showErrorNotification(error)
        
        // For critical errors, also show in-app feedback
        if error.category == .permissions || error.category == .configuration {
            showingErrorDetails = true
        }
    }
}

// Enhanced notification manager
class NotificationManager {
    
    func showErrorNotification(_ error: RephraserError) {
        let content = UNMutableNotificationContent()
        content.title = "Rephraser Error"
        content.body = error.errorDescription ?? "An error occurred"
        content.sound = .default
        
        // Add recovery suggestion as subtitle if available
        if let recovery = error.recoverySuggestion {
            content.subtitle = recovery
        }
        
        let request = UNNotificationRequest(
            identifier: "error-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func showSuccessNotification(message: String, subtitle: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Rephraser"
        content.body = message
        
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        let request = UNNotificationRequest(
            identifier: "success-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// Error detail view for in-app display
struct ErrorDetailView: View {
    let error: RephraserError
    let onDismiss: () -> Void
    let onAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Error icon and title
            VStack(spacing: 12) {
                Image(systemName: error.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Something went wrong")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            // Error description
            VStack(spacing: 8) {
                Text(error.errorDescription ?? "An unknown error occurred")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                if let onAction = onAction {
                    Button(actionButtonTitle) {
                        onAction()
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 400)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 20)
    }
    
    private var actionButtonTitle: String {
        switch error.category {
        case .configuration:
            return "Open Settings"
        case .permissions:
            return "Open System Settings"
        default:
            return "Try Again"
        }
    }
}