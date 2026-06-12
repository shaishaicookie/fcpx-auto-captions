//
//  UpdateService.swift
//  Whisper Auto Captions
//
//  Handles automatic app updates via Sparkle framework
//

import Foundation
import Sparkle

/// Service class that manages app updates using Sparkle framework
@MainActor
final class UpdateService: ObservableObject {
    /// Shared singleton instance
    static let shared = UpdateService()

    /// Sparkle's standard updater controller
    private let updaterController: SPUStandardUpdaterController

    /// The underlying updater instance
    var updater: SPUUpdater {
        updaterController.updater
    }

    /// Whether the app can check for updates
    @Published var canCheckForUpdates = false

    private init() {
        // Initialize the updater controller
        // This automatically starts the update lifecycle
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Observe canCheckForUpdates changes
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Manually check for updates
    func checkForUpdates() {
        updater.checkForUpdates()
    }

    /// Whether to automatically check for updates
    var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set { updater.automaticallyChecksForUpdates = newValue }
    }

    /// Whether to automatically download updates
    var automaticallyDownloadsUpdates: Bool {
        get { updater.automaticallyDownloadsUpdates }
        set { updater.automaticallyDownloadsUpdates = newValue }
    }

    /// The update check interval in seconds
    var updateCheckInterval: TimeInterval {
        get { updater.updateCheckInterval }
        set { updater.updateCheckInterval = newValue }
    }

    /// The last update check date
    var lastUpdateCheckDate: Date? {
        updater.lastUpdateCheckDate
    }
}
