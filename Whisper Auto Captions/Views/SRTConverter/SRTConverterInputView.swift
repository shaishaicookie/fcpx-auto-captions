import SwiftUI
import UniformTypeIdentifiers

// MARK: - SRT Converter Input View
struct SRTConverterInputView: View {
    @ObservedObject var viewModel: SRTConverterViewModel

    var body: some View {
        VStack {
            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 20) {
                // SRT File Selection
                GridRow {
                    Text(String(localized: "SRT File:", comment: "SRT file label"))
                        .gridColumnAlignment(.trailing)
                    HStack {
                        Button(action: selectFile) {
                            Text(String(localized: "Choose File", comment: "Choose file button"))
                        }

                        if viewModel.srtFileURL != nil {
                            Text(viewModel.fileName)
                        }
                    }
                    .gridColumnAlignment(.leading)
                }

                // Project Name
                GridRow {
                    Text(String(localized: "Project Name:", comment: "Project name label"))
                    TextField(String(localized: "Project name for FCPXML", comment: "Project name placeholder"), text: $viewModel.projectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
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

                // Title Style Settings
                GridRow {
                    Text(String(localized: "Title Style:", comment: "Title style label"))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(viewModel.titleStyleSummary)
                                .fontWeight(.medium)

                            Button(action: { viewModel.showTitleStyleSettings = true }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.borderless)
                            .help(String(localized: "Configure title style", comment: "Title style settings button tooltip"))
                        }

                        Text(viewModel.titleStyleDetails)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Convert Button
                GridRow {
                    Button(action: viewModel.convertSRTtoFCPXML) {
                        Text(String(localized: "Convert to FCPXML", comment: "Convert button label"))
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .gridCellAnchor(.center)
                    .disabled(!viewModel.canConvert)
                }
                .gridCellColumns(2)
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showTitleStyleSettings) {
            TitleStyleSettingsView(
                viewModel: viewModel,
                availableFonts: viewModel.availableFonts
            )
        }
        .alert(String(localized: "Conversion Failed", comment: "SRT conversion failure alert title"), isPresented: $viewModel.showConversionError) {
            Button(String(localized: "OK", comment: "OK button"), role: .cancel) { }
        } message: {
            Text(viewModel.conversionErrorMessage)
        }
    }

    // MARK: - Actions
    private func selectFile() {
        var allowedTypes: [UTType] = []
        if let srtType = UTType(filenameExtension: "srt") {
            allowedTypes.append(srtType)
        }
        
        FileUtility.selectFile(allowedTypes: allowedTypes, allowDirectories: false) { url in
            if let url {
                viewModel.selectFile(url: url)
            }
        }
    }
}
