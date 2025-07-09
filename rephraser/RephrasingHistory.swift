//
//  RephrasingHistory.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation

enum APIProvider: String, Codable, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .claude:
            return "brain.head.profile"
        case .openai:
            return "cpu"
        }
    }
}

struct RephrasingEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let originalText: String
    let rephrasedText: String
    let timestamp: Date
    let appName: String?
    let style: String?
    let apiProvider: APIProvider
    let isSuccess: Bool
    let errorMessage: String?
    
    init(originalText: String, rephrasedText: String, timestamp: Date = Date(), appName: String? = nil, style: String? = nil, apiProvider: APIProvider = .claude) {
        self.id = UUID()
        self.originalText = originalText
        self.rephrasedText = rephrasedText
        self.timestamp = timestamp
        self.appName = appName
        self.style = style
        self.apiProvider = apiProvider
        self.isSuccess = true
        self.errorMessage = nil
    }
    
    init(originalText: String, errorMessage: String, timestamp: Date = Date(), appName: String? = nil, style: String? = nil, apiProvider: APIProvider = .claude) {
        self.id = UUID()
        self.originalText = originalText
        self.rephrasedText = "❌ Failed: \(errorMessage)"
        self.timestamp = timestamp
        self.appName = appName
        self.style = style
        self.apiProvider = apiProvider
        self.isSuccess = false
        self.errorMessage = errorMessage
    }
    
    var displayTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var shortOriginal: String {
        if originalText.count > 50 {
            return String(originalText.prefix(47)) + "..."
        }
        return originalText
    }
    
    var shortRephrased: String {
        if rephrasedText.count > 50 {
            return String(rephrasedText.prefix(47)) + "..."
        }
        return rephrasedText
    }
}

class RephrasingHistory: ObservableObject {
    @Published var entries: [RephrasingEntry] = []
    
    private let maxEntries = 100
    private let userDefaults = UserDefaults.standard
    private let historyKey = "rephrasingHistory"
    
    init() {
        loadHistory()
    }
    
    func addEntry(original: String, rephrased: String, appName: String? = nil, style: String? = nil, apiProvider: APIProvider = .claude) {
        let entry = RephrasingEntry(
            originalText: original,
            rephrasedText: rephrased,
            appName: appName,
            style: style,
            apiProvider: apiProvider
        )
        addEntry(entry)
    }
    
    func addFailedEntry(original: String, errorMessage: String, appName: String? = nil, style: String? = nil, apiProvider: APIProvider = .claude) {
        let entry = RephrasingEntry(
            originalText: original,
            errorMessage: errorMessage,
            appName: appName,
            style: style,
            apiProvider: apiProvider
        )
        addEntry(entry)
    }
    
    func addEntry(_ entry: RephrasingEntry) {
        DispatchQueue.main.async {
            self.entries.insert(entry, at: 0)
            
            // Keep only the most recent entries
            if self.entries.count > self.maxEntries {
                self.entries = Array(self.entries.prefix(self.maxEntries))
            }
            
            self.saveHistory()
        }
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.entries.removeAll()
            self.saveHistory()
        }
    }
    
    func deleteEntry(_ entry: RephrasingEntry) {
        DispatchQueue.main.async {
            self.entries.removeAll { $0.id == entry.id }
            self.saveHistory()
        }
    }
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(entries)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("Failed to save rephrasing history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else { return }
        
        do {
            let loadedEntries = try JSONDecoder().decode([RephrasingEntry].self, from: data)
            DispatchQueue.main.async {
                self.entries = loadedEntries
            }
        } catch {
            print("Failed to load rephrasing history: \(error)")
        }
    }
}