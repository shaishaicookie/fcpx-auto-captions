//
//  GeminiService.swift
//  Whisper Auto Captions
//
//  Service for communicating with Gemini API
//

import Foundation
import Combine

/// Service for interacting with Google's Gemini API
class GeminiService: ObservableObject {
    // MARK: - Singleton
    static let shared = GeminiService()

    // MARK: - Published Properties
    @Published private(set) var hasApiKey: Bool = false

    // MARK: - Constants
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let model = "gemini-2.0-flash"

    // MARK: - Errors
    enum GeminiServiceError: Error, LocalizedError {
        case invalidAPIKey
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case parsingError(String)

        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return String(localized: "Invalid API key", comment: "Invalid API key error")
            case .networkError(let error):
                return String(localized: "Network error: \(error.localizedDescription)", comment: "Network error")
            case .invalidResponse:
                return String(localized: "Invalid response from server", comment: "Invalid response error")
            case .apiError(let message):
                return message
            case .parsingError(let message):
                return String(localized: "Failed to parse response: \(message)", comment: "Parsing error")
            }
        }
    }

    // MARK: - Private Init
    private init() {
        hasApiKey = KeychainService.exists(.geminiApiKey)
    }

    // MARK: - API Key Management

    /// Get the stored API key
    var apiKey: String? {
        return KeychainService.retrieve(.geminiApiKey)
    }


    /// Save API key to Keychain
    @discardableResult
    func saveApiKey(_ key: String) -> Bool {
        let result = KeychainService.save(key, for: .geminiApiKey)
        if result {
            hasApiKey = true
        }
        return result
    }

    /// Delete stored API key
    @discardableResult
    func deleteApiKey() -> Bool {
        let result = KeychainService.delete(.geminiApiKey)
        if result {
            hasApiKey = false
        }
        return result
    }

    // MARK: - API Validation

    /// Validate an API key by making a test request
    func validateApiKey(_ key: String) async throws -> GeminiValidationResult {
        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(key)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let testRequest = GeminiRequest(prompt: "Say 'OK' if you can read this.", temperature: 0)
        request.httpBody = try JSONEncoder().encode(testRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return GeminiValidationResult(isValid: false, message: "Invalid response")
            }

            if httpResponse.statusCode == 200 {
                return GeminiValidationResult(isValid: true, message: "API key is valid")
            } else if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                if let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
                   let error = geminiResponse.error {
                    return GeminiValidationResult(isValid: false, message: error.message)
                }
                return GeminiValidationResult(isValid: false, message: "Invalid API key")
            } else {
                return GeminiValidationResult(isValid: false, message: "Server error: \(httpResponse.statusCode)")
            }
        } catch {
            return GeminiValidationResult(isValid: false, message: "Network error: \(error.localizedDescription)")
        }
    }

    // MARK: - Settings Suggestion

    /// Request AI-suggested settings based on user input
    func suggestSettings(userInput: String, currentSettings: WhisperSettings) async throws -> SettingsSuggestion {
        guard let key = apiKey else {
            throw GeminiServiceError.invalidAPIKey
        }

        let systemPrompt = buildSystemPrompt(currentSettings: currentSettings)
        let fullPrompt = """
        \(systemPrompt)

        User request: \(userInput)
        """

        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(key)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let geminiRequest = GeminiRequest(prompt: fullPrompt, temperature: 0.1, maxTokens: 800)
        request.httpBody = try JSONEncoder().encode(geminiRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiServiceError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                if let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
                   let error = geminiResponse.error {
                    throw GeminiServiceError.apiError(error.message)
                }
                throw GeminiServiceError.apiError("Server error: \(httpResponse.statusCode)")
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            guard let candidate = geminiResponse.candidates?.first,
                  let content = candidate.content,
                  let text = content.parts.first?.text else {
                throw GeminiServiceError.invalidResponse
            }

            // Parse the JSON response
            let suggestion = try parseSettingsSuggestion(from: text)
            return suggestion

        } catch let error as GeminiServiceError {
            throw error
        } catch {
            throw GeminiServiceError.networkError(error)
        }
    }

    // MARK: - Private Helpers

    private func buildSystemPrompt(currentSettings: WhisperSettings) -> String {
        return """
        You are a Whisper transcription settings assistant for a Final Cut Pro auto-captions app.
        Based on the user's description, suggest optimal Whisper settings.

        Current settings:
        - beamSize: \(currentSettings.beamSize) (range: 1-\(WhisperSettings.maxDecoderCount), higher = more accurate but slower)
        - bestOf: \(currentSettings.bestOf) (range: 1-\(WhisperSettings.maxDecoderCount), candidates to consider)
        - temperature: \(currentSettings.temperature) (range: 0.0-1.0, 0 = deterministic, higher = more creative)
        - entropyThreshold: \(currentSettings.entropyThreshold) (range: 0.0-5.0, segment validation threshold)
        - logProbThreshold: \(currentSettings.logProbThreshold) (range: -5.0 to 0.0, log probability threshold)
        - threads: \(currentSettings.threads) (range: 1-16, computation threads)
        - processors: \(currentSettings.processors) (range: 1-8, number of processors)
        - noGPU: \(currentSettings.noGPU) (true = disable GPU)
        - flashAttention: \(currentSettings.flashAttention) (true = enable flash attention)
        - maxLen: \(currentSettings.maxLen) (0 = no limit, otherwise max segment length)
        - splitOnWord: \(currentSettings.splitOnWord) (split segments on word boundaries)
        - translate: \(currentSettings.translate) (translate to English)
        - noSpeechThreshold: \(currentSettings.noSpeechThreshold) (range: 0.0-1.0, silence detection)
        - wordThreshold: \(currentSettings.wordThreshold) (range: 0.0-1.0, word timestamp threshold)

        Guidelines for suggestions:
        - For poor audio quality: increase beamSize and bestOf, enable higher entropy threshold
        - For fast processing: reduce beamSize and bestOf, increase threads
        - For maximum accuracy: high beamSize (8), high bestOf (8), temperature 0
        - For background noise: increase noSpeechThreshold
        - For long videos: consider using flash attention if available

        IMPORTANT: Only suggest settings that need to change. Do not include settings that should stay the same.

        Respond ONLY in this JSON format (only include fields that should change):
        {
          "beamSize": 5,
          "temperature": 0.0,
          "explanation": "설명 (사용자 언어로, 한국어 가능)"
        }
        """
    }

    private func parseSettingsSuggestion(from text: String) throws -> SettingsSuggestion {
        // Try to extract JSON from the response
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code block if present
        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        } else if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8) else {
            throw GeminiServiceError.parsingError("Invalid JSON encoding")
        }

        do {
            let suggestion = try JSONDecoder().decode(SettingsSuggestion.self, from: data)
            return suggestion
        } catch {
            throw GeminiServiceError.parsingError(error.localizedDescription)
        }
    }
}
