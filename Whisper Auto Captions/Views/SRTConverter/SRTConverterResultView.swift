import SwiftUI

// MARK: - SRT Converter Result View
struct SRTConverterResultView: View {
    @ObservedObject var viewModel: SRTConverterViewModel
    @State private var showOperationError = false
    @State private var operationErrorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)

            Text("Conversion Complete!")
                .font(.title)

            Text("Project: \(viewModel.projectName)")
                .font(.title2)

            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    saveFile(viewModel.outputFCPXMLFilePath)
                }) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Download .fcpxml")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.blue)

                OpenInFinalCutProButton(
                    fcpxmlPath: viewModel.outputFCPXMLFilePath,
                    onFailure: presentOperationError
                )
            }

            // Reset Button
            Button(action: {
                viewModel.reset()
            }) {
                Image(systemName: "arrow.counterclockwise")
                Text("Convert Another File")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
        .alert(String(localized: "Action Failed", comment: "Operation failure alert title"), isPresented: $showOperationError) {
            Button(String(localized: "OK", comment: "OK button")) { }
        } message: {
            Text(operationErrorMessage)
        }
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
