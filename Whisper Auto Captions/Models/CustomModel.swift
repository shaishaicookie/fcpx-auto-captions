//
//  CustomModel.swift
//  Whisper Auto Captions
//
//  Data model for user-added custom Whisper models
//

import Foundation

/// Represents a custom Whisper model added by the user
struct CustomModel: Codable, Identifiable, Equatable {
    /// Unique identifier for the model
    let id: UUID

    /// Display name for the model (user-provided)
    var name: String

    /// File name used for storage (without ggml- prefix and .bin extension)
    var fileName: String

    /// Source of the model (URL or local file)
    var source: ModelSource

    /// Whether the model file has been downloaded/imported
    var isDownloaded: Bool

    /// File size in bytes (nil if unknown)
    var fileSize: Int64?

    /// Date when the model was added
    var dateAdded: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        fileName: String,
        source: ModelSource,
        isDownloaded: Bool = false,
        fileSize: Int64? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.source = source
        self.isDownloaded = isDownloaded
        self.fileSize = fileSize
        self.dateAdded = dateAdded
    }

    // MARK: - Computed Properties

    /// Full file name with ggml- prefix and .bin extension
    var fullFileName: String {
        "ggml-\(fileName).bin"
    }

    /// Formatted file size for display
    var formattedFileSize: String {
        guard let size = fileSize else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    /// Source description for display
    var sourceDescription: String {
        switch source {
        case .url:
            return String(localized: "Downloaded", comment: "Custom model source: downloaded from URL")
        case .local:
            return String(localized: "Local", comment: "Custom model source: imported from local file")
        }
    }
}

// MARK: - ModelSource

/// Source of a custom model
enum ModelSource: Codable, Equatable {
    /// Model downloaded from a URL
    case url(String)

    /// Model imported from a local file path
    case local(String)

    /// The source URL or path string
    var path: String {
        switch self {
        case .url(let urlString):
            return urlString
        case .local(let localPath):
            return localPath
        }
    }

    /// Whether this is a URL source
    var isURL: Bool { if case .url = self { true } else { false } }

    /// Whether this is a local source
    var isLocal: Bool { if case .local = self { true } else { false } }
}
