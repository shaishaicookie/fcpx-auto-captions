import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - File Utility
struct FileUtility {
    enum SaveFileError: LocalizedError {
        case sourceMissing(String)
        case copyFailed(String)

        var errorDescription: String? {
            switch self {
            case .sourceMissing(let path):
                return String(localized: "The source file could not be found: \(path)", comment: "Source file missing save error")
            case .copyFailed(let message):
                return String(localized: "Failed to save the file: \(message)", comment: "File save failed error")
            }
        }
    }
    
    // MARK: - Time Formatting
    /// Format seconds into a human-readable time string (MM:SS or HH:MM:SS)
    /// - Parameter seconds: The number of seconds to format
    /// - Returns: Formatted time string
    static func formatSeconds(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.maximumUnitCount = 3
        } else {
            formatter.allowedUnits = [.minute, .second]
            formatter.maximumUnitCount = 2
        }
        
        return formatter.string(from: seconds) ?? "00:00"
    }
    
    // MARK: - File Selection
    /// Present a file selection dialog
    /// - Parameters:
    ///   - allowedTypes: Array of UTTypes to allow
    ///   - allowDirectories: Whether to allow directory selection
    ///   - completion: Callback with selected URL or nil if cancelled
    static func selectFile(
        allowedTypes: [UTType],
        allowDirectories: Bool = false,
        completion: @escaping (URL?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = allowDirectories
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = allowedTypes

        panel.begin { response in
            DispatchQueue.main.async {
                if response == .OK {
                    completion(panel.urls.first)
                } else {
                    completion(nil)
                }
            }
        }
    }

    static func withSecurityScopedAccess<T>(
        to url: URL,
        perform operation: () throws -> T
    ) rethrows -> T {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }

    static func withSecurityScopedAccess<T>(
        to url: URL,
        perform operation: () async throws -> T
    ) async rethrows -> T {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try await operation()
    }

    static func isValidMediaFile(url: URL, allowedTypes: [UTType]) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return false
        }

        guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let contentType = resourceValues.contentType else {
            let extensionLowercased = url.pathExtension.lowercased()
            return allowedTypes.contains { type in
                type.preferredFilenameExtension == extensionLowercased
            }
        }

        return allowedTypes.contains { contentType.conforms(to: $0) }
    }

    static func mediaFileValidationMessage(for url: URL, allowedTypes: [UTType]) -> String {
        let allowedExtensions = allowedTypes.compactMap { $0.preferredFilenameExtension }
        if allowedExtensions.isEmpty {
            return "Only supported media files are allowed."
        }

        let allowedExtensionsText = allowedExtensions.map { ".\($0)" }.joined(separator: ", ")
        return "\(url.lastPathComponent)은(는) 지원하지 않는 파일 형식입니다. 허용 형식: \(allowedExtensionsText)"
    }

    static func saveFileWithDialog(
        filePath: String,
        completion: ((Result<URL, Error>) -> Void)? = nil
    ) {
        let fileURL = URL(fileURLWithPath: filePath)
        let fileManager = FileManager.default

        // Verify source file exists
        guard fileManager.fileExists(atPath: filePath) else {
            completion?(.failure(SaveFileError.sourceMissing(filePath)))
            return
        }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = fileURL.lastPathComponent
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = String(localized: "Save File", comment: "Save panel title")
        savePanel.message = String(localized: "Choose a location to save the file", comment: "Save panel message")

        // Set allowed file type based on the file extension
        let fileExtension = fileURL.pathExtension
        if let contentType = UTType(filenameExtension: fileExtension) {
            savePanel.allowedContentTypes = [contentType]
        }

        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    // Remove existing file if it exists at destination
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.copyItem(at: fileURL, to: destinationURL)
                    completion?(.success(destinationURL))
                } catch {
                    completion?(.failure(SaveFileError.copyFailed(error.localizedDescription)))
                }
            }
        }
    }
}
