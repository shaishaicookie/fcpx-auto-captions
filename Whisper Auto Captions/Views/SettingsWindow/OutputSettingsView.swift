//
//  OutputSettingsView.swift
//  Whisper Auto Captions
//
//  Output format settings
//

import SwiftUI

/// Preset options for audio segment duration
enum SegmentDurationPreset: Int, CaseIterable {
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900
    case twentyMinutes = 1200
    case custom = -1

    var displayName: String {
        switch self {
        case .fiveMinutes: return String(localized: "5 minutes", comment: "5 minutes segment duration")
        case .tenMinutes: return String(localized: "10 minutes (default)", comment: "10 minutes segment duration")
        case .fifteenMinutes: return String(localized: "15 minutes", comment: "15 minutes segment duration")
        case .twentyMinutes: return String(localized: "20 minutes", comment: "20 minutes segment duration")
        case .custom: return String(localized: "Custom...", comment: "Custom segment duration option")
        }
    }

    static func from(seconds: Int, isCustom: Bool) -> SegmentDurationPreset {
        if isCustom { return .custom }
        return SegmentDurationPreset(rawValue: seconds) ?? .custom
    }
}

struct OutputSettingsView: View {
    @Binding var settings: WhisperSettings

    private var selectedPreset: SegmentDurationPreset {
        SegmentDurationPreset.from(seconds: settings.audioSegmentDuration, isCustom: settings.useCustomSegmentDuration)
    }

    var body: some View {
        Form {
            Section {
                // Audio Segment Duration
                HStack {
                    Text(String(localized: "Audio Segment Duration:", comment: "Audio segment duration label"))
                        .frame(width: 150, alignment: .trailing)
                    Picker("", selection: Binding(
                        get: { selectedPreset },
                        set: { newValue in
                            if newValue == .custom {
                                settings.useCustomSegmentDuration = true
                            } else {
                                settings.useCustomSegmentDuration = false
                                settings.audioSegmentDuration = newValue.rawValue
                            }
                        }
                    )) {
                        ForEach(SegmentDurationPreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                    Spacer()
                    InfoButton(
                        title: "info.audiosegment.title",
                        description: "info.audiosegment.description",
                        recommendation: "info.audiosegment.recommendation"
                    )
                }

                // Custom Duration Input (shown when Custom is selected)
                if settings.useCustomSegmentDuration {
                    HStack {
                        Text(String(localized: "Custom Duration:", comment: "Custom duration label"))
                            .frame(width: 150, alignment: .trailing)
                        TextField("", value: $settings.customSegmentDurationMinutes, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onChange(of: settings.customSegmentDurationMinutes) { newValue in
                                // Clamp to valid range (1-30 minutes)
                                let clampedValue = min(max(newValue, 1), 30)
                                if clampedValue != newValue {
                                    settings.customSegmentDurationMinutes = clampedValue
                                }
                                // Update the actual duration in seconds
                                settings.audioSegmentDuration = clampedValue * 60
                            }
                        Text(String(localized: "minutes (1-30)", comment: "Minutes range hint"))
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Spacer()
                    }
                }
            } header: {
                Text(String(localized: "Audio Splitting", comment: "Audio splitting section header"))
            }

            Section {
                // Max Length
                HStack {
                    Text(String(localized: "Max Segment Length:", comment: "Max length label"))
                        .frame(width: 150, alignment: .trailing)
                    TextField("", value: $settings.maxLen, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Spacer()
                    InfoButton(
                        title: "info.maxlen.title",
                        description: "info.maxlen.description",
                        recommendation: "info.maxlen.recommendation"
                    )
                }

                // Split on Word
                HStack {
                    Toggle(isOn: $settings.splitOnWord) {
                        Text(String(localized: "Split on Word Boundaries", comment: "Split on word toggle label"))
                    }
                    InfoButton(
                        title: "info.splitonword.title",
                        description: "info.splitonword.description",
                        recommendation: "info.splitonword.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "Segment Length", comment: "Segment length section header"))
            }

            Section {
                // No Timestamps
                HStack {
                    Toggle(isOn: $settings.noTimestamps) {
                        Text(String(localized: "Disable Timestamps", comment: "No timestamps toggle label"))
                    }
                    InfoButton(
                        title: "info.notimestamps.title",
                        description: "info.notimestamps.description",
                        recommendation: "info.notimestamps.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "Timestamps", comment: "Timestamps section header"))
            }

            Section {
                // Translate
                HStack {
                    Toggle(isOn: $settings.translate) {
                        Text(String(localized: "Translate to English", comment: "Translate toggle label"))
                    }
                    InfoButton(
                        title: "info.translate.title",
                        description: "info.translate.description",
                        recommendation: "info.translate.recommendation"
                    )
                }
            } header: {
                Text(String(localized: "Translation", comment: "Translation section header"))
            }

            Section {
                Text(String(localized: "Setting a max segment length helps ensure subtitles fit on screen. Enable 'Split on Word' to prevent awkward mid-word breaks.", comment: "Output tips"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text(String(localized: "Tips", comment: "Tips section header"))
            }
        }
        .formStyle(.grouped)

    }
}
