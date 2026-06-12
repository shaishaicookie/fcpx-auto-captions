//
//  GeminiModels.swift
//  Whisper Auto Captions
//
//  Data models for Gemini API communication
//

import Foundation

// MARK: - Gemini API Request Models

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig

    init(prompt: String, temperature: Double = 0.1, maxTokens: Int = 500) {
        self.contents = [
            GeminiContent(parts: [GeminiPart(text: prompt)])
        ]
        self.generationConfig = GenerationConfig(
            temperature: temperature,
            maxOutputTokens: maxTokens,
            responseMimeType: "application/json"
        )
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    let responseMimeType: String
}

// MARK: - Gemini API Response Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let error: GeminiError?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
}

struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String?
}

// MARK: - Settings Suggestion Model

/// Represents AI-suggested Whisper settings based on user input
struct SettingsSuggestion: Codable {
    // Quality Settings
    let beamSize: Int?
    let bestOf: Int?
    let temperature: Double?
    let entropyThreshold: Double?
    let logProbThreshold: Double?

    // Performance Settings
    let threads: Int?
    let processors: Int?
    let noGPU: Bool?
    let flashAttention: Bool?

    // Output Settings
    let maxLen: Int?
    let splitOnWord: Bool?
    let translate: Bool?

    // Advanced Settings
    let noSpeechThreshold: Double?
    let wordThreshold: Double?

    // Explanation
    let explanation: String

    // MARK: - Convenience

    /// Check if any setting is suggested
    var hasSuggestions: Bool {
        return beamSize != nil ||
               bestOf != nil ||
               temperature != nil ||
               entropyThreshold != nil ||
               logProbThreshold != nil ||
               threads != nil ||
               processors != nil ||
               noGPU != nil ||
               flashAttention != nil ||
               maxLen != nil ||
               splitOnWord != nil ||
               translate != nil ||
               noSpeechThreshold != nil ||
               wordThreshold != nil
    }

    /// Get a list of changed settings with their values
    var changedSettings: [(name: String, value: String)] {
        var changes: [(String, String)] = []

        if let v = beamSize { changes.append(("Beam Size", String(v))) }
        if let v = bestOf { changes.append(("Best Of", String(v))) }
        if let v = temperature { changes.append(("Temperature", String(format: "%.2f", v))) }
        if let v = entropyThreshold { changes.append(("Entropy Threshold", String(format: "%.2f", v))) }
        if let v = logProbThreshold { changes.append(("Log Prob Threshold", String(format: "%.2f", v))) }
        if let v = threads { changes.append(("Threads", String(v))) }
        if let v = processors { changes.append(("Processors", String(v))) }
        if let v = noGPU { changes.append(("Disable GPU", v ? "Yes" : "No")) }
        if let v = flashAttention { changes.append(("Flash Attention", v ? "Yes" : "No")) }
        if let v = maxLen { changes.append(("Max Length", v == 0 ? "No limit" : String(v))) }
        if let v = splitOnWord { changes.append(("Split on Word", v ? "Yes" : "No")) }
        if let v = translate { changes.append(("Translate", v ? "Yes" : "No")) }
        if let v = noSpeechThreshold { changes.append(("No Speech Threshold", String(format: "%.2f", v))) }
        if let v = wordThreshold { changes.append(("Word Threshold", String(format: "%.3f", v))) }

        return changes
    }

    /// Apply this suggestion to WhisperSettings
    func apply(to settings: inout WhisperSettings) {
        if let v = beamSize { settings.beamSize = WhisperSettings.clampedDecoderCount(v) }
        if let v = bestOf { settings.bestOf = WhisperSettings.clampedDecoderCount(v) }
        if let v = temperature { settings.temperature = v }
        if let v = entropyThreshold { settings.entropyThreshold = v }
        if let v = logProbThreshold { settings.logProbThreshold = v }
        if let v = threads { settings.threads = v }
        if let v = processors { settings.processors = v }
        if let v = noGPU { settings.noGPU = v }
        if let v = flashAttention { settings.flashAttention = v }
        if let v = maxLen { settings.maxLen = v }
        if let v = splitOnWord { settings.splitOnWord = v }
        if let v = translate { settings.translate = v }
        if let v = noSpeechThreshold { settings.noSpeechThreshold = v }
        if let v = wordThreshold { settings.wordThreshold = v }
    }
}

// MARK: - API Validation Response

struct GeminiValidationResult {
    let isValid: Bool
    let message: String
}
