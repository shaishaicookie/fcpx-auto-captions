//
//  WhisperPreset.swift
//  Whisper Auto Captions
//
//  Preset configurations for common use cases
//

import Foundation

/// Predefined presets for whisper.cpp with optimized settings
enum WhisperPreset: String, CaseIterable, Codable, Identifiable {
    case fastest = "Fastest"
    case fast = "Fast"
    case balanced = "Balanced"
    case quality = "Quality"
    case bestQuality = "Best Quality"
    case custom = "Custom"

    var id: String { rawValue }

    /// Localized display name
    var displayName: String {
        switch self {
        case .fastest:
            return String(localized: "Fastest", comment: "Preset name for fastest processing")
        case .fast:
            return String(localized: "Fast", comment: "Preset name for fast processing")
        case .balanced:
            return String(localized: "Balanced", comment: "Preset name for balanced processing")
        case .quality:
            return String(localized: "Quality", comment: "Preset name for quality processing")
        case .bestQuality:
            return String(localized: "Best Quality", comment: "Preset name for best quality processing")
        case .custom:
            return String(localized: "Custom", comment: "Preset name for custom settings")
        }
    }

    /// Description of what this preset optimizes for
    var description: String {
        switch self {
        case .fastest:
            return String(localized: "Maximum speed, lower accuracy. Good for quick previews.", comment: "Fastest preset description")
        case .fast:
            return String(localized: "Fast processing with reasonable accuracy.", comment: "Fast preset description")
        case .balanced:
            return String(localized: "Balance between speed and accuracy. Recommended for most use cases.", comment: "Balanced preset description")
        case .quality:
            return String(localized: "Higher accuracy at the cost of speed.", comment: "Quality preset description")
        case .bestQuality:
            return String(localized: "Maximum accuracy. Significantly slower processing.", comment: "Best Quality preset description")
        case .custom:
            return String(localized: "Manually configured settings.", comment: "Custom preset description")
        }
    }

    /// Default settings for this preset
    var settings: WhisperSettings {
        var settings = WhisperSettings()

        switch self {
        case .fastest:
            settings.bestOf = 1
            settings.beamSize = 1
            settings.threads = 8
            settings.processors = 2
            settings.flashAttention = true

        case .fast:
            settings.bestOf = 2
            settings.beamSize = 2
            settings.threads = 6
            settings.flashAttention = true

        case .balanced:
            // Use default values
            break

        case .quality:
            settings.bestOf = 8
            settings.beamSize = 8
            settings.threads = 4

        case .bestQuality:
            settings.bestOf = WhisperSettings.maxDecoderCount
            settings.beamSize = WhisperSettings.maxDecoderCount
            settings.entropyThreshold = 2.8
            settings.threads = 4

        case .custom:
            // Use default values as starting point
            break
        }

        return settings
    }

    func apply(to settings: inout WhisperSettings) {
        settings.applyPresetOwnedSettings(from: self.settings)
    }

    /// Check if given settings match this preset
    func matches(_ settings: WhisperSettings) -> Bool {
        guard self != .custom else { return false }

        let presetSettings = self.settings
        return settings.bestOf == presetSettings.bestOf &&
               settings.beamSize == presetSettings.beamSize &&
               settings.threads == presetSettings.threads &&
               settings.processors == presetSettings.processors &&
               settings.flashAttention == presetSettings.flashAttention &&
               settings.entropyThreshold == presetSettings.entropyThreshold
    }

    /// Determine which preset matches the given settings, or .custom if none match
    static func detect(from settings: WhisperSettings) -> WhisperPreset {
        for preset in WhisperPreset.allCases where preset != .custom {
            if preset.matches(settings) {
                return preset
            }
        }
        return .custom
    }
}
