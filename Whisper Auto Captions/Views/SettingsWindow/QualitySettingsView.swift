//
//  QualitySettingsView.swift
//  Whisper Auto Captions
//
//  Quality-related settings (accuracy parameters)
//

import SwiftUI

struct QualitySettingsView: View {
    @Binding var settings: WhisperSettings

    var body: some View {
        Form {
            Section {
                // Best-of
                HStack {
                    Text(String(localized: "Best-of:", comment: "Best-of setting label"))
                        .frame(width: 150, alignment: .trailing)
                    Stepper(value: $settings.bestOf, in: 1...WhisperSettings.maxDecoderCount) {
                        Text("\(settings.bestOf)")
                            .frame(width: 40)
                    }
                    Spacer()
                    InfoButton(
                        title: "info.bestof.title",
                        description: "info.bestof.description",
                        recommendation: "info.bestof.recommendation"
                    )
                }

                // Beam Size
                HStack {
                    Text(String(localized: "Beam Size:", comment: "Beam size setting label"))
                        .frame(width: 150, alignment: .trailing)
                    Stepper(value: $settings.beamSize, in: 1...WhisperSettings.maxDecoderCount) {
                        Text("\(settings.beamSize)")
                            .frame(width: 40)
                    }
                    Spacer()
                    InfoButton(
                        title: "info.beamsize.title",
                        description: "info.beamsize.description",
                        recommendation: "info.beamsize.recommendation"
                    )
                }

                // Temperature
                HStack {
                    Text(String(localized: "Temperature:", comment: "Temperature setting label"))
                        .frame(width: 150, alignment: .trailing)
                    TextField("", value: $settings.temperature, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Spacer()
                    InfoButton(
                        title: "info.temperature.title",
                        description: "info.temperature.description",
                        recommendation: "info.temperature.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "Decoding Parameters", comment: "Decoding section header"))
            }

            Section {
                // Entropy Threshold
                HStack {
                    Text(String(localized: "Entropy Threshold:", comment: "Entropy threshold label"))
                        .frame(width: 150, alignment: .trailing)
                    TextField("", value: $settings.entropyThreshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Spacer()
                    InfoButton(
                        title: "info.entropy.title",
                        description: "info.entropy.description",
                        recommendation: "info.entropy.recommendation"
                    )
                }

                // Log Probability Threshold
                HStack {
                    Text(String(localized: "Log Prob Threshold:", comment: "Log prob threshold label"))
                        .frame(width: 150, alignment: .trailing)
                    TextField("", value: $settings.logProbThreshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Spacer()
                    InfoButton(
                        title: "info.logprob.title",
                        description: "info.logprob.description",
                        recommendation: "info.logprob.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "Validation Thresholds", comment: "Validation section header"))
            }

            Section {
                Text(String(localized: "Higher values for best-of and beam-size improve accuracy but increase processing time.", comment: "Quality tips"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text(String(localized: "Tips", comment: "Tips section header"))
            }
        }
        .formStyle(.grouped)

    }
}
