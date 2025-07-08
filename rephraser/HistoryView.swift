//
//  HistoryView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
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
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Rephrasing History")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("\(appState.history.entries.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Clear All") {
                    appState.history.clearHistory()
                }
                .disabled(appState.history.entries.isEmpty)
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
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
        .frame(width: 800, height: 600)
        .sheet(item: $selectedEntry) { entry in
            HistoryDetailView(entry: entry)
        }
    }
}

struct HistoryEntryView: View {
    let entry: RephrasingEntry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with timestamp and app
            HStack {
                Text(entry.displayTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let appName = entry.appName {
                    Text("• \(appName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete this entry")
            }
            
            // Original text
            VStack(alignment: .leading, spacing: 4) {
                Text("Original:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(entry.shortOriginal)
                    .font(.body)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Arrow
            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
                    .font(.caption)
                Spacer()
            }
            
            // Rephrased text
            VStack(alignment: .leading, spacing: 4) {
                Text("Rephrased:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(entry.shortRephrased)
                    .font(.body)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
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
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Rephrasing Detail")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text(entry.displayTimestamp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let appName = entry.appName {
                            Text("• \(appName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                
                // Rephrased
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rephrased Text:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(entry.rephrasedText)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
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
    HistoryView()
        .environmentObject(AppState())
}