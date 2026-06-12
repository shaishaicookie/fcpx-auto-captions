//
//  AddCustomModelView.swift
//  Whisper Auto Captions
//
//  Sheet view for adding a new custom Whisper model
//

import SwiftUI
import UniformTypeIdentifiers

/// View for adding a new custom Whisper model
struct AddCustomModelView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var modelManager = CustomModelManager.shared

    // MARK: - State

    @State private var modelName: String = ""
    @State private var sourceType: SourceType = .url
    @State private var urlString: String = ""
    @State private var localFilePath: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    enum SourceType: String, CaseIterable {
        case url = "URL"
        case local = "Local File"

        var localizedName: String {
            switch self {
            case .url:
                return String(localized: "Download from URL", comment: "URL source option")
            case .local:
                return String(localized: "Import Local File", comment: "Local file source option")
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    modelNameSection
                    sourceTypeSection
                    sourceInputSection
                }
                .padding()
            }

            Divider()

            // Footer
            footer
        }
        .frame(width: 500, height: 380)
        .alert(String(localized: "Error", comment: "Error alert title"), isPresented: $showError) {
            Button(String(localized: "OK", comment: "OK button")) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(String(localized: "Add Custom Model", comment: "Add custom model sheet title"))
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
    }

    // MARK: - Model Name Section

    private var modelNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Model Name", comment: "Model name field label"))
                .font(.headline)

            TextField(
                String(localized: "Enter a name for this model", comment: "Model name placeholder"),
                text: $modelName
            )
            .textFieldStyle(.roundedBorder)

            Text(String(localized: "This name will appear in the model selection dropdown.", comment: "Model name help text"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Source Type Section

    private var sourceTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Source", comment: "Source type field label"))
                .font(.headline)

            Picker(selection: $sourceType, label: EmptyView()) {
                ForEach(SourceType.allCases, id: \.self) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Source Input Section

    private var sourceInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch sourceType {
            case .url:
                urlInputSection
            case .local:
                localFileSection
            }
        }
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Model URL", comment: "Model URL field label"))
                .font(.headline)

            TextField(
                "https://huggingface.co/.../ggml-model.bin",
                text: $urlString
            )
            .textFieldStyle(.roundedBorder)

            Text(String(localized: "Enter the direct download URL for a GGML model file (.bin)", comment: "URL help text"))
                .font(.caption)
                .foregroundColor(.secondary)

            // Example URLs
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Common sources:", comment: "Common sources label"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• HuggingFace: huggingface.co/...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• GitHub Releases: github.com/.../releases/...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private var localFileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Local File", comment: "Local file field label"))
                .font(.headline)

            HStack {
                TextField(
                    String(localized: "No file selected", comment: "No file selected placeholder"),
                    text: $localFilePath
                )
                .textFieldStyle(.roundedBorder)
                .disabled(true)

                Button(String(localized: "Choose...", comment: "Choose file button")) {
                    selectLocalFile()
                }
            }

            Text(String(localized: "Select a GGML model file (.bin) from your computer.", comment: "Local file help text"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(String(localized: "Cancel", comment: "Cancel button")) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button(String(localized: "Add Model", comment: "Add model button")) {
                addModel()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
    }

    // MARK: - Validation

    private var isValid: Bool {
        guard !modelName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        switch sourceType {
        case .url:
            return isValidURL(urlString)
        case .local:
            return !localFilePath.isEmpty && FileManager.default.fileExists(atPath: localFilePath)
        }
    }

    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return false
        }
        return true
    }

    // MARK: - Actions

    private func selectLocalFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "bin") ?? .data]
        panel.message = String(localized: "Select a GGML Whisper model file", comment: "File picker message")

        panel.begin { response in
            DispatchQueue.main.async {
                if response == .OK, let url = panel.url {
                    localFilePath = url.path
                }
            }
        }
    }

    private func addModel() {
        let trimmedName = modelName.trimmingCharacters(in: .whitespaces)

        // Check for duplicate names
        if modelManager.findModel(byName: trimmedName) != nil {
            errorMessage = String(localized: "A model with this name already exists.", comment: "Duplicate model name error")
            showError = true
            return
        }

        switch sourceType {
        case .url:
            let model = modelManager.addModel(name: trimmedName, url: urlString)
            // Start download immediately
            modelManager.downloadModel(model) { success, _ in
                if !success {
                    // Model was added but download failed - user can retry later
                }
            }
            dismiss()

        case .local:
            if let validationError = modelManager.localModelValidationError(atPath: localFilePath) {
                errorMessage = validationError
                showError = true
                return
            }

            if modelManager.addModel(name: trimmedName, localPath: localFilePath) != nil {
                dismiss()
            } else {
                errorMessage = String(localized: "Failed to import the model file.", comment: "Import failed error")
                showError = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AddCustomModelView_Previews: PreviewProvider {
    static var previews: some View {
        AddCustomModelView()
    }
}
#endif
