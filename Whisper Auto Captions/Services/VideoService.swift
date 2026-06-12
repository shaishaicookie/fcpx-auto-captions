//
//  VideoService.swift
//  Whisper Auto Captions
//
//  Handles video file analysis for frame rate extraction
//

import Foundation
import AVFoundation

/// Service for video file operations
class VideoService {
    // MARK: - Singleton
    static let shared = VideoService()
    private init() {}

    // MARK: - Supported Video Extensions
    private let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv", "webm", "mxf"]

    // MARK: - Video File Detection
    /// Check if the given URL is a video file
    func isVideoFile(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return videoExtensions.contains(ext)
    }

    // MARK: - Frame Rate Extraction
    /// Extract frame rate from a video file using AVFoundation
    /// - Parameter url: The URL of the video file
    /// - Returns: The frame rate as a Float, or nil if extraction fails
    func extractFrameRate(from url: URL) async -> Float? {
        await FileUtility.withSecurityScopedAccess(to: url) {
            let asset = AVURLAsset(url: url)

            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let videoTrack = tracks.first else {
                    return nil
                }

                let frameRate = try await videoTrack.load(.nominalFrameRate)
                return frameRate > 0 ? frameRate : nil
            } catch {
                return nil
            }
        }
    }
}
