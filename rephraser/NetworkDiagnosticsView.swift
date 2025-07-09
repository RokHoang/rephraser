//
//  NetworkDiagnosticsView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

struct NetworkDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var networkDiagnostics = NetworkDiagnostics()
    @State private var diagnosticResults: [String] = []
    @State private var isRunningDiagnostics = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Back Button
            HStack {
                Button(action: { dismiss() }) {
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
                
                VStack(alignment: .center) {
                    Text("Network Diagnostics")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Check connectivity to Claude API")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            // Current Status
            VStack(spacing: 10) {
                HStack {
                    Text("Current Status")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Circle()
                        .fill(networkDiagnostics.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text("Internet: \(networkDiagnostics.isConnected ? "Connected" : "Disconnected")")
                        .font(.body)
                    
                    Spacer()
                    
                    Text(networkDiagnostics.connectionType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Diagnostics Section
            VStack(spacing: 15) {
                HStack {
                    Text("Full Diagnostics")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Run Diagnostics") {
                        runDiagnostics()
                    }
                    .disabled(isRunningDiagnostics)
                    .buttonStyle(.borderedProminent)
                    
                    if isRunningDiagnostics {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Results
                if !diagnosticResults.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(diagnosticResults, id: \.self) { result in
                                Text(result)
                                    .font(.caption)
                                    .monospaced()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                } else if !isRunningDiagnostics {
                    Text("Click 'Run Diagnostics' to test connectivity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Troubleshooting Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Common Issues:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• \"Cannot find host\" - DNS or internet connection issue")
                    Text("• \"Connection timed out\" - Firewall or network blocking")
                    Text("• \"No internet connection\" - Check WiFi/Ethernet")
                    Text("• HTTP 401/403 - Invalid API key")
                    Text("• HTTP 429 - Rate limit exceeded")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            Spacer()
        }
        .frame(width: 500, height: 500)
        .onAppear {
            // Auto-run diagnostics when view appears
            if diagnosticResults.isEmpty {
                runDiagnostics()
            }
        }
    }
    
    private func runDiagnostics() {
        isRunningDiagnostics = true
        diagnosticResults = []
        
        Task {
            let results = await networkDiagnostics.runFullDiagnostics()
            
            DispatchQueue.main.async {
                self.diagnosticResults = results
                self.isRunningDiagnostics = false
            }
        }
    }
}

#Preview {
    NetworkDiagnosticsView()
}