//
//  WhisperService.swift
//  Whisper Auto Captions
//
//  Handles whisper.cpp execution and argument building
//

import Foundation

/// Service for running whisper.cpp transcription
class WhisperService {
    // MARK: - Singleton
    static let shared = WhisperService()
    private init() {}

    // MARK: - Progress Callback Types
    typealias ProgressCallback = (Int, Double, String) -> Void  // (percentage, progress, remainingTime)
    typealias OutputCallback = (String) -> Void
    typealias CompletionCallback = (Result<String, TranscriptionError>) -> Void  // srtFilePath

    enum TranscriptionError: Error {
        case whisperCliNotFound
        case whisperLaunchFailed(String)
        case whisperProcessFailed(status: Int32, details: String)
        case srtMissing(details: String)
        case srtUnreadable(details: String)
        case srtEmpty(details: String)
        case srtMissingTimestamps(details: String)

        var userMessage: String {
            switch self {
            case .whisperCliNotFound:
                return String(localized: "whisper-cli was not found in the app bundle.", comment: "Missing whisper-cli error")
            case .whisperLaunchFailed(let details):
                return String(localized: "Failed to start whisper-cli. \(details)", comment: "whisper-cli launch failure")
            case .whisperProcessFailed(_, let details):
                let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedDetails.isEmpty {
                    return String(localized: "whisper-cli exited with an error.", comment: "whisper-cli process failure without details")
                }
                return String(localized: "whisper-cli exited with an error. \(trimmedDetails)", comment: "whisper-cli process failure with details")
            case .srtMissing(let details):
                return Self.srtFailureMessage(
                    fallback: String(localized: "No subtitle file was created. The audio may contain no detectable speech, or whisper-cli may not have produced SRT output.", comment: "Missing SRT output error"),
                    details: details
                )
            case .srtUnreadable(let details):
                return Self.srtFailureMessage(
                    fallback: String(localized: "The subtitle file was created, but it could not be read.", comment: "Unreadable SRT output error"),
                    details: details
                )
            case .srtEmpty(let details):
                return Self.srtFailureMessage(
                    fallback: String(localized: "The subtitle file was empty. The audio may contain no detectable speech.", comment: "Empty SRT output error"),
                    details: details
                )
            case .srtMissingTimestamps(let details):
                return Self.srtFailureMessage(
                    fallback: String(localized: "The subtitle file did not contain timestamped subtitles.", comment: "SRT missing timestamps error"),
                    details: details
                )
            }
        }

        private static func srtFailureMessage(fallback: String, details: String) -> String {
            let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedDetails.isEmpty else { return fallback }
            return "\(fallback) \(trimmedDetails)"
        }
    }

    // MARK: - Build Arguments
    /// Build command line arguments for whisper.cpp based on settings
    func buildArguments(
        settings: WhisperSettings,
        modelPath: String,
        inputPath: String,
        language: String,
        forceNoGPU: Bool = false
    ) -> [String] {
        var args = ["-m", modelPath]
        let bestOf = WhisperSettings.clampedDecoderCount(settings.bestOf)
        let beamSize = WhisperSettings.clampedDecoderCount(settings.beamSize)

        // Language
        if let langCode = LanguageData.code(for: language) {
            args += ["-l", langCode]
        }

        // Standard output options
        args += ["-pp", "-osrt", "-f", inputPath]

        // Quality settings (only add if different from defaults)
        if bestOf != 5 {
            args += ["--best-of", "\(bestOf)"]
        }
        if beamSize != 5 {
            args += ["--beam-size", "\(beamSize)"]
        }
        if settings.temperature != 0.0 {
            args += ["--temperature", "\(settings.temperature)"]
        }
        if settings.entropyThreshold != 2.4 {
            args += ["--entropy-thold", "\(settings.entropyThreshold)"]
        }
        if settings.logProbThreshold != -1.0 {
            args += ["--logprob-thold", "\(settings.logProbThreshold)"]
        }

        // Performance settings
        if settings.threads != 4 {
            args += ["-t", "\(settings.threads)"]
        }
        if settings.processors != 1 {
            args += ["-p", "\(settings.processors)"]
        }
        if settings.noGPU || forceNoGPU {
            args += ["--no-gpu"]
        }
        if settings.flashAttention {
            args += ["--flash-attn"]
        } else {
            args += ["--no-flash-attn"]
        }

        // Output settings
        if settings.maxLen > 0 {
            args += ["--max-len", "\(settings.maxLen)"]
        }
        if settings.splitOnWord {
            args += ["--split-on-word"]
        }
        if settings.noTimestamps {
            args += ["--no-timestamps"]
        }
        if settings.translate {
            args += ["--translate"]
        }

        // Advanced settings
        let effectivePrompt = settings.prompt.isEmpty ? LanguageData.defaultPrompt(for: language) : settings.prompt
        if !effectivePrompt.isEmpty {
            args += ["--prompt", effectivePrompt]
        }

        if settings.noSpeechThreshold != 0.6 {
            args += ["--no-speech-thold", "\(settings.noSpeechThreshold)"]
        }
        if settings.wordThreshold != 0.01 {
            args += ["--word-thold", "\(settings.wordThreshold)"]
        }
        if settings.diarize {
            args += ["--diarize"]
        }
        if settings.tinyDiarize {
            args += ["--tinydiarize"]
        }

        return args
    }

    // MARK: - Run Transcription
    /// Run whisper.cpp transcription on a WAV file
    func transcribe(
        settings: WhisperSettings,
        modelPath: String,
        selectedLanguage: String,
        outputWavFilePath: String,
        processStarted: ((Process) -> Void)? = nil,
        progressCallback: @escaping ProgressCallback,
        outputCallback: @escaping OutputCallback,
        completion: @escaping CompletionCallback
    ) {
        guard let whisperCliPath = Bundle.main.path(forResource: "whisper-cli", ofType: nil) else {
            completion(.failure(.whisperCliNotFound))
            return
        }

        runTranscription(
            whisperCliPath: whisperCliPath,
            settings: settings,
            modelPath: modelPath,
            selectedLanguage: selectedLanguage,
            outputWavFilePath: outputWavFilePath,
            forceNoGPU: false,
            processStarted: processStarted,
            progressCallback: progressCallback,
            outputCallback: outputCallback,
            completion: completion
        )
    }

    private func runTranscription(
        whisperCliPath: String,
        settings: WhisperSettings,
        modelPath: String,
        selectedLanguage: String,
        outputWavFilePath: String,
        forceNoGPU: Bool,
        processStarted: ((Process) -> Void)?,
        progressCallback: @escaping ProgressCallback,
        outputCallback: @escaping OutputCallback,
        completion: @escaping CompletionCallback
    ) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: whisperCliPath)
        let arguments = buildArguments(
            settings: settings,
            modelPath: modelPath,
            inputPath: outputWavFilePath,
            language: selectedLanguage,
            forceNoGPU: forceNoGPU
        )
        task.arguments = arguments
        Self.removeStaleSRT(for: outputWavFilePath)

        let errorPipe = Pipe()
        let outputPipe = Pipe()

        task.standardError = errorPipe
        task.standardOutput = outputPipe

        let startTime = Date()

        let errorHandle = errorPipe.fileHandleForReading
        let outputHandle = outputPipe.fileHandleForReading
        let errorOutputLock = NSLock()
        var errorOutput = ""
        let isCPUOnlyRun = settings.noGPU || forceNoGPU
        let attemptDescription = forceNoGPU ? "cpu-retry" : (settings.noGPU ? "cpu" : "primary")

        Self.log(
            """
            Starting whisper-cli (\(attemptDescription)).
            Executable: \(whisperCliPath)
            Arguments: \(Self.debugCommand(arguments))
            Input: \(Self.debugFileDescription(outputWavFilePath))
            Model: \(Self.debugFileDescription(modelPath))
            """
        )

        errorHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let error = String(data: data, encoding: .utf8) {
                errorOutputLock.lock()
                errorOutput += error
                errorOutputLock.unlock()

                let lines = error.split(whereSeparator: \.isNewline)
                if let lastLine = lines.last, lastLine.hasPrefix("whisper_full_with_state: progress") {
                    if let progressString = lastLine.components(separatedBy: "=").last?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .dropLast() {
                        let progressPercentage = Int(progressString) ?? 0
                        let progress = Double(progressPercentage) * 0.01

                        let currentTime = Date()
                        let elapsed = currentTime.timeIntervalSince(startTime)
                        let remainingSeconds = progress > 0 ? round((1 - progress) / progress * elapsed) : 0
                        let remainingTime = FileUtility.formatSeconds(remainingSeconds)

                        DispatchQueue.main.async {
                            progressCallback(progressPercentage, progress, remainingTime)
                        }
                    }
                }
            }
        }

        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    outputCallback(output)
                }
            }
        }

        task.terminationHandler = { terminatedTask in
            errorHandle.readabilityHandler = nil
            outputHandle.readabilityHandler = nil
            _ = outputHandle.readDataToEndOfFile()
            let remainingErrorData = errorHandle.readDataToEndOfFile()
            if let remainingError = String(data: remainingErrorData, encoding: .utf8), !remainingError.isEmpty {
                errorOutputLock.lock()
                errorOutput += remainingError
                errorOutputLock.unlock()
            }

            errorOutputLock.lock()
            let fullErrorOutput = errorOutput
            let errorDetails = Self.lastMeaningfulLines(from: fullErrorOutput)
            errorOutputLock.unlock()
            let terminationDetails = Self.terminationDetails(for: terminatedTask)
            let stderrLog = terminatedTask.terminationStatus == 0 ? "" : "\nstderr:\n\(fullErrorOutput)"

            Self.log(
                """
                Finished whisper-cli (\(attemptDescription)).
                \(terminationDetails)
                SRT: \(Self.debugFileDescription(outputWavFilePath + ".srt"))\(stderrLog)
                """
            )

            if terminatedTask.terminationStatus == 0 {
                DispatchQueue.main.async {
                    progressCallback(100, 1.0, "00:00")
                }
            }

            let srtFilePath = outputWavFilePath + ".srt"
            guard terminatedTask.terminationStatus == 0 else {
                if !isCPUOnlyRun && Self.isLikelyGPUFailure(fullErrorOutput) {
                    Self.log("Retrying whisper-cli with --no-gpu after likely GPU failure.")
                    self.runTranscription(
                        whisperCliPath: whisperCliPath,
                        settings: settings,
                        modelPath: modelPath,
                        selectedLanguage: selectedLanguage,
                        outputWavFilePath: outputWavFilePath,
                        forceNoGPU: true,
                        processStarted: processStarted,
                        progressCallback: progressCallback,
                        outputCallback: outputCallback,
                        completion: completion
                    )
                    return
                }

                let debugLogPath = Self.writeFailureDebugLog(
                    attemptDescription: attemptDescription,
                    whisperCliPath: whisperCliPath,
                    arguments: arguments,
                    inputPath: outputWavFilePath,
                    modelPath: modelPath,
                    terminationDetails: terminationDetails,
                    stderr: fullErrorOutput
                )
                let combinedDetails = Self.combinedFailureDetails(
                    terminationDetails: terminationDetails,
                    errorDetails: errorDetails,
                    debugLogPath: debugLogPath
                )
                completion(.failure(.whisperProcessFailed(
                    status: terminatedTask.terminationStatus,
                    details: combinedDetails
                )))
                return
            }

            switch SRTService.shared.validateSRTFile(srtFilePath) {
            case .valid:
                completion(.success(srtFilePath))
            case .missing:
                completion(.failure(.srtMissing(details: errorDetails)))
            case .unreadable:
                completion(.failure(.srtUnreadable(details: errorDetails)))
            case .empty:
                completion(.failure(.srtEmpty(details: errorDetails)))
            case .missingTimestamps:
                completion(.failure(.srtMissingTimestamps(details: errorDetails)))
            }
        }

        do {
            try task.run()
        } catch {
            completion(.failure(.whisperLaunchFailed(error.localizedDescription)))
            return
        }

        processStarted?(task)
    }

    private static func removeStaleSRT(for inputPath: String) {
        let srtPath = inputPath + ".srt"
        guard FileManager.default.fileExists(atPath: srtPath) else { return }
        do {
            try FileManager.default.removeItem(atPath: srtPath)
        } catch {
            log("Failed to remove stale SRT at \(srtPath): \(error.localizedDescription)")
        }
    }

    private static func isLikelyGPUFailure(_ output: String) -> Bool {
        let lowercasedOutput = output.lowercased()
        return lowercasedOutput.contains("ggml_metal") ||
               lowercasedOutput.contains("failed to allocate buffer") ||
               lowercasedOutput.contains("whisper_backend_init_gpu: failed")
    }

    private static func terminationDetails(for process: Process) -> String {
        let reason: String
        switch process.terminationReason {
        case .exit:
            reason = "exit"
        case .uncaughtSignal:
            reason = "uncaughtSignal"
        @unknown default:
            reason = "unknown"
        }

        return "terminationStatus=\(process.terminationStatus), terminationReason=\(reason)"
    }

    private static func combinedFailureDetails(
        terminationDetails: String,
        errorDetails: String,
        debugLogPath: String?
    ) -> String {
        var parts = [terminationDetails]
        if !errorDetails.isEmpty {
            parts.append(errorDetails)
        }
        if let debugLogPath = debugLogPath {
            parts.append("Debug log: \(debugLogPath)")
        }
        return parts.joined(separator: " ")
    }

    private static func writeFailureDebugLog(
        attemptDescription: String,
        whisperCliPath: String,
        arguments: [String],
        inputPath: String,
        modelPath: String,
        terminationDetails: String,
        stderr: String
    ) -> String? {
        let logDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let inputName = URL(fileURLWithPath: inputPath).deletingPathExtension().lastPathComponent
        let logURL = logDirectory.appendingPathComponent("\(inputName)-whisper-\(attemptDescription)-failure.log")
        let contents = """
        Whisper Auto Captions whisper-cli failure

        \(terminationDetails)
        Executable: \(whisperCliPath)
        Arguments: \(debugCommand(arguments))
        Input: \(debugFileDescription(inputPath))
        Model: \(debugFileDescription(modelPath))

        stderr:
        \(stderr)
        """

        do {
            try contents.write(to: logURL, atomically: true, encoding: .utf8)
            log("Wrote whisper-cli failure debug log: \(logURL.path)")
            return logURL.path
        } catch {
            log("Failed to write whisper-cli failure debug log: \(error.localizedDescription)")
            return nil
        }
    }

    private static func debugCommand(_ arguments: [String]) -> String {
        arguments.map(debugQuote).joined(separator: " ")
    }

    private static func debugQuote(_ value: String) -> String {
        if value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil && !value.contains("'") {
            return value
        }
        return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func debugFileDescription(_ path: String) -> String {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            return "\(path) (missing)"
        }

        let attributes = try? fileManager.attributesOfItem(atPath: path)
        let size = attributes?[.size] as? NSNumber
        let sizeDescription = size.map { "\($0.int64Value) bytes" } ?? "unknown size"
        return "\(path) (\(sizeDescription))"
    }

    private static func log(_ message: String) {
        NSLog("[WhisperService] %@", message)
    }

    private static func lastMeaningfulLines(from output: String, limit: Int = 4) -> String {
        output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("whisper_full_with_state: progress") }
            .suffix(limit)
            .joined(separator: " ")
    }
}
