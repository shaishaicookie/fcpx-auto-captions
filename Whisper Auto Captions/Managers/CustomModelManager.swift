//
//  CustomModelManager.swift
//  Whisper Auto Captions
//
//  Manages custom Whisper models - adding, removing, and accessing
//

import Foundation

/// Manages user-added custom Whisper models
class CustomModelManager: ObservableObject {
    // MARK: - Singleton

    static let shared = CustomModelManager()

    // MARK: - Published Properties

    @Published private(set) var customModels: [CustomModel] = []

    // MARK: - Private Properties

    private let modelDownloadManager = ModelDownloadManager.shared
    private let minimumValidModelSize: Int64 = 50 * 1024 * 1024

    // MARK: - Initialization

    private init() {
        loadModels()
    }

    // MARK: - Model Management

    /// Add a new model from a URL
    /// - Parameters:
    ///   - name: Display name for the model
    ///   - urlString: URL to download the model from
    /// - Returns: The created CustomModel
    @discardableResult
    func addModel(name: String, url urlString: String) -> CustomModel {
        let fileName = sanitizeFileName(name)
        let model = CustomModel(
            name: name,
            fileName: fileName,
            source: .url(urlString),
            isDownloaded: false
        )
        customModels.append(model)
        saveModels()
        return model
    }

    /// Add a new model from a local file
    /// - Parameters:
    ///   - name: Display name for the model
    ///   - localPath: Path to the local .bin file
    /// - Returns: The created CustomModel, or nil if import failed
    @discardableResult
    func addModel(name: String, localPath: String) -> CustomModel? {
        guard localModelValidationError(atPath: localPath) == nil else {
            return nil
        }

        let sourceURL = URL(fileURLWithPath: localPath)

        let fileSize = getFileSize(atPath: localPath)

        let fileName = sanitizeFileName(name)
        var model = CustomModel(
            name: name,
            fileName: fileName,
            source: .local(localPath),
            isDownloaded: false,
            fileSize: fileSize
        )

        // Copy file to app directory
        do {
            let destinationURL = try getCustomModelPath(for: model)
            try AppDirectoryUtility.ensureDirectoryExists()

            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            model.isDownloaded = true
        } catch {
            print("Failed to import local model: \(error)")
            return nil
        }

        customModels.append(model)
        saveModels()
        return model
    }

    /// Remove a custom model
    /// - Parameter model: The model to remove
    /// - Parameter deleteFile: Whether to delete the model file (default: true)
    func removeModel(_ model: CustomModel, deleteFile: Bool = true) {
        // Remove file if requested and it was downloaded
        if deleteFile, model.isDownloaded {
            if let path = try? getCustomModelPath(for: model) {
                try? FileManager.default.removeItem(at: path)
            }
        }

        customModels.removeAll { $0.id == model.id }
        saveModels()
    }

    /// Get the file path for a custom model
    /// - Parameter model: The custom model
    /// - Returns: URL to the model file
    func getCustomModelPath(for model: CustomModel) throws -> URL {
        let directory = try AppDirectoryUtility.getAppSupportDirectory()
        return directory.appendingPathComponent(model.fullFileName)
    }

    /// Check if a custom model is downloaded
    /// - Parameter model: The model to check
    /// - Returns: true if the model file exists
    func isDownloaded(_ model: CustomModel) -> Bool {
        guard let path = try? getCustomModelPath(for: model) else {
            return false
        }
        return FileManager.default.fileExists(atPath: path.path)
    }

    func localModelValidationError(atPath path: String) -> String? {
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return String(localized: "The selected model file does not exist.", comment: "Missing local model file error")
        }

        guard !isDirectory.boolValue else {
            return String(localized: "Select a GGML model .bin file, not a folder.", comment: "Local model folder selected error")
        }

        let url = URL(fileURLWithPath: path)
        guard url.pathExtension.lowercased() == "bin" else {
            return String(localized: "Select a GGML model file with a .bin extension.", comment: "Invalid local model extension error")
        }

        guard let fileSize = getFileSize(atPath: path) else {
            return String(localized: "Could not read the selected model file.", comment: "Unreadable local model file error")
        }

        guard fileSize >= minimumValidModelSize else {
            return String(localized: "The selected file is too small to be a valid GGML Whisper model.", comment: "Local model file too small error")
        }

        return nil
    }

    /// Find a custom model by name
    /// - Parameter name: The model name to search for
    /// - Returns: The custom model if found
    func findModel(byName name: String) -> CustomModel? {
        return customModels.first { $0.name == name }
    }

    /// Check if a model name is a custom model
    /// - Parameter name: The model name to check
    /// - Returns: true if this is a custom model name
    func isCustomModel(_ name: String) -> Bool {
        return findModel(byName: name) != nil
    }

    // MARK: - Download

    /// Download a custom model from its URL
    /// - Parameters:
    ///   - model: The model to download
    ///   - completion: Called with success/failure when complete
    func downloadModel(
        _ model: CustomModel,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard case .url(let urlString) = model.source,
              let url = URL(string: urlString) else {
            let message = String(localized: "The model download URL is invalid.", comment: "Invalid custom model URL error")
            modelDownloadManager.errorMessage = message
            completion(false, message)
            return
        }

        let target = ModelDownloadTarget(
            id: model.id.uuidString,
            displayName: model.name,
            fileName: model.fileName,
            url: url
        )

        modelDownloadManager.download(target: target) { [weak self] success, errorMessage in
            if success {
                self?.handleDownloadComplete(model: model)
            }
            completion(success, errorMessage)
        }
    }

    /// Cancel the current download
    func cancelDownload() {
        modelDownloadManager.cancelDownload()
    }

    // MARK: - Private Methods

    private func getFileSize(atPath path: String) -> Int64? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else { return nil }
        return size
    }

    private func handleDownloadComplete(model: CustomModel) {
        if let index = customModels.firstIndex(where: { $0.id == model.id }) {
            customModels[index].isDownloaded = true
            if let path = try? getCustomModelPath(for: model) {
                customModels[index].fileSize = getFileSize(atPath: path.path)
            }
            saveModels()
        }
    }

    private func sanitizeFileName(_ name: String) -> String {
        // Remove spaces and special characters, lowercase
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = name
            .lowercased()
            .components(separatedBy: allowed.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        // Ensure unique by adding timestamp if needed
        if customModels.contains(where: { $0.fileName == sanitized }) {
            return "\(sanitized)-\(Int(Date().timeIntervalSince1970))"
        }
        return sanitized
    }

    // MARK: - Persistence

    private func loadModels() {
        customModels = SettingsManager.shared.settings.customModels

        // Verify download status for each model
        for i in customModels.indices {
            customModels[i].isDownloaded = isDownloaded(customModels[i])
        }
    }

    private func saveModels() {
        SettingsManager.shared.settings.customModels = customModels
    }
}
