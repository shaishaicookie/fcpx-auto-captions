import Foundation
import AppKit

// MARK: - XMLElement Extension for Safe Attribute Handling
private extension XMLElement {
    /// Safely add an attribute to this element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    func addSafeAttribute(name: String, value: String) {
        if let attr = XMLNode.attribute(withName: name, stringValue: value) as? XMLNode {
            addAttribute(attr)
        }
    }
}

// MARK: - FCPXML Service
/// Service for converting SRT files to FCPXML format for Final Cut Pro
struct FCPXMLService {
    enum FinalCutOpenError: LocalizedError {
        case fileUnavailable
        case scriptUnavailable
        case scriptFailed(String)

        var errorDescription: String? {
            switch self {
            case .fileUnavailable:
                return String(localized: "The FCPXML file could not be found or is not readable.", comment: "FCPXML file unavailable error")
            case .scriptUnavailable:
                return String(localized: "Could not create the Final Cut Pro launch script.", comment: "AppleScript creation error")
            case .scriptFailed(let message):
                return String(localized: "Final Cut Pro could not open the file: \(message)", comment: "Final Cut Pro open failed error")
            }
        }
    }

    // MARK: - Time Conversion
    static func srtTimeToFrame(srtTime: String, fps: Float) -> Int {
        // Convert SRT time to milliseconds
        let normalizedSrtTime = srtTime.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedSrtTime.count >= 4 else { return 0 }

        let ms = Int(normalizedSrtTime.suffix(3)) ?? 0
        let timeComponents = normalizedSrtTime.prefix(normalizedSrtTime.count - 4).split(separator: ":")

        guard timeComponents.count >= 3,
              let hours = Int(timeComponents[0]),
              let minutes = Int(timeComponents[1]),
              let seconds = Int(timeComponents[2]) else {
            return 0
        }

        let srtTimeMs = (hours * 3600 + minutes * 60 + seconds) * 1000 + ms
        // Convert ms to frame
        let frame = Int(floor(Float(srtTimeMs) / (1000 / fps)))
        return frame
    }

    // MARK: - SRT to FCPXML Conversion
    static func srtToFCPXML(srtPath: String, fps: Float, projectName: String, width: Int = 1920, height: Int = 1080, titleStyle: TitleStyleSettings = .default) -> String {
        do {
            let srtContent = try String(contentsOfFile: srtPath, encoding: .utf8)
            let normalizedSrtContent = srtContent.normalizedSRTLineEndings

            // Validate SRT content is not empty
            let trimmedContent = normalizedSrtContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else {
                print("Error: SRT file is empty")
                return "Error: SRT file is empty"
            }

            let subtitles: [String] = trimmedContent.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            // Validate we have at least one subtitle
            guard !subtitles.isEmpty else {
                print("Error: No subtitles found in SRT file")
                return "Error: No subtitles found"
            }

            // Validate last subtitle format before accessing
            guard let lastSubtitle = subtitles.last else {
                print("Error: No subtitles found in SRT file")
                return "Error: No subtitles found"
            }

            let lastSubtitleLines = lastSubtitle.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
            guard lastSubtitleLines.count >= 2 else {
                print("Error: Invalid subtitle format - insufficient lines")
                return "Error: Invalid subtitle format"
            }

            let timeRangeComponents = lastSubtitleLines[1].components(separatedBy: " --> ")
            guard timeRangeComponents.count >= 2 else {
                print("Error: Invalid subtitle format - missing time range")
                return "Error: Invalid subtitle format"
            }

            // Extract total duration from srt
            let totalSrtTime = timeRangeComponents[1]
            let totalFrame = srtTimeToFrame(srtTime: totalSrtTime, fps: Float(fps))
            let hundredFoldTotalFrame = String(100 * totalFrame)
            let hundredFoldFps = String(Int(fps * 100))

            let resolvedTitleStyle = titleStyle.resolved(forWidth: width, height: height)

            // Build FCPXML structure
            let fcpxmlElement = XMLElement(name: "fcpxml")
            fcpxmlElement.addSafeAttribute(name: "version", value: "1.9")

            // Resources
            let resourcesElement = XMLElement(name: "resources")

            // Format - use dynamic resolution
            let formatName = VideoResolution.formatName(width: width, height: height, fps: fps)
            let formatElement = XMLElement(name: "format")
            formatElement.addSafeAttribute(name: "id", value: "r1")
            formatElement.addSafeAttribute(name: "name", value: formatName)
            formatElement.addSafeAttribute(name: "frameDuration", value: "100/\(hundredFoldFps)s")
            formatElement.addSafeAttribute(name: "width", value: String(width))
            formatElement.addSafeAttribute(name: "height", value: String(height))
            formatElement.addSafeAttribute(name: "colorSpace", value: "1-1-1 (Rec. 709)")
            resourcesElement.addChild(formatElement)

            // Effect
            let effectElement = XMLElement(name: "effect")
            effectElement.addSafeAttribute(name: "id", value: "r2")
            effectElement.addSafeAttribute(name: "name", value: "Basic Title")
            effectElement.addSafeAttribute(name: "uid", value: ".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti")
            resourcesElement.addChild(effectElement)

            // Library
            let libraryElement = XMLElement(name: "library")

            // Event
            let eventElement = XMLElement(name: "event")
            eventElement.addSafeAttribute(name: "name", value: "Whisper Auto Captions")
            libraryElement.addChild(eventElement)

            // Project
            let projectElement = XMLElement(name: "project")
            projectElement.addSafeAttribute(name: "name", value: "\(projectName)")
            eventElement.addChild(projectElement)

            // Sequence
            let sequenceElement = XMLElement(name: "sequence")
            sequenceElement.addSafeAttribute(name: "format", value: "r1")
            sequenceElement.addSafeAttribute(name: "tcStart", value: "0s")
            sequenceElement.addSafeAttribute(name: "tcFormat", value: "NDF")
            sequenceElement.addSafeAttribute(name: "audioLayout", value: "stereo")
            sequenceElement.addSafeAttribute(name: "audioRate", value: "48k")
            sequenceElement.addSafeAttribute(name: "duration", value: "\(hundredFoldTotalFrame)/\(hundredFoldFps)s")
            projectElement.addChild(sequenceElement)

            // Spine
            let spineElement = XMLElement(name: "spine")
            sequenceElement.addChild(spineElement)

            // Gap
            let gapElement = XMLElement(name: "gap")
            gapElement.addSafeAttribute(name: "name", value: "Gap")
            gapElement.addSafeAttribute(name: "offset", value: "0s")
            gapElement.addSafeAttribute(name: "duration", value: "\(hundredFoldTotalFrame)/\(hundredFoldFps)s")
            spineElement.addChild(gapElement)

            // Process each subtitle
            for (i, subtitle) in subtitles.enumerated() {
                let subtitleItem = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")

                // Skip malformed subtitles (need at least: index, time range, text)
                guard subtitleItem.count >= 3 else {
                    print("Warning: Skipping malformed subtitle at index \(i)")
                    continue
                }

                let timeRange = subtitleItem[1].components(separatedBy: " --> ")
                guard timeRange.count >= 2 else {
                    print("Warning: Skipping subtitle with invalid time range at index \(i)")
                    continue
                }

                let offset = timeRange[0]
                let end = timeRange[1]
                let offsetFrame = srtTimeToFrame(srtTime: offset, fps: fps)
                let endFrame = srtTimeToFrame(srtTime: end, fps: fps)
                let durationFrame = endFrame - offsetFrame

                let hundredFoldOffsetFrame = String(100 * offsetFrame)
                let hundredFoldDurationFrame = String(100 * durationFrame)
                // 인덱스 2 이상의 모든 줄을 결합하고 앞뒤 공백 제거
                let subtitleContent = subtitleItem.dropFirst(2)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Create title element based on style settings
                let titleElement = createTitleElement(
                    index: i,
                    subtitleContent: subtitleContent,
                    hundredFoldOffsetFrame: hundredFoldOffsetFrame,
                    hundredFoldDurationFrame: hundredFoldDurationFrame,
                    hundredFoldFps: hundredFoldFps,
                    titleStyle: resolvedTitleStyle
                )
                gapElement.addChild(titleElement)
            }

            // Add the resources and library elements to the fcpxml element
            fcpxmlElement.addChild(resourcesElement)
            fcpxmlElement.addChild(libraryElement)

            // Create the XML document with the fcpxml element as the root
            let xmlDoc = XMLDocument(rootElement: fcpxmlElement)

            // Set the XML document version and encoding
            xmlDoc.version = "1.0"
            xmlDoc.characterEncoding = "utf-8"

            // Write the XML document to the output file
            let xmlData = xmlDoc.xmlData(options: .nodePrettyPrint)
            let fileUrl = URL(fileURLWithPath: srtPath + ".fcpxml")
            try xmlData.write(to: fileUrl)
            return srtPath + ".fcpxml"
        } catch {
            print("Error converting SRT to FCPXML: \(error)")
            return "Error"
        }
    }

    static func isValidFCPXMLFile(_ path: String) -> Bool {
        let fileManager = FileManager.default
        guard !path.isEmpty,
              fileManager.fileExists(atPath: path),
              let attrs = try? fileManager.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64,
              size > 0 else {
            return false
        }

        let fcpxmlURL = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: fcpxmlURL),
              !data.isEmpty else {
            return false
        }

        do {
            let xml = try XMLDocument(data: data, options: .documentTidyXML)
            return xml.rootElement()?.name == "fcpxml"
        } catch {
            return false
        }
    }

    // MARK: - Private Helpers

    /// Create a title element for a subtitle
    private static func createTitleElement(
        index: Int,
        subtitleContent: String,
        hundredFoldOffsetFrame: String,
        hundredFoldDurationFrame: String,
        hundredFoldFps: String,
        titleStyle: TitleStyleSettings
    ) -> XMLElement {
        let titleElement = XMLElement(name: "title")
        titleElement.addSafeAttribute(name: "ref", value: "r2")
        titleElement.addSafeAttribute(name: "lane", value: "1")
        titleElement.addSafeAttribute(name: "offset", value: "\(hundredFoldOffsetFrame)/\(hundredFoldFps)s")
        titleElement.addSafeAttribute(name: "duration", value: "\(hundredFoldDurationFrame)/\(hundredFoldFps)s")
        titleElement.addSafeAttribute(name: "name", value: "\(subtitleContent) - Basic Title")

        // Position param - use style settings
        let param1Element = XMLElement(name: "param")
        param1Element.addSafeAttribute(name: "name", value: "Position")
        param1Element.addSafeAttribute(name: "key", value: "9999/999166631/999166633/1/100/101")
        param1Element.addSafeAttribute(name: "value", value: titleStyle.positionString)
        titleElement.addChild(param1Element)

        // Flatten param
        let param2Element = XMLElement(name: "param")
        param2Element.addSafeAttribute(name: "name", value: "Flatten")
        param2Element.addSafeAttribute(name: "key", value: "999/999166631/999166633/2/351")
        param2Element.addSafeAttribute(name: "value", value: "1")
        titleElement.addChild(param2Element)

        // Alignment param - use style settings
        let param3Element = XMLElement(name: "param")
        param3Element.addSafeAttribute(name: "name", value: "Alignment")
        param3Element.addSafeAttribute(name: "key", value: "9999/999166631/999166633/2/354/999169573/401")
        param3Element.addSafeAttribute(name: "value", value: titleStyle.alignment.fcpxmlParamValue)
        titleElement.addChild(param3Element)

        // Text element
        let textElement = XMLElement(name: "text")
        titleElement.addChild(textElement)

        // Text style
        let textStyleElement = XMLElement(name: "text-style")
        textStyleElement.addSafeAttribute(name: "ref", value: "ts\(String(index))")
        textStyleElement.stringValue = subtitleContent
        textElement.addChild(textStyleElement)

        // Text style def
        let textStyleDefElement = XMLElement(name: "text-style-def")
        textStyleDefElement.addSafeAttribute(name: "id", value: "ts\(String(index))")
        titleElement.addChild(textStyleDefElement)

        // Text style 2 (font settings) - use style settings
        let textStyle2Element = XMLElement(name: "text-style")

        // Font settings from style
        textStyle2Element.addSafeAttribute(name: "font", value: titleStyle.fontName)
        textStyle2Element.addSafeAttribute(name: "fontSize", value: String(Int(titleStyle.fontSize)))
        textStyle2Element.addSafeAttribute(name: "fontFace", value: titleStyle.fontWeight.rawValue)
        textStyle2Element.addSafeAttribute(name: "fontColor", value: titleStyle.textColor.toFCPXMLString())

        // Bold attribute for semibold or bold weight
        if titleStyle.fontWeight == .semibold || titleStyle.fontWeight == .bold {
            textStyle2Element.addSafeAttribute(name: "bold", value: "1")
        }

        // Stroke settings (only if enabled)
        if titleStyle.strokeEnabled && titleStyle.strokeWidth > 0 {
            textStyle2Element.addSafeAttribute(name: "strokeColor", value: titleStyle.strokeColor.toFCPXMLString())
            textStyle2Element.addSafeAttribute(name: "strokeWidth", value: String(Int(titleStyle.strokeWidth)))
        }

        // Shadow settings
        textStyle2Element.addSafeAttribute(name: "shadowColor", value: titleStyle.shadowColor.toFCPXMLString())
        textStyle2Element.addSafeAttribute(name: "shadowOffset", value: titleStyle.shadowOffsetString)

        // Alignment
        textStyle2Element.addSafeAttribute(name: "alignment", value: titleStyle.alignment.fcpxmlStyleValue)

        textStyleDefElement.addChild(textStyle2Element)

        return titleElement
    }

    // MARK: - Open in Final Cut Pro

    /// Opens an FCPXML file in Final Cut Pro using AppleScript
    /// - Parameter fcpxmlPath: The file path to the FCPXML file
    static func openInFinalCutPro(
        fcpxmlPath: String,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let fileManager = FileManager.default
        let fcpxmlURL = URL(fileURLWithPath: fcpxmlPath)
        guard !fcpxmlPath.isEmpty,
              fileManager.fileExists(atPath: fcpxmlURL.path),
              (try? fcpxmlURL.resourceValues(forKeys: [.isReadableKey]).isReadable) == true else {
            completeOnMain(.failure(FinalCutOpenError.fileUnavailable), completion: completion)
            return
        }

        let safePath = escapeAppleScriptPath(fcpxmlPath)

        let command =
        """
        tell application "Final Cut Pro"
            launch
            activate
            open POSIX file "\(safePath)"
        end tell
        """
        DispatchQueue.global(qos: .background).async {
            var error: NSDictionary?
            guard let scriptObject = NSAppleScript(source: command) else {
                completeOnMain(.failure(FinalCutOpenError.scriptUnavailable), completion: completion)
                return
            }

            _ = scriptObject.executeAndReturnError(&error)
            if let error {
                let message = error["NSAppleScriptErrorMessage"] as? String
                    ?? String(localized: "Unknown AppleScript error.", comment: "Unknown AppleScript error fallback")
                completeOnMain(.failure(FinalCutOpenError.scriptFailed(message)), completion: completion)
            } else {
                completeOnMain(.success(()), completion: completion)
            }
        }
    }

    private static func completeOnMain<T>(
        _ result: Result<T, Error>,
        completion: ((Result<T, Error>) -> Void)?
    ) {
        guard let completion else { return }

        DispatchQueue.main.async {
            completion(result)
        }
    }

    private static func escapeAppleScriptPath(_ path: String) -> String {
        return path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// MARK: - Legacy SRTConverter (for backward compatibility)
/// Alias for backward compatibility with existing code
typealias SRTConverter = FCPXMLService
