import SwiftUI

// MARK: - Process View
struct ProcessView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showOperationError = false
    @State private var operationErrorMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            header
            statusView
            outputPreview
            actionBar
            progressSection
        }
        .padding()
        .alert(String(localized: "Action Failed", comment: "Operation failure alert title"), isPresented: $showOperationError) {
            Button(String(localized: "OK", comment: "OK button")) { }
        } message: {
            Text(operationErrorMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(String(localized: "Project: \(viewModel.projectName)", comment: "Processing project name label"))
                .font(.title2)
                .lineLimit(1)

            Spacer()

            if viewModel.isProcessingRunning {
                Button(action: viewModel.cancelTranscription) {
                    Image(systemName: "xmark.circle")
                    Text(String(localized: "Cancel", comment: "Cancel transcription button"))
                }
            }

            Button(action: viewModel.reset) {
                Image(systemName: "checkmark.circle")
                Text(String(localized: "Back to Home", comment: "Return to home after processing button"))
            }
            .disabled(!viewModel.isProcessingFinished)
        }
    }

    private var statusView: some View {
        Text(String(localized: "Current Status: \(viewModel.status)", comment: "Processing status label"))
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(2)
    }

    private var outputPreview: some View {
        ScrollView {
            Text(viewModel.outputCaptions)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                saveFile(viewModel.outputSRTFilePath)
            }) {
                Image(systemName: "square.and.arrow.down")
                Text(String(localized: "Save .srt", comment: "Save SRT output button"))
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(!viewModel.isProcessingComplete)

            Button(action: {
                saveFile(viewModel.outputFCPXMLFilePath)
            }) {
                Image(systemName: "square.and.arrow.down")
                Text(String(localized: "Save .fcpxml", comment: "Save FCPXML output button"))
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(!viewModel.isProcessingComplete)

            OpenInFinalCutProButton(
                fcpxmlPath: viewModel.outputFCPXMLFilePath,
                label: String(localized: "Open .fcpxml in Final Cut Pro", comment: "Open FCPXML in Final Cut Pro button"),
                onFailure: presentOperationError
            )
            .disabled(!viewModel.isProcessingComplete)

            Spacer()
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)

            Text(String(localized: "Batch (\(batchDisplayText)): \(viewModel.progressPercentage)% completed - \(viewModel.remainingTime) remaining", comment: "Processing batch progress status"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var batchDisplayText: String {
        let current = viewModel.currentBatch.map(String.init) ?? "..."
        let total = viewModel.totalBatch.map(String.init) ?? "..."
        return "\(current) / \(total)"
    }

    private func saveFile(_ path: String) {
        FileUtility.saveFileWithDialog(filePath: path) { result in
            if case .failure(let error) = result {
                presentOperationError(error.localizedDescription)
            }
        }
    }

    private func presentOperationError(_ message: String) {
        operationErrorMessage = message
        showOperationError = true
    }
}
