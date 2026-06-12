//
//  GeneralSettingsView.swift
//  Whisper Auto Captions
//
//  General settings including software updates
//

import SwiftUI

struct GeneralSettingsView: View {
    @StateObject private var updateService = UpdateService.shared
    @State private var automaticallyCheckForUpdates = true
    @State private var automaticallyDownloadUpdates = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Software Updates Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(String(localized: "Software Updates", comment: "Software updates section title"))
                            .font(.headline)
                        Spacer()
                    }

                    Divider()

                    // Check for Updates Button
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "Check for Updates", comment: "Check for updates label"))
                                .font(.body)
                            if let lastCheck = updateService.lastUpdateCheckDate {
                                Text(String(localized: "Last checked: \(lastCheck.formatted(date: .abbreviated, time: .shortened))", comment: "Last update check date"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(String(localized: "Check Now", comment: "Check for updates button")) {
                            updateService.checkForUpdates()
                        }
                        .disabled(!updateService.canCheckForUpdates)
                    }

                    Divider()

                    // Automatic Updates Toggle
                    Toggle(isOn: $automaticallyCheckForUpdates) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Automatically check for updates", comment: "Auto check updates toggle"))
                            Text(String(localized: "Periodically check for new versions in the background", comment: "Auto check updates description"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: automaticallyCheckForUpdates) { newValue in
                        updateService.automaticallyChecksForUpdates = newValue
                    }

                    // Automatic Download Toggle
                    Toggle(isOn: $automaticallyDownloadUpdates) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Automatically download updates", comment: "Auto download updates toggle"))
                            Text(String(localized: "Download updates in the background when available", comment: "Auto download updates description"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: automaticallyDownloadUpdates) { newValue in
                        updateService.automaticallyDownloadsUpdates = newValue
                    }
                    .disabled(!automaticallyCheckForUpdates)
                }
                .padding(8)
            }

            // App Info Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(String(localized: "About", comment: "About section title"))
                            .font(.headline)
                        Spacer()
                    }

                    Divider()

                    HStack {
                        Text(String(localized: "Version", comment: "Version label"))
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(String(localized: "Build", comment: "Build label"))
                        Spacer()
                        Text(appBuild)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
            }

            Spacer()
        }
        .onAppear {
            automaticallyCheckForUpdates = updateService.automaticallyChecksForUpdates
            automaticallyDownloadUpdates = updateService.automaticallyDownloadsUpdates
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 400, height: 400)
        .padding()
}
