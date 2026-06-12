import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var customModelManager = CustomModelManager.shared
    @ObservedObject private var modelDownloadManager = ModelDownloadManager.shared
    @State private var showInvalidFileAlert = false
    @State private var invalidFileErrorMessage = ""

    var body: some View {
        VStack {
            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 20) {
                // Video/Audio File Selection
                GridRow {
                    Text("Video/Audio File:")
                        .gridColumnAlignment(.trailing)
                    HStack {
                        Button(action: selectFile) {
                            Text("Choose File")
                        }

                        if viewModel.fileURL != nil {
                            Text(viewModel.fileName)
                        }
                    }
                    .gridColumnAlignment(.leading)
                }

                // Frame Rate Selection
                GridRow {
                    Text(String(localized: "Frame Rate:", comment: "Frame rate label"))
                    FrameRatePicker(
                        selectedFrameRate: $viewModel.selectedFrameRate,
                        customFps: $viewModel.customFps,
                        isFpsValid: viewModel.isFpsValid
                    )
                }

                // Resolution Selection
                GridRow {
                    Text(String(localized: "Resolution:", comment: "Resolution label"))
                    VStack(alignment: .leading, spacing: 8) {
                        Picker(selection: $viewModel.selectedResolution, label: EmptyView()) {
                            ForEach(VideoResolution.allCases) { resolution in
                                Text(resolution.displayName).tag(resolution)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 300, alignment: .leading)

                        if viewModel.selectedResolution == .custom {
                            HStack(spacing: 8) {
                                TextField(String(localized: "Width", comment: "Width placeholder"), text: $viewModel.customWidth)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 70)
                                Text("×")
                                TextField(String(localized: "Height", comment: "Height placeholder"), text: $viewModel.customHeight)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 70)
                            }

                            if let warning = viewModel.resolutionWarning {
                                Text(warning)
                                    .font(.caption)
                                    .foregroundColor(viewModel.isResolutionValid ? .orange : .red)
                            }
                        }
                    }
                }

                // Model Selection
                GridRow {
                    Text(String(localized: "Model:", comment: "Model label"))
                    HStack(spacing: 8) {
                        Picker(selection: $viewModel.selectedModel, label: EmptyView()) {
                            // Built-in models
                            ForEach(viewModel.models, id: \.self) { model in
                                Text(model).tag(model)
                            }

                            // Custom models (if any)
                            if !customModelManager.customModels.isEmpty {
                                Divider()

                                ForEach(customModelManager.customModels) { customModel in
                                    HStack {
                                        Text(customModel.name)
                                        if !customModel.isDownloaded {
                                            Image(systemName: "arrow.down.circle")
                                                .font(.caption)
                                        }
                                    }
                                    .tag(customModel.name)
                                }
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 300, alignment: .leading)

                        selectedModelDownloadControl
                    }
                }

                // Language Selection
                GridRow {
                    Text(String(localized: "Language:", comment: "Language label"))
                    Picker(selection: $viewModel.selectedLanguage, label: EmptyView()) {
                        ForEach(viewModel.languages, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 300, alignment: .leading)
                }

                // Settings Summary
                GridRow {
                    Text(String(localized: "Settings:", comment: "Settings label"))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(settingsManager.presetDisplayName)
                                .fontWeight(.medium)

                            Button(action: { viewModel.showSettings = true }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.borderless)
                            .help(String(localized: "Open settings", comment: "Settings button tooltip"))
                        }

                        Text(settingsManager.settingsSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Action Buttons
                GridRow {
                    VStack(spacing: 8) {
                        Button(action: viewModel.validateAndStartTranscription) {
                            Text(String(localized: "Create", comment: "Create button"))
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(!viewModel.canStartTranscription || viewModel.isSelectedModelStartPending)

                        if let reason = viewModel.transcriptionBlockReason {
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else if viewModel.isSelectedModelStartPending {
                            Text(String(localized: "Transcription will start after the selected model downloads.", comment: "Pending transcription after model download status"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .gridCellColumns(2)
                .gridCellAnchor(.center)
            }
            .padding()

            if modelDownloadManager.hasPendingDownloads {
                VStack(spacing: 8) {
                    if modelDownloadManager.isDownloading {
                        HStack {
                            Text(String(localized: "Downloading \(modelDownloadManager.currentDisplayName ?? viewModel.selectedModel) Model", comment: "Model download status"))
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f%%", modelDownloadManager.progress * 100))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        ProgressView(value: modelDownloadManager.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }

                    if modelDownloadManager.queuedCount > 0 {
                        Text(String(localized: "Queued downloads: \(modelDownloadManager.queuedCount)", comment: "Queued model download count"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if viewModel.hasStartPendingDownload {
                        Text(String(localized: "A transcription is waiting for its model download.", comment: "Pending transcription download status"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Button(String(localized: "Cancel Current", comment: "Cancel current download button")) {
                            modelDownloadManager.cancelDownload()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                        .disabled(!modelDownloadManager.isDownloading)

                        Button(String(localized: "Cancel All", comment: "Cancel all downloads button")) {
                            viewModel.cancelAllModelDownloads()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                    }
                }
                .frame(width: 280)
                .padding()
            }
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
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsWindowView()
        }
        .alert("Invalid File", isPresented: $showInvalidFileAlert) {
            Button("OK", role: .cancel) {
                showInvalidFileAlert = false
            }
        } message: {
            Text(invalidFileErrorMessage)
        }
        .onReceive(customModelManager.$customModels) { _ in
            viewModel.reconcileSelectedModelWithAvailableModels()
        }
    }

    @ViewBuilder
    private var selectedModelDownloadControl: some View {
        if viewModel.isSelectedModelDownloading {
            ProgressView(value: modelDownloadManager.progress)
                .progressViewStyle(.circular)
                .scaleEffect(0.65)
                .frame(width: 24, height: 24)
                .help(String(localized: "Downloading selected model", comment: "Selected model downloading tooltip"))
        } else if viewModel.isSelectedModelQueued {
            Button(action: viewModel.cancelSelectedQueuedDownload) {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
            .help(String(localized: "Cancel queued download for selected model", comment: "Cancel selected queued model tooltip"))
        } else if viewModel.canDownloadSelectedModel {
            Button(action: viewModel.downloadSelectedModel) {
                Image(systemName: "arrow.down.circle")
            }
            .buttonStyle(.borderless)
            .help(String(localized: "Download selected model", comment: "Download selected model tooltip"))
        }
    }
    
    // MARK: - Actions
    private func selectFile() {
        FileUtility.selectFile(allowedTypes: [.audio, .movie], allowDirectories: false) { url in
            guard let url else { return }

            let isValidFile = FileUtility.withSecurityScopedAccess(to: url) {
                FileUtility.isValidMediaFile(url: url, allowedTypes: [.audio, .movie])
            }

            if isValidFile {
                viewModel.selectFile(url: url)
            } else {
                invalidFileErrorMessage = FileUtility.mediaFileValidationMessage(
                    for: url,
                    allowedTypes: [.audio, .movie]
                )
                showInvalidFileAlert = true
            }
        }
    }
}
