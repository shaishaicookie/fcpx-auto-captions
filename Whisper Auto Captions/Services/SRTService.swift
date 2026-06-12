//
//  SRTService.swift
//  Whisper Auto Captions
//
//  Handles SRT file operations and FCPXML conversion
//

import Foundation

extension String {
    var normalizedSRTLineEndings: String {
        replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
}

/// Service for SRT file operations
class SRTService {
    // MARK: - Singleton
    static let shared = SRTService()
    private init() {}

    enum ValidationResult {
        case valid
        case missing
        case unreadable
        case empty
        case missingTimestamps
    }

    // MARK: - Validation
    /// Validate whether an SRT file exists and contains timestamped subtitle entries.
    func validateSRTFile(_ path: String) -> ValidationResult {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            return .missing
        }

        guard let attributes = try? fileManager.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return .unreadable
        }

        guard size > 0 else {
            return .empty
        }

        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return .unreadable
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .empty
        }

        guard content.contains("-->") else {
            return .missingTimestamps
        }

        return .valid
    }

    /// Check whether an SRT file exists and has at least one subtitle timestamp.
    func isValidSRTFile(_ path: String) -> Bool {
        validateSRTFile(path) == .valid
    }

    // MARK: - Merge SRT Files
    /// Merge multiple SRT files into one, adjusting timestamps
    func mergeSRT(srtFiles: [String], segmentDurationSeconds: TimeInterval = 600.0) -> String {
        guard !srtFiles.isEmpty else { return "" }

        let mergedSrtPath = srtFiles[0] + "_merged.srt"
        var mergedContents = ""
        var index = 1

        for (i, srtPath) in srtFiles.enumerated() {
            do {
                let srtContent = try String(contentsOfFile: srtPath, encoding: .utf8)
                let subtitles: [String] = srtContent
                    .normalizedSRTLineEndings
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: "\n\n")

                for subtitle in subtitles {
                    let subtitleItem = subtitle
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: "\n")

                    guard subtitleItem.count >= 3 else { continue }

                    let timeRange = subtitleItem[1].components(separatedBy: " --> ")
                    guard timeRange.count >= 2 else { continue }

                    let start = timeRange[0]
                    let end = timeRange[1]

                    let offsetSeconds = TimeInterval(i) * segmentDurationSeconds
                    let newStart = adjustSrtTime(srtTime: start, offsetSeconds: offsetSeconds)
                    let newEnd = adjustSrtTime(srtTime: end, offsetSeconds: offsetSeconds)

                    let newTimeRange = newStart + " --> " + newEnd
                    // 인덱스 2 이상의 모든 줄을 결합하고 앞뒤 공백 제거
                    let subtitleContent = subtitleItem.dropFirst(2)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    mergedContents += "\(index)\n"
                    mergedContents += "\(newTimeRange)\n"
                    mergedContents += "\(subtitleContent)\n\n"
                    index += 1
                }
            } catch {
                continue
            }
        }

        do {
            try mergedContents.write(toFile: mergedSrtPath, atomically: true, encoding: .utf8)
        } catch {
            // Handle error silently
        }

        return mergedSrtPath
    }

    // MARK: - Adjust SRT Time
    /// Adjust SRT timestamp by adding a fixed offset in seconds
    func adjustSrtTime(srtTime: String, offsetSeconds: TimeInterval) -> String {
        let normalizedSrtTime = srtTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let timeComponents = normalizedSrtTime.components(separatedBy: ":")
        guard timeComponents.count >= 3 else { return srtTime }

        let hours = Int(timeComponents[0]) ?? 0
        let minutes = Int(timeComponents[1]) ?? 0
        let secondsAndMilliseconds = timeComponents[2].components(separatedBy: ",")
        let seconds = Int(secondsAndMilliseconds[0]) ?? 0

        let milliseconds = Int(secondsAndMilliseconds.count > 1 ? secondsAndMilliseconds[1] : "000") ?? 0
        let totalMilliseconds = ((hours * 3600) + (minutes * 60) + seconds) * 1000 + milliseconds
        let adjustedMilliseconds = totalMilliseconds + Int(round(offsetSeconds * 1000))
        let newTotalSeconds = max(0, adjustedMilliseconds / 1000)
        let newMilliseconds = adjustedMilliseconds % 1000

        let newHours = newTotalSeconds / 3600
        let newMinutes = (newTotalSeconds % 3600) / 60
        let newSeconds = newTotalSeconds % 60

        return String(format: "%02d:%02d:%02d,%03d", newHours, newMinutes, newSeconds, newMilliseconds)
    }

}
