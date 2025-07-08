//
//  ClaudeAPI.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation

class ClaudeAPI {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func rephrase(text: String, style: RephraseStyle = .standard) async throws -> String {
        return try await rephraseWithPrompt(text: text, prompt: style.prompt)
    }
    
    func rephraseWithPrompt(text: String, prompt: String) async throws -> String {
        let request = ClaudeRequest(
            model: "claude-3-haiku-20240307",
            maxTokens: 1024,
            messages: [
                ClaudeMessage(
                    role: "user",
                    content: "\(prompt)\n\n\(text)"
                )
            ]
        )
        
        let requestData = try JSONEncoder().encode(request)
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = requestData
        urlRequest.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            return try handleResponse(data: data, response: response)
        } catch {
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    throw ClaudeAPIError.networkError("No internet connection")
                case .cannotFindHost:
                    throw ClaudeAPIError.networkError("Cannot reach Claude API server. Check your internet connection.")
                case .timedOut:
                    throw ClaudeAPIError.networkError("Request timed out. Please try again.")
                case .cannotConnectToHost:
                    throw ClaudeAPIError.networkError("Cannot connect to Claude API server")
                default:
                    throw ClaudeAPIError.networkError("Network error: \(urlError.localizedDescription)")
                }
            }
            
            throw ClaudeAPIError.networkError("Network error: \(error.localizedDescription)")
        }
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw ClaudeAPIError.apiError(errorData.error.message)
            } else {
                throw ClaudeAPIError.httpError(httpResponse.statusCode)
            }
        }
        
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        
        guard let content = claudeResponse.content.first?.text else {
            throw ClaudeAPIError.noContent
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
    let model: String
    let role: String
    let usage: ClaudeUsage
}

struct ClaudeContent: Codable {
    let text: String
    let type: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct ClaudeErrorResponse: Codable {
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}

enum ClaudeAPIError: Error, LocalizedError {
    case invalidResponse
    case apiError(String)
    case httpError(Int)
    case noContent
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let message):
            return "Claude API error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noContent:
            return "No content received from Claude API"
        case .networkError(let message):
            return message
        }
    }
}