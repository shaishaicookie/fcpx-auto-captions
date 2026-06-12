//
//  PerformanceSettingsView.swift
//  Whisper Auto Captions
//
//  Performance-related settings (speed parameters)
//

import SwiftUI

struct PerformanceSettingsView: View {
    @Binding var settings: WhisperSettings

    private var maxThreads: Int {
        ProcessInfo.processInfo.processorCount
    }

    var body: some View {
        Form {
            Section {
                // Threads
                HStack {
                    Text(String(localized: "Threads:", comment: "Threads setting label"))
                        .frame(width: 150, alignment: .trailing)
                    Stepper(value: $settings.threads, in: 1...maxThreads) {
                        Text("\(settings.threads)")
                            .frame(width: 40)
                    }
                    Text(String(localized: "Max: \(maxThreads)", comment: "Max threads description"))
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    InfoButton(
                        title: "info.threads.title",
                        description: "info.threads.description",
                        recommendation: "info.threads.recommendation"
                    )
                }

                // Processors
                HStack {
                    Text(String(localized: "Processors:", comment: "Processors setting label"))
                        .frame(width: 150, alignment: .trailing)
                    Stepper(value: $settings.processors, in: 1...maxThreads) {
                        Text("\(settings.processors)")
                            .frame(width: 40)
                    }
                    Spacer()
                    InfoButton(
                        title: "info.processors.title",
                        description: "info.processors.description",
                        recommendation: "info.processors.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "Threading", comment: "Threading section header"))
            }

            Section {
                // No GPU
                HStack {
                    Toggle(isOn: $settings.noGPU) {
                        Text(String(localized: "Disable GPU Acceleration", comment: "No GPU toggle label"))
                    }
                    InfoButton(
                        title: "info.nogpu.title",
                        description: "info.nogpu.description",
                        recommendation: "info.nogpu.recommendation"
                    )
                }

                // Flash Attention
                HStack {
                    Toggle(isOn: $settings.flashAttention) {
                        Text(String(localized: "Flash Attention", comment: "Flash attention toggle label"))
                    }
                    InfoButton(
                        title: "info.flashattention.title",
                        description: "info.flashattention.description",
                        recommendation: "info.flashattention.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "GPU Settings", comment: "GPU section header"))
            }

            Section {
                Text(String(localized: "More threads generally improve speed, but using too many can cause diminishing returns. Flash Attention can significantly speed up processing on supported hardware.", comment: "Performance tips"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text(String(localized: "Tips", comment: "Tips section header"))
            }
        }
        .formStyle(.grouped)

    }
}
