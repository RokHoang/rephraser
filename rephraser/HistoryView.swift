//
//  HistoryView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    let onBack: () -> Void
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
        VStack(spacing: 0) {
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
                
                VStack(alignment: .center) {
                    Text("Rephrasing History")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("\(appState.history.entries.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button("Clear All") {
                        appState.history.clearHistory()
                    }
                    .disabled(appState.history.entries.isEmpty)
                    
                    Button("Done") {
                        onBack()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            Divider()
            
            // Search
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
            .padding()
            
            Divider()
            
            // History List
            if filteredEntries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No rephrasing history yet" : "No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Start rephrasing text with Cmd+C+C+C to see history here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredEntries, selection: $selectedEntry) { entry in
                    HistoryEntryView(entry: entry) {
                        appState.history.deleteEntry(entry)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 700, height: 400)
        .sheet(item: $selectedEntry) { entry in
            HistoryDetailView(entry: entry)
        }
    }
}

struct HistoryEntryView: View {
    let entry: RephrasingEntry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Compact header with timestamp, app, and provider
            HStack {
                // Status indicator
                Image(systemName: entry.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(entry.isSuccess ? .green : .red)
                
                Text(entry.displayTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let appName = entry.appName {
                    Text("• \(appName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // API Provider indicator
                HStack(spacing: 2) {
                    Image(systemName: entry.apiProvider.icon)
                        .font(.caption2)
                    Text(entry.apiProvider.displayName)
                        .font(.caption2)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
                
                if let style = entry.style {
                    Text(style)
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete this entry")
            }
            
            // Compact text comparison in horizontal layout
            HStack(alignment: .top, spacing: 8) {
                // Original text (left side)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Original")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(entry.shortOriginal)
                        .font(.caption)
                        .lineLimit(3)
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Arrow (center)
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                    .font(.caption2)
                    .padding(.top, 16)
                
                // Rephrased text (right side)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rephrased")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(entry.shortRephrased)
                        .font(.caption)
                        .lineLimit(3)
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
        .onTapGesture(count: 2) {
            // Double-click to view full entry
            // This will be handled by the List selection
        }
    }
}

struct HistoryDetailView: View {
    let entry: RephrasingEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                    HStack {
                        Image(systemName: entry.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(entry.isSuccess ? .green : .red)
                        Text(entry.isSuccess ? "Rephrasing Detail" : "Failed Rephrasing")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text(entry.displayTimestamp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let appName = entry.appName {
                            Text("• \(appName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // API Provider indicator
                        HStack(spacing: 2) {
                            Image(systemName: entry.apiProvider.icon)
                                .font(.caption)
                            Text(entry.apiProvider.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                        
                        if let style = entry.style {
                            Text(style)
                                .font(.caption)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            // Full text display
            VStack(alignment: .leading, spacing: 15) {
                // Original
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Text:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(entry.originalText)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
                
                // Rephrased or Error
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.isSuccess ? "Rephrased Text:" : "Error Details:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.rephrasedText)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(entry.isSuccess ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                                .cornerRadius(8)
                            
                            if !entry.isSuccess, let errorMessage = entry.errorMessage {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Error Message:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    
                                    Text(errorMessage)
                                        .font(.caption)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(6)
                                        .background(Color.red.opacity(0.05))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                
                // Copy buttons
                HStack {
                    Button("Copy Original") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.originalText, forType: .string)
                    }
                    
                    Button("Copy Rephrased") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.rephrasedText, forType: .string)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

#Preview {
    HistoryView(onBack: {})
        .environmentObject(AppState())
}