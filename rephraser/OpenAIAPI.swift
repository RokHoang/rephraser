//
//  OpenAIAPI.swift
//  rephraser
//
//  Created by Rok Hoang on 7/9/25.
//

import Foundation

class OpenAIAPI {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func rephrase(text: String, style: RephraseStyle = .standard) async throws -> String {
        return try await rephraseWithPrompt(text: text, prompt: style.prompt)
    }
    
    func rephraseWithPrompt(text: String, prompt: String) async throws -> String {
        let request = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIMessage(
                    role: "system",
                    content: prompt
                ),
                OpenAIMessage(
                    role: "user",
                    content: text
                )
            ],
            maxTokens: 1000,
            temperature: 0.7
        )
        
        let requestData = try JSONEncoder().encode(request)
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = requestData
        urlRequest.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            return try handleResponse(data: data, response: response)
        } catch {
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    throw OpenAIAPIError.networkError("No internet connection")
                case .timedOut:
                    throw OpenAIAPIError.networkError("Request timed out")
                case .cannotFindHost:
                    throw OpenAIAPIError.networkError("Cannot reach OpenAI servers")
                default:
                    throw OpenAIAPIError.networkError("Network error: \(urlError.localizedDescription)")
                }
            }
            
            throw OpenAIAPIError.networkError("Unknown network error: \(error.localizedDescription)")
        }
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIAPIError.invalidResponse
        }
        
        // Handle HTTP errors
        if httpResponse.statusCode >= 400 {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw OpenAIAPIError.apiError(errorResponse.error.message)
            } else {
                throw OpenAIAPIError.httpError(httpResponse.statusCode)
            }
        }
        
        // Parse successful response
        guard let openaiResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data) else {
            throw OpenAIAPIError.invalidResponse
        }
        
        guard let choice = openaiResponse.choices.first,
              !choice.message.content.isEmpty else {
            throw OpenAIAPIError.noContent
        }
        
        let content = choice.message.content
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - OpenAI API Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
}

struct OpenAIError: Codable {
    let message: String
    let type: String
    let param: String?
    let code: String?
}

// MARK: - OpenAI API Errors
enum OpenAIAPIError: Error, LocalizedError {
    case networkError(String)
    case apiError(String)
    case httpError(Int)
    case invalidResponse
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .noContent:
            return "No content received from OpenAI"
        }
    }
}