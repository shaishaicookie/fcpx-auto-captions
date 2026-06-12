//
//  CustomModelManagementView.swift
//  Whisper Auto Captions
//
//  View for managing custom Whisper models
//

import SwiftUI

/// View for managing custom Whisper models
struct CustomModelManagementView: View {
    @ObservedObject private var modelManager = CustomModelManager.shared
    @ObservedObject private var modelDownloadManager = ModelDownloadManager.shared
    @State private var showAddModelSheet = false
    @State private var modelToDelete: CustomModel?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with add button
            headerSection

            if modelManager.customModels.isEmpty {
                emptyStateView
            } else {
                modelListView
            }

            // Download progress
            if modelDownloadManager.hasPendingDownloads {
                downloadProgressView
            }

            Spacer()
        }
        .sheet(isPresented: $showAddModelSheet) {
            AddCustomModelView()
        }
        .alert(
            String(localized: "Delete Model?", comment: "Delete model confirmation title"),
            isPresented: $showDeleteConfirmation,
            presenting: modelToDelete
        ) { model in
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) { }
            Button(String(localized: "Delete", comment: "Delete button"), role: .destructive) {
                modelManager.removeModel(model)
            }
        } message: { model in
            Text(String(localized: "Are you sure you want to delete \"\(model.name)\"? This will also remove the downloaded model file.", comment: "Delete model confirmation message"))
        }
        .alert(
            String(localized: "Download Failed", comment: "Download failure alert title"),
            isPresented: Binding(
                get: { modelDownloadManager.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        modelDownloadManager.errorMessage = nil
                    }
                }
            )
        ) {
            Button(String(localized: "OK", comment: "OK button")) {
                modelDownloadManager.errorMessage = nil
            }
        } message: {
            Text(modelDownloadManager.errorMessage ?? "")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Custom models are user-added GGML Whisper models.", comment: "Custom models description"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showAddModelSheet = true }) {
                Label(
                    String(localized: "Add Model", comment: "Add model button"),
                    systemImage: "plus"
                )
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.box")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(String(localized: "No Custom Models", comment: "No custom models title"))
                .font(.headline)

            Text(String(localized: "Add custom GGML models from URLs or local files.", comment: "No custom models description"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showAddModelSheet = true }) {
                Label(
                    String(localized: "Add Your First Model", comment: "Add first model button"),
                    systemImage: "plus"
                )
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Model List

    private var modelListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(modelManager.customModels) { model in
                    CustomModelRow(
                        model: model,
                        isDownloading: modelDownloadManager.currentTargetID == model.id.uuidString,
                        isQueued: modelDownloadManager.isQueued(model.id.uuidString),
                        isActionDisabled: modelDownloadManager.isActiveOrQueued(model.id.uuidString),
                        downloadProgress: modelDownloadManager.currentTargetID == model.id.uuidString ? modelDownloadManager.progress : 0,
                        onDownload: {
                            modelManager.downloadModel(model) { _, _ in }
                        },
                        onCancelQueued: {
                            modelDownloadManager.cancelQueuedDownload(targetID: model.id.uuidString)
                        },
                        onDelete: {
                            modelToDelete = model
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
        }
    }

    // MARK: - Download Progress

    private var downloadProgressView: some View {
        VStack(spacing: 8) {
            if modelDownloadManager.isDownloading, let modelName = modelDownloadManager.currentDisplayName {
                HStack {
                    Text(String(localized: "Downloading \(modelName)...", comment: "Downloading model status"))
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.0f%%", modelDownloadManager.progress * 100))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: modelDownloadManager.progress)
                    .progressViewStyle(.linear)
            }

            if modelDownloadManager.queuedCount > 0 {
                Text(String(localized: "Queued downloads: \(modelDownloadManager.queuedCount)", comment: "Queued model download count"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                if modelDownloadManager.isDownloading {
                    Button(String(localized: "Cancel Current", comment: "Cancel current download button")) {
                        modelDownloadManager.cancelDownload()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }

                Button(String(localized: "Cancel All", comment: "Cancel all downloads button")) {
                    modelDownloadManager.cancelAllDownloads()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Custom Model Row

/// Row view for displaying a single custom model
struct CustomModelRow: View {
    let model: CustomModel
    let isDownloading: Bool
    let isQueued: Bool
    let isActionDisabled: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    let onCancelQueued: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: model.isDownloaded ? "cube.box.fill" : "cube.box")
                .font(.title2)
                .foregroundColor(model.isDownloaded ? .accentColor : .secondary)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    // Source badge
                    Text(model.sourceDescription)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)

                    // File size
                    if let _ = model.fileSize {
                        Text(model.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Status
                    if isQueued {
                        Text(String(localized: "Queued", comment: "Model download queued status"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !model.isDownloaded && !isDownloading {
                        Text(String(localized: "Not downloaded", comment: "Model not downloaded status"))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                if isDownloading {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                        .frame(width: 24, height: 24)
                } else if isQueued {
                    Button(action: onCancelQueued) {
                        Image(systemName: "xmark.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                    .help(String(localized: "Cancel queued download", comment: "Cancel queued model download tooltip"))
                } else if !model.isDownloaded && model.source.isURL {
                    Button(action: onDownload) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .disabled(isActionDisabled)
                    .help(String(localized: "Download model", comment: "Download model button tooltip"))
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .disabled(isActionDisabled)
                .help(String(localized: "Delete model", comment: "Delete model button tooltip"))
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#if DEBUG
struct CustomModelManagementView_Previews: PreviewProvider {
    static var previews: some View {
        CustomModelManagementView()
            .frame(width: 400, height: 400)
            .padding()
    }
}
#endif
