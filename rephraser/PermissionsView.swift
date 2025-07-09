//
//  PermissionsView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

struct PermissionsView: View {
    @StateObject private var permissionsManager = PermissionsManager()
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Back Button
            HStack {
                Button(action: { onBack() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Back")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
                
                Spacer()
                
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("App Permissions")
                        .font(.title)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding(.top)
            
            Divider()
            
            // Permission Status
            VStack(spacing: 15) {
                // Accessibility Permission
                PermissionRowView(
                    icon: "accessibility",
                    title: "Accessibility Access",
                    description: "Required to monitor global keyboard shortcuts and manipulate text",
                    status: permissionsManager.permissionStatusText,
                    statusColor: Color(permissionsManager.permissionStatusColor),
                    isGranted: permissionsManager.accessibilityPermissionGranted,
                    onRequestPermission: {
                        permissionsManager.requestAccessibilityPermission()
                    },
                    onOpenSettings: {
                        permissionsManager.openSystemPreferences()
                    }
                )
                
                Divider()
                
                // Instructions
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Setup Instructions")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        InstructionStepView(
                            step: 1,
                            text: "Click 'Request Permission' or 'Open Settings' above"
                        )
                        InstructionStepView(
                            step: 2,
                            text: "In System Settings, go to Privacy & Security → Accessibility"
                        )
                        InstructionStepView(
                            step: 3,
                            text: "Find 'rephraser' in the list and enable it"
                        )
                        InstructionStepView(
                            step: 4,
                            text: "If not found, click '+' and add the app manually"
                        )
                        InstructionStepView(
                            step: 5,
                            text: "Return here and click 'Recheck Permissions'"
                        )
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 10) {
                HStack(spacing: 15) {
                    Button("Recheck Permissions") {
                        permissionsManager.checkPermissions()
                    }
                    .keyboardShortcut("r")
                    
                    Button("Open Settings") {
                        permissionsManager.openSystemPreferences()
                    }
                    .keyboardShortcut("s")
                }
                
                if permissionsManager.accessibilityPermissionGranted {
                    Button("Done") {
                        onBack()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .frame(width: 600, height: 500)
        .onAppear {
            permissionsManager.checkPermissions()
        }
    }
}

struct PermissionRowView: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    let statusColor: Color
    let isGranted: Bool
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 5) {
                if !isGranted {
                    Button("Request Permission") {
                        onRequestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Open Settings") {
                        onOpenSettings()
                    }
                    .controlSize(.small)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct InstructionStepView: View {
    let step: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(step).")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionsView(onBack: {})
}