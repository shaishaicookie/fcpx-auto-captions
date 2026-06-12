//
//  AIAssistantSettingsView.swift
//  Whisper Auto Captions
//
//  AI Assistant settings view for natural language configuration
//

import SwiftUI

struct AIAssistantSettingsView: View {
    @Binding var settings: WhisperSettings
    @ObservedObject private var geminiService = GeminiService.shared

    // MARK: - State
    @State private var apiKeyInput: String = ""
    @State private var isApiKeyVisible: Bool = false
    @State private var isValidating: Bool = false
    @State private var validationResult: GeminiValidationResult?

    @State private var userPrompt: String = ""
    @State private var isRequestingSuggestion: Bool = false
    @State private var suggestion: SettingsSuggestion?
    @State private var errorMessage: String?

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // API Key Section
            apiKeySection

            Divider()

            // AI Configuration Section
            if geminiService.hasApiKey {
                aiConfigurationSection
            } else {
                noApiKeyPlaceholder
            }

            Spacer()
        }
        .onAppear {
            loadSavedApiKey()
        }
    }

    // MARK: - API Key Section
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gemini API Key")
                .font(.headline)

            HStack(spacing: 8) {
                if isApiKeyVisible {
                    TextField("Enter your API key", text: $apiKeyInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("Enter your API key", text: $apiKeyInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Button(action: { isApiKeyVisible.toggle() }) {
                    Image(systemName: isApiKeyVisible ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)

                Button(action: validateAndSaveApiKey) {
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Test")
                    }
                }
                .disabled(apiKeyInput.isEmpty || isValidating)

                if geminiService.hasApiKey {
                    Button(action: deleteApiKey) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }

            // Validation Result
            if let result = validationResult {
                HStack(spacing: 4) {
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.isValid ? .green : .red)
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(result.isValid ? .green : .red)
                }
            }

            // Help Text
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Get your free API key at")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("aistudio.google.com", destination: URL(string: "https://aistudio.google.com/apikey")!)
                    .font(.caption)
            }
        }
    }

    // MARK: - No API Key Placeholder
    private var noApiKeyPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Configure AI Assistant")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Enter your Gemini API key above to enable AI-powered settings configuration.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - AI Configuration Section
    private var aiConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ask AI to Configure")
                .font(.headline)

            Text("Describe your video or what you need, and AI will suggest optimal settings.")
                .font(.caption)
                .foregroundColor(.secondary)

            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $userPrompt)
                    .frame(height: 80)
                    .font(.body)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                // Example Prompts
                HStack(spacing: 8) {
                    Text("Examples:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    exampleButton("Poor audio quality")
                    exampleButton("Fast processing")
                    exampleButton("Maximum accuracy")
                }
            }

            // Request Button
            HStack {
                Spacer()
                Button(action: requestSuggestion) {
                    HStack(spacing: 6) {
                        if isRequestingSuggestion {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Get Suggestion")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(userPrompt.isEmpty || isRequestingSuggestion)
            }

            // Error Message
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // Suggestion View
            if let suggestion = suggestion {
                suggestionView(suggestion)
            }
        }
    }

    // MARK: - Suggestion View
    private func suggestionView(_ suggestion: SettingsSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("AI Suggestion")
                    .font(.headline)
            }

            // Explanation
            Text(suggestion.explanation)
                .font(.body)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            // Changed Settings
            if suggestion.hasSuggestions {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Changes:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(suggestion.changedSettings, id: \.name) { change in
                        HStack {
                            Text(change.name)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(change.value)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Action Buttons
            HStack {
                Button(action: clearSuggestion) {
                    Text("Dismiss")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: { applySuggestion(suggestion) }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Apply")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!suggestion.hasSuggestions)
            }
        }
    }

    // MARK: - Example Button
    private func exampleButton(_ text: String) -> some View {
        Button(action: { userPrompt = text }) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadSavedApiKey() {
        if let savedKey = geminiService.apiKey {
            apiKeyInput = savedKey
            validationResult = GeminiValidationResult(isValid: true, message: "Saved API key loaded")
        }
    }

    private func validateAndSaveApiKey() {
        isValidating = true
        validationResult = nil

        Task {
            let result = try? await geminiService.validateApiKey(apiKeyInput)

            await MainActor.run {
                isValidating = false

                if let result = result {
                    validationResult = result
                    if result.isValid {
                        geminiService.saveApiKey(apiKeyInput)
                    }
                } else {
                    validationResult = GeminiValidationResult(isValid: false, message: "Validation failed")
                }
            }
        }
    }

    private func deleteApiKey() {
        geminiService.deleteApiKey()
        apiKeyInput = ""
        validationResult = nil
        suggestion = nil
    }

    private func requestSuggestion() {
        isRequestingSuggestion = true
        errorMessage = nil
        suggestion = nil

        Task {
            do {
                let result = try await geminiService.suggestSettings(
                    userInput: userPrompt,
                    currentSettings: settings
                )

                await MainActor.run {
                    isRequestingSuggestion = false
                    suggestion = result
                }
            } catch {
                await MainActor.run {
                    isRequestingSuggestion = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func applySuggestion(_ suggestion: SettingsSuggestion) {
        suggestion.apply(to: &settings)
        clearSuggestion()
    }

    private func clearSuggestion() {
        suggestion = nil
        userPrompt = ""
        errorMessage = nil
    }
}

// MARK: - Preview
struct AIAssistantSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AIAssistantSettingsView(settings: .constant(WhisperSettings.default))
            .frame(width: 400, height: 500)
            .padding()
    }
}
