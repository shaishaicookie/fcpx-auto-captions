//
//  AudioService.swift
//  Whisper Auto Captions
//
//  Handles audio file conversion and splitting
//

import Foundation
import AVFoundation

/// Service for audio file operations
class AudioService {
    // MARK: - Singleton
    static let shared = AudioService()
    private init() {}

    typealias ProcessUpdate = (Process?) -> Void

    enum AudioPreparationError: Error {
        case copyFailed(String)
        case ffmpegNotFound
        case ffmpegLaunchFailed(String)
        case ffmpegConversionFailed(status: Int32, details: String)
        case outputMissing

        var userMessage: String {
            switch self {
            case .copyFailed(let details):
                return String(localized: "Failed to copy the prepared audio file. \(details)", comment: "Audio preparation copy failure")
            case .ffmpegNotFound:
                return String(localized: "FFmpeg was not found in the app bundle.", comment: "Missing FFmpeg error")
            case .ffmpegLaunchFailed(let details):
                return String(localized: "Failed to start FFmpeg. \(details)", comment: "FFmpeg launch failure")
            case .ffmpegConversionFailed(_, let details):
                let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedDetails.isEmpty {
                    return String(localized: "FFmpeg failed to convert the audio.", comment: "FFmpeg conversion failure without details")
                }
                return String(localized: "FFmpeg failed to convert the audio. \(trimmedDetails)", comment: "FFmpeg conversion failure with details")
            case .outputMissing:
                return String(localized: "FFmpeg finished, but the prepared audio file was not created.", comment: "Missing prepared audio output")
            }
        }
    }

    // MARK: - Constants
    private let whisperSampleRate: Double = 16000  // Required sample rate for whisper.cpp

    // MARK: - Audio Analysis

    /// Get the sample rate of an audio file
    func getAudioSampleRate(_ path: String) -> Double? {
        let url = URL(fileURLWithPath: path)
        guard let audioFile = try? AVAudioFile(forReading: url) else { return nil }
        return audioFile.processingFormat.sampleRate
    }

    /// Check if the audio file needs conversion for whisper.cpp
    /// Returns false only if it's already a 16kHz WAV file
    func needsConversion(_ path: String) -> Bool {
        // Not a WAV file -> needs conversion
        guard path.lowercased().hasSuffix(".wav") else { return true }

        // Check sample rate - must be 16kHz for whisper.cpp
        guard let sampleRate = getAudioSampleRate(path),
              sampleRate == whisperSampleRate else { return true }

        return false
    }

    // MARK: - Audio Preparation

    /// Prepare input audio file for whisper.cpp processing
    /// - If input is already a 16kHz WAV, copies it into the temp workspace
    /// - Otherwise, converts to 16kHz mono WAV using ffmpeg
    func prepareAudioForWhisper(
        inputPath: String,
        projectName: String,
        tempFolder: String,
        processUpdate: ProcessUpdate? = nil
    ) -> Result<String, AudioPreparationError> {
        let wavFilePath = uniqueWavFilePath(projectName: projectName, tempFolder: tempFolder)
        let fileManager = FileManager.default

        // Keep all intermediate outputs in the temp workspace, even when no conversion is needed.
        if !needsConversion(inputPath) {
            do {
                try fileManager.copyItem(atPath: inputPath, toPath: wavFilePath)
            } catch {
                return .failure(.copyFailed(error.localizedDescription))
            }
            return .success(wavFilePath)
        }

        guard let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) else {
            return .failure(.ffmpegNotFound)
        }

        // Convert to 16kHz mono 16-bit PCM WAV
        let task = Process()
        task.executableURL = URL(fileURLWithPath: ffmpegPath)
        task.arguments = [
            "-hide_banner",
            "-nostdin",
            "-y",
            "-loglevel", "error",
            "-i", inputPath,
            "-ar", "16000",
            "-ac", "1",
            "-c:a", "pcm_s16le",
            wavFilePath
        ]

        let errorPipe = Pipe()
        task.standardError = errorPipe
        task.standardOutput = Pipe()

        do {
            try task.run()
        } catch {
            return .failure(.ffmpegLaunchFailed(error.localizedDescription))
        }

        processUpdate?(task)
        task.waitUntilExit()
        processUpdate?(nil)

        let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard task.terminationStatus == 0 else {
            return .failure(.ffmpegConversionFailed(
                status: task.terminationStatus,
                details: Self.lastMeaningfulLines(from: errorOutput)
            ))
        }

        guard isNonEmptyFile(atPath: wavFilePath) else {
            return .failure(.outputMissing)
        }

        return .success(wavFilePath)
    }

    private func uniqueWavFilePath(projectName: String, tempFolder: String) -> String {
        let fileManager = FileManager.default
        let tempFolderURL = URL(fileURLWithPath: tempFolder, isDirectory: true)
        var wavFileName = projectName + ".wav"
        var wavFilePath = tempFolderURL.appendingPathComponent(wavFileName).path

        if fileManager.fileExists(atPath: wavFilePath) {
            var counter = 1
            while fileManager.fileExists(atPath: wavFilePath) {
                wavFileName = "\(projectName)_\(counter).wav"
                wavFilePath = tempFolderURL.appendingPathComponent(wavFileName).path
                counter += 1
            }
        }

        return wavFilePath
    }

    // MARK: - Split WAV File
    /// Split a WAV file into segments for processing
    /// - Parameters:
    ///   - inputFilePath: Path to the input WAV file
    ///   - segmentDuration: Duration of each segment in seconds (default: 600 = 10 minutes)
    /// - Returns: Array of paths to the split WAV files
    func splitWav(
        inputFilePath: String,
        segmentDuration: Double = 600,
        processUpdate: ProcessUpdate? = nil,
        isCancelled: () -> Bool = { false }
    ) -> [String] {
        var result: [String] = []

        let fileURL = URL(fileURLWithPath: inputFilePath)
        guard let asset = try? AVAudioPlayer(contentsOf: fileURL),
              asset.duration > 0 else {
            return [inputFilePath]
        }

        let duration: TimeInterval = asset.duration

        // If duration is less than segment duration, return original file
        if duration < segmentDuration {
            return [inputFilePath]
        }

        let numberOfSegments = Int(ceil(duration / segmentDuration) - 1)
        let outputPrefix = "\(inputFilePath)_p"

        guard let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) else {
            return [inputFilePath]
        }

        for i in 0...numberOfSegments {
            if isCancelled() {
                break
            }

            let outputFilePath = "\(outputPrefix)\(i).wav"

            let task = Process()
            task.executableURL = URL(fileURLWithPath: ffmpegPath)
            task.arguments = [
                "-hide_banner",
                "-nostdin",
                "-y",
                "-loglevel", "error",
                "-i", inputFilePath,
                "-ss", String(i * Int(segmentDuration)),
                "-t", String(Int(segmentDuration)),
                "-c", "copy",
                outputFilePath
            ]
            task.standardError = Pipe()
            task.standardOutput = Pipe()

            do {
                try task.run()
            } catch {
                return []
            }

            processUpdate?(task)
            task.waitUntilExit()
            processUpdate?(nil)

            if isCancelled() {
                break
            }

            guard task.terminationStatus == 0 && isNonEmptyFile(atPath: outputFilePath) else {
                return []
            }

            result.append(outputFilePath)
        }

        return result
    }

    private func isNonEmptyFile(atPath path: String) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return false
        }
        return size > 0
    }

    private static func lastMeaningfulLines(from output: String, limit: Int = 3) -> String {
        output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .suffix(limit)
            .joined(separator: " ")
    }
}
