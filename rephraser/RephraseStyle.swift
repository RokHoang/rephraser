//
//  RephraseStyle.swift
//  rephraser
//
//  Created by Rok Hoang on 7/8/25.
//

import Foundation

// MARK: - Custom Style Structure
struct CustomRephraseStyle: Codable, Identifiable, Equatable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var prompt: String
    var icon: String
    
    init(name: String, description: String, prompt: String, icon: String = "text.cursor") {
        self.name = name
        self.description = description
        self.prompt = prompt
        self.icon = icon
    }
}

// MARK: - Rephrase Style Manager
class RephraseStyleManager: ObservableObject {
    @Published var customStyles: [CustomRephraseStyle] = []
    
    private let keychainService = "com.rokhoang.rephraser"
    private let customStylesItem = "custom-styles"
    
    init() {
        loadCustomStyles()
    }
    
    var allStyles: [RephraseStyleOption] {
        let builtInStyles = RephraseStyle.allCases.map { RephraseStyleOption.builtin($0) }
        let customOptions = customStyles.map { RephraseStyleOption.custom($0) }
        return builtInStyles + customOptions
    }
    
    func addCustomStyle(_ style: CustomRephraseStyle) {
        customStyles.append(style)
        saveCustomStyles()
    }
    
    func removeCustomStyle(_ style: CustomRephraseStyle) {
        customStyles.removeAll { $0.id == style.id }
        saveCustomStyles()
    }
    
    func updateCustomStyle(_ style: CustomRephraseStyle) {
        if let index = customStyles.firstIndex(where: { $0.id == style.id }) {
            customStyles[index] = style
            saveCustomStyles()
        }
    }
    
    private func saveCustomStyles() {
        if let data = try? JSONEncoder().encode(customStyles) {
            KeychainHelper.save(String(data: data, encoding: .utf8) ?? "", service: keychainService, account: customStylesItem)
        }
    }
    
    private func loadCustomStyles() {
        if let stylesData = KeychainHelper.load(service: keychainService, account: customStylesItem),
           let data = stylesData.data(using: .utf8),
           let styles = try? JSONDecoder().decode([CustomRephraseStyle].self, from: data) {
            customStyles = styles
        }
    }
}

// MARK: - Style Option Enum
enum RephraseStyleOption: Identifiable, Equatable, Hashable {
    case builtin(RephraseStyle)
    case custom(CustomRephraseStyle)
    
    var id: String {
        switch self {
        case .builtin(let style):
            return "builtin-\(style.rawValue)"
        case .custom(let style):
            return "custom-\(style.id.uuidString)"
        }
    }
    
    var displayName: String {
        switch self {
        case .builtin(let style):
            return style.displayName
        case .custom(let style):
            return style.name
        }
    }
    
    var description: String {
        switch self {
        case .builtin(let style):
            return style.description
        case .custom(let style):
            return style.description
        }
    }
    
    var prompt: String {
        switch self {
        case .builtin(let style):
            return style.prompt
        case .custom(let style):
            return style.prompt
        }
    }
    
    var icon: String {
        switch self {
        case .builtin(let style):
            return style.icon
        case .custom(let style):
            return style.icon
        }
    }
    
    var isCustom: Bool {
        switch self {
        case .builtin:
            return false
        case .custom:
            return true
        }
    }
}

// MARK: - Built-in Styles
enum RephraseStyle: String, CaseIterable, Codable {
    case standard = "standard"
    case formal = "formal"
    case casual = "casual"
    case concise = "concise"
    case creative = "creative"
    case professional = "professional"
    
    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .formal:
            return "Formal"
        case .casual:
            return "Casual"
        case .concise:
            return "Concise"
        case .creative:
            return "Creative"
        case .professional:
            return "Professional"
        }
    }
    
    var description: String {
        switch self {
        case .standard:
            return "Clear and well-structured"
        case .formal:
            return "Professional and academic tone"
        case .casual:
            return "Relaxed and conversational"
        case .concise:
            return "Brief and to the point"
        case .creative:
            return "Engaging and expressive"
        case .professional:
            return "Business-appropriate language"
        }
    }
    
    var prompt: String {
        switch self {
        case .standard:
            return "Please rephrase the following text to make it clearer and more concise while preserving its original meaning. Only return the rephrased text, nothing else:"
        case .formal:
            return "Please rephrase the following text in a formal, academic style with sophisticated vocabulary and proper grammar. Maintain the original meaning while making it more professional. Only return the rephrased text, nothing else:"
        case .casual:
            return "Please rephrase the following text in a casual, conversational tone that sounds natural and friendly. Keep the original meaning but make it more relaxed. Only return the rephrased text, nothing else:"
        case .concise:
            return "Please rephrase the following text to be as brief and concise as possible while retaining all essential information and meaning. Remove any unnecessary words. Only return the rephrased text, nothing else:"
        case .creative:
            return "Please rephrase the following text in a creative, engaging way that captures attention while preserving the original meaning. Use vivid language and interesting expressions. Only return the rephrased text, nothing else:"
        case .professional:
            return "Please rephrase the following text using professional business language appropriate for workplace communication. Maintain clarity and the original meaning. Only return the rephrased text, nothing else:"
        }
    }
    
    var icon: String {
        switch self {
        case .standard:
            return "text.alignleft"
        case .formal:
            return "graduationcap"
        case .casual:
            return "message"
        case .concise:
            return "text.word.spacing"
        case .creative:
            return "paintbrush"
        case .professional:
            return "briefcase"
        }
    }
}