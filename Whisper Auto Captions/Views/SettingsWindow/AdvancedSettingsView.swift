//
//  AdvancedSettingsView.swift
//  Whisper Auto Captions
//
//  Advanced settings for specialized features
//

import SwiftUI

struct AdvancedSettingsView: View {
    @Binding var settings: WhisperSettings

    var body: some View {
        Form {
            Section {
                // Prompt
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "Initial Prompt:", comment: "Prompt label"))
                        Spacer()
                        InfoButton(
                            title: "info.prompt.title",
                            description: "info.prompt.description",
                            recommendation: nil
                        )
                    }
                    TextEditor(text: $settings.prompt)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            } header: {
                Text(String(localized: "Prompt", comment: "Prompt section header"))
            }

            Section {
                // No Speech Threshold
                HStack {
                    Text(String(localized: "No Speech Threshold:", comment: "No speech threshold label"))
                        .frame(width: 150, alignment: .trailing)
                    TextField("", value: $settings.noSpeechThreshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Spacer()
                    InfoButton(
                        title: "info.nospeech.title",
                        description: "info.nospeech.description",
                        recommendation: "info.nospeech.recommendation"
                    )
                }

                // Word Threshold
                HStack {
                    Text(String(localized: "Word Threshold:", comment: "Word threshold label"))
                        .frame(width: 150, alignment: .trailing)
                    TextField("", value: $settings.wordThreshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Spacer()
                    InfoButton(
                        title: "info.wordthreshold.title",
                        description: "info.wordthreshold.description",
                        recommendation: "info.wordthreshold.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "Detection Thresholds", comment: "Detection section header"))
            }

            Section {
                // Diarize
                HStack {
                    Toggle(isOn: $settings.diarize) {
                        Text(String(localized: "Speaker Diarization", comment: "Diarize toggle label"))
                    }
                    InfoButton(
                        title: "info.diarize.title",
                        description: "info.diarize.description",
                        recommendation: "info.diarize.recommendation"
                    )
                }

                // Tiny Diarize
                HStack {
                    Toggle(isOn: $settings.tinyDiarize) {
                        Text(String(localized: "Tiny Diarization (Experimental)", comment: "Tiny diarize toggle label"))
                    }
                    InfoButton(
                        title: "info.tinydiarize.title",
                        description: "info.tinydiarize.description",
                        recommendation: "info.tinydiarize.recommendation"
                    )
                }
                .disabled(!settings.diarize)
            } header: {
                Text(String(localized: "Speaker Diarization", comment: "Diarization section header"))
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Use the prompt to provide context about the audio content or include specific vocabulary that should be recognized.", comment: "Prompt tip"))

                    Text(String(localized: "Speaker diarization helps distinguish between multiple speakers but may increase processing time.", comment: "Diarization tip"))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            } header: {
                Text(String(localized: "Tips", comment: "Tips section header"))
            }
        }
        .formStyle(.grouped)

    }
}
