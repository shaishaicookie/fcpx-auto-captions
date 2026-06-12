//
//  SettingsManager.swift
//  Whisper Auto Captions
//
//  Manages application settings persistence and state
//

import Foundation
import SwiftUI

struct SRTConverterSettings: Codable, Equatable {
    var selectedResolution: String = VideoResolution.fullHD1080p.rawValue
    var customWidth: String = "1920"
    var customHeight: String = "1080"
    var selectedFrameRate: String = FrameRate.fps30.rawValue
    var customFps: String = "30"
}

/// Manages WhisperSettings persistence using AppStorage
class SettingsManager: ObservableObject {
    // MARK: - Singleton
    static let shared = SettingsManager()

    // MARK: - Published Properties
    @Published var settings: WhisperSettings {
        didSet {
            saveSettings()
            if !isUpdatingFromPreset {
                updatePreset()
            }
        }
    }

    @Published var currentPreset: WhisperPreset = .balanced {
        didSet {
            if currentPreset != .custom {
                applyPreset(currentPreset)
            }
        }
    }

    // MARK: - Title Style Settings
    @Published var titleStyleSettings: TitleStyleSettings {
        didSet {
            saveTitleStyleSettings()
        }
    }

    @Published var srtConverterSettings: SRTConverterSettings {
        didSet {
            saveSRTConverterSettings()
        }
    }

    // MARK: - Storage Keys
    private enum StorageKeys {
        static let settings = "whisperSettings"
        static let preset = "whisperPreset"
        static let titleStyle = "titleStyleSettings"
        static let srtConverter = "srtConverterSettings"
    }

    // MARK: - UserDefaults
    private let defaults = UserDefaults.standard

    // MARK: - Circular Update Prevention
    private var isUpdatingFromPreset = false

    // MARK: - Initialization
    private init() {
        // Load settings from UserDefaults
        var loadedSettings: WhisperSettings
        if let data = defaults.data(forKey: StorageKeys.settings),
           let decoded = try? JSONDecoder().decode(WhisperSettings.self, from: data) {
            loadedSettings = decoded
        } else {
            loadedSettings = WhisperSettings.default
        }
        loadedSettings.clampDecoderSettings()
        self.settings = loadedSettings

        // Load title style settings from UserDefaults
        if let data = defaults.data(forKey: StorageKeys.titleStyle),
           let decoded = try? JSONDecoder().decode(TitleStyleSettings.self, from: data) {
            self.titleStyleSettings = decoded
        } else {
            self.titleStyleSettings = TitleStyleSettings.default
        }

        if let data = defaults.data(forKey: StorageKeys.srtConverter),
           let decoded = try? JSONDecoder().decode(SRTConverterSettings.self, from: data) {
            self.srtConverterSettings = decoded
        } else {
            self.srtConverterSettings = SRTConverterSettings()
        }

        // Load preset from UserDefaults (after all stored properties are initialized)
        if let presetRaw = defaults.string(forKey: StorageKeys.preset),
           let preset = WhisperPreset(rawValue: presetRaw) {
            self.currentPreset = preset
        } else {
            self.currentPreset = WhisperPreset.detect(from: loadedSettings)
        }
    }

    // MARK: - Persistence
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: StorageKeys.settings)
        }
        defaults.set(currentPreset.rawValue, forKey: StorageKeys.preset)
    }

    private func saveTitleStyleSettings() {
        if let encoded = try? JSONEncoder().encode(titleStyleSettings) {
            defaults.set(encoded, forKey: StorageKeys.titleStyle)
        }
    }

    private func saveSRTConverterSettings() {
        if let encoded = try? JSONEncoder().encode(srtConverterSettings) {
            defaults.set(encoded, forKey: StorageKeys.srtConverter)
        }
    }

    // MARK: - Preset Management
    private func updatePreset() {
        let detected = WhisperPreset.detect(from: settings)
        if detected != currentPreset && currentPreset != .custom {
            currentPreset = .custom
        }
    }

    func applyPreset(_ preset: WhisperPreset) {
        guard preset != .custom else { return }

        isUpdatingFromPreset = true
        defer { isUpdatingFromPreset = false }

        preset.apply(to: &settings)
    }

    func resetToDefaults() {
        settings = WhisperSettings.default
        currentPreset = .balanced
        titleStyleSettings = TitleStyleSettings.default
    }

    // MARK: - Convenience Accessors
    var model: String {
        get { settings.model }
        set { settings.model = newValue }
    }

    var language: String {
        get { settings.language }
        set { settings.language = newValue }
    }

    var fps: String {
        get { settings.fps }
        set { settings.fps = newValue }
    }

    // MARK: - Settings Summary
    /// Returns a summary text describing the current settings
    var settingsSummary: String {
        let bestOf = WhisperSettings.clampedDecoderCount(settings.bestOf)
        let beam = WhisperSettings.clampedDecoderCount(settings.beamSize)
        return "best-of: \(bestOf), beam: \(beam)"
    }

    /// Returns the display name for the current preset
    var presetDisplayName: String {
        currentPreset.displayName
    }
}
