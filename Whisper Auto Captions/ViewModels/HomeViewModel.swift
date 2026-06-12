import Foundation
import AVFoundation

// MARK: - Home ViewModel
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var fileURL: URL?
    @Published var fileName: String = ""
    @Published var projectName: String = ""
    @Published var isSelected: Bool = false
    @Published var selectedFrameRate: FrameRate = .fps30 {
        didSet { saveFrameRateSettings() }
    }
    @Published var customFps: String = "30" {
        didSet { saveFrameRateSettings() }
    }
    @Published var selectedResolution: VideoResolution = .fullHD1080p {
        didSet { saveResolutionSettings() }
    }
    @Published var customWidth: String = "1920" {
        didSet { saveResolutionSettings() }
    }
    @Published var customHeight: String = "1080" {
        didSet { saveResolutionSettings() }
    }
    @Published var selectedLanguage = "Auto" {
        didSet { saveLanguageSetting() }
    }
    @Published var selectedModel = "Medium" {
        didSet { saveModelSetting() }
    }
    @Published var showSettings = false

    // Processing state
    enum TranscriptionState: Equatable {
        case idle
        case running
        case succeeded
        case cancelled
        case failed(String)
    }

    @Published var startCreatingAutoCaptions = false
    @Published var progress = 0.0
    @Published var progressPercentage = 0
    @Published var totalBatch: Int?
    @Published var currentBatch: Int?
    @Published var remainingTime = "00:00"
    @Published var status = "Splitting audio file..."
    @Published var outputCaptions = ""
    @Published var outputSRTFilePath = ""
    @Published var outputFCPXMLFilePath = ""
    @Published var processingState: TranscriptionState = .idle
    
    // MARK: - Private Properties
    private var isInitializing = true  // Prevents saving during init
    private let minimumValidModelSize: Int64 = 50 * 1024 * 1024
    private let transcriptionControlQueue = DispatchQueue(label: "WhisperAutoCaptions.HomeViewModel.transcription")
    private var activeExternalProcess: Process?
    private var cancellationRequested = false
    private let modelDownloadManager = ModelDownloadManager.shared
    @Published private var pendingStartDownloadTargetIDs: Set<String> = []

    // MARK: - Initialization
    init() {
        let settings = SettingsManager.shared.settings

        // Restore FPS settings
        if let frameRate = FrameRate(rawValue: settings.selectedFrameRate) {
            self.selectedFrameRate = frameRate
        }
        self.customFps = settings.customFps

        let converterSettings = SettingsManager.shared.srtConverterSettings
        if let resolution = VideoResolution(rawValue: converterSettings.selectedResolution) {
            self.selectedResolution = resolution
        }
        self.customWidth = converterSettings.customWidth
        self.customHeight = converterSettings.customHeight

        // Restore language and model
        self.selectedLanguage = settings.language
        self.selectedModel = settings.model

        // Mark initialization complete
        isInitializing = false
        reconcileSelectedModelWithAvailableModels()
    }

    // MARK: - Settings Persistence
    private func saveFrameRateSettings() {
        guard !isInitializing else { return }
        SettingsManager.shared.settings.selectedFrameRate = selectedFrameRate.rawValue
        SettingsManager.shared.settings.customFps = customFps
    }

    private func saveResolutionSettings() {
        guard !isInitializing else { return }
        var converterSettings = SettingsManager.shared.srtConverterSettings
        converterSettings.selectedResolution = selectedResolution.rawValue
        converterSettings.customWidth = customWidth
        converterSettings.customHeight = customHeight
        SettingsManager.shared.srtConverterSettings = converterSettings
    }

    private func saveLanguageSetting() {
        guard !isInitializing else { return }
        SettingsManager.shared.settings.language = selectedLanguage
    }

    private func saveModelSetting() {
        guard !isInitializing else { return }
        SettingsManager.shared.settings.model = selectedModel
    }

    // MARK: - Data
    let languages = LanguageData.languages
    let models = ModelData.models
    let modelsMapping = ModelData.modelToFileName

    // MARK: - Custom Models
    private let customModelManager = CustomModelManager.shared

    /// All available custom models
    var customModels: [CustomModel] {
        customModelManager.customModels
    }

    /// Check if the selected model is a custom model
    var isCustomModelSelected: Bool {
        customModelManager.isCustomModel(selectedModel)
    }

    /// Get the path for the currently selected model
    func getSelectedModelPath() -> URL? {
        // Check if it's a custom model first
        if let customModel = customModelManager.findModel(byName: selectedModel) {
            return try? customModelManager.getCustomModelPath(for: customModel)
        }

        // Fall back to built-in model
        guard let modelFileName = modelsMapping[selectedModel] else { return nil }
        return try? AppDirectoryUtility.getModelPath(for: modelFileName)
    }
    
    // MARK: - Computed Properties
    var currentFps: Float {
        if selectedFrameRate == .custom {
            return Float(customFps) ?? 30.0
        }
        return selectedFrameRate.value
    }

    var currentWidth: Int {
        if selectedResolution == .custom {
            return Int(customWidth) ?? 0
        }
        return selectedResolution.width
    }

    var currentHeight: Int {
        if selectedResolution == .custom {
            return Int(customHeight) ?? 0
        }
        return selectedResolution.height
    }

    var isFpsValid: Bool {
        return FrameRate.isValidFrameRate(currentFps)
    }

    var isResolutionValid: Bool {
        let validation = VideoResolution.isValidResolution(width: currentWidth, height: currentHeight)
        return validation.valid
    }

    var resolutionWarning: String? {
        if selectedResolution == .custom && (Int(customWidth) == nil || Int(customHeight) == nil) {
            return String(localized: "Resolution must be numeric.", comment: "Non-numeric resolution warning")
        }

        let validation = VideoResolution.isValidResolution(width: currentWidth, height: currentHeight)
        return validation.message
    }

    var isProcessingComplete: Bool {
        if case .succeeded = processingState { return true }
        return false
    }

    var isProcessingRunning: Bool {
        if case .running = processingState { return true }
        return false
    }

    var isProcessingFinished: Bool {
        return !isProcessingRunning
    }

    var canStartTranscription: Bool {
        return fileURL != nil
            && isFpsValid
            && isResolutionValid
            && isSelectedModelAvailable
            && !SettingsManager.shared.settings.noTimestamps
    }

    var transcriptionBlockReason: String? {
        if fileURL == nil {
            return nil
        }
        if !isFpsValid {
            return String(localized: "Frame rate must be between 0 and 120.", comment: "Invalid frame rate transcription warning")
        }
        if !isResolutionValid {
            return resolutionWarning ?? String(localized: "Resolution must be between 640 and 8192.", comment: "Invalid resolution transcription warning")
        }
        if SettingsManager.shared.settings.noTimestamps {
            return String(localized: "Disable Timestamps must be turned off to create SRT and FCPXML captions.", comment: "No timestamps transcription warning")
        }
        if !isSelectedModelAvailable {
            return String(localized: "The selected model is no longer available. Choose another model.", comment: "Unavailable selected model transcription warning")
        }
        return nil
    }

    var isSelectedModelAvailable: Bool {
        isModelAvailable(selectedModel)
    }

    var canDownloadSelectedModel: Bool {
        guard let targetID = selectedModelDownloadTargetID,
              !modelDownloadManager.isActiveOrQueued(targetID),
              let modelPath = getSelectedModelPath() else {
            return false
        }

        if let customModel = customModelManager.findModel(byName: selectedModel) {
            guard customModel.source.isURL else { return false }
        }

        return !isValidModelFile(at: modelPath)
    }

    var isSelectedModelDownloading: Bool {
        guard let targetID = selectedModelDownloadTargetID else { return false }
        return modelDownloadManager.currentTargetID == targetID
    }

    var isSelectedModelQueued: Bool {
        guard let targetID = selectedModelDownloadTargetID else { return false }
        return modelDownloadManager.isQueued(targetID)
    }

    var isSelectedModelStartPending: Bool {
        guard let targetID = selectedModelDownloadTargetID else { return false }
        return pendingStartDownloadTargetIDs.contains(targetID) && modelDownloadManager.isActiveOrQueued(targetID)
    }

    var hasStartPendingDownload: Bool {
        return pendingStartDownloadTargetIDs.contains { targetID in
            modelDownloadManager.isActiveOrQueued(targetID)
        }
    }

    func reconcileSelectedModelWithAvailableModels() {
        guard !isModelAvailable(selectedModel) else { return }
        selectedModel = ModelData.models.contains("Medium") ? "Medium" : ModelData.models[0]
    }

    private func isModelAvailable(_ model: String) -> Bool {
        modelsMapping[model] != nil || customModelManager.findModel(byName: model) != nil
    }

    private var hasCancellationRequest: Bool {
        transcriptionControlQueue.sync {
            cancellationRequested
        }
    }

    private func beginTranscriptionRun() {
        transcriptionControlQueue.sync {
            cancellationRequested = false
            activeExternalProcess = nil
        }
    }

    private func setActiveExternalProcess(_ process: Process?) {
        let shouldTerminate = transcriptionControlQueue.sync {
            activeExternalProcess = process
            return cancellationRequested && process != nil
        }

        if shouldTerminate {
            process?.terminate()
        }
    }

    func cancelTranscription() {
        let process = transcriptionControlQueue.sync { () -> Process? in
            cancellationRequested = true
            return activeExternalProcess
        }

        process?.terminate()
        status = String(localized: "Cancelling...", comment: "Transcription cancellation in progress status")
    }

    private func finishCancelledTranscription() {
        setActiveExternalProcess(nil)
        let update = {
            self.progress = 0.0
            self.progressPercentage = 0
            self.remainingTime = "00:00"
            self.status = String(localized: "Cancelled", comment: "Transcription cancelled status")
            self.processingState = .cancelled
        }

        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.async(execute: update)
        }
    }
    
    // MARK: - File Selection
    func selectFile(url: URL) {
        self.fileURL = url
        self.fileName = url.lastPathComponent
        self.projectName = (url.lastPathComponent as NSString).deletingPathExtension

        // Extract frame rate from video files
        if VideoService.shared.isVideoFile(url: url) {
            Task {
                await extractAndSetFrameRate(from: url)
            }
        }
    }

    /// Extract frame rate from video and update settings
    @MainActor
    private func extractAndSetFrameRate(from url: URL) async {
        guard let fps = await VideoService.shared.extractFrameRate(from: url) else {
            return
        }

        if let matchedFrameRate = FrameRate.fromValue(fps) {
            selectedFrameRate = matchedFrameRate
        } else if FrameRate.isValidFrameRate(fps) {
            selectedFrameRate = .custom
            customFps = String(format: "%.3f", fps)
        }
    }
    
    // MARK: - Model Download
    func downloadSelectedModel() {
        if let customModel = customModelManager.findModel(byName: selectedModel) {
            queueCustomModelDownload(customModel, startsTranscriptionAfterDownload: false)
            return
        }

        guard let modelFileName = modelsMapping[selectedModel] else { return }
        queueBuiltInModelDownload(
            fileName: modelFileName,
            displayName: selectedModel,
            startsTranscriptionAfterDownload: false
        )
    }

    private func queueBuiltInModelDownload(
        fileName: String,
        displayName: String,
        startsTranscriptionAfterDownload: Bool
    ) {
        guard let url = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-\(fileName.lowercased()).bin") else {
            modelDownloadManager.errorMessage = String(localized: "The built-in model download URL is invalid.", comment: "Invalid built-in model URL error")
            return
        }

        let target = ModelDownloadTarget(
            id: builtInDownloadTargetID(for: fileName),
            displayName: displayName,
            fileName: fileName,
            url: url
        )

        if startsTranscriptionAfterDownload {
            pendingStartDownloadTargetIDs.insert(target.id)
        }

        modelDownloadManager.download(target: target) { [weak self] success, _ in
            DispatchQueue.main.async {
                if startsTranscriptionAfterDownload {
                    self?.pendingStartDownloadTargetIDs.remove(target.id)
                }

                guard success, startsTranscriptionAfterDownload else { return }
                guard self?.selectedModel == displayName else { return }
                self?.startTranscription()
            }
        }
    }
    
    func cancelDownload() {
        modelDownloadManager.cancelDownload()
    }

    func cancelSelectedQueuedDownload() {
        guard let targetID = selectedModelDownloadTargetID else { return }
        modelDownloadManager.cancelQueuedDownload(targetID: targetID)
    }

    func cancelAllModelDownloads() {
        modelDownloadManager.cancelAllDownloads()
    }
    
    // MARK: - Main Processing
    func startTranscription() {
        guard let fileURL = fileURL else { return }
        guard let modelPath = getSelectedModelPath() else {
            status = "Error: Model file not found"
            processingState = .failed(status)
            return
        }

        beginTranscriptionRun()
        self.startCreatingAutoCaptions = true
        self.processingState = .running
        self.outputCaptions = ""
        let settings = SettingsManager.shared.settings
        let filePathString = fileURL.path
        let tempFolder = NSTemporaryDirectory()
        let projectName = self.projectName
        let fps = self.currentFps
        let outputWidth = self.currentWidth
        let outputHeight = self.currentHeight
        let titleStyle = SettingsManager.shared.titleStyleSettings
        let language = self.selectedLanguage
        self.totalBatch = nil
        self.status = String(localized: "Preparing audio...", comment: "Preparing audio status")
        self.currentBatch = nil
        self.progress = 0.0
        self.progressPercentage = 0
        self.remainingTime = "00:00"
        self.outputSRTFilePath = ""
        self.outputFCPXMLFilePath = ""

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            // Prepare audio for whisper.cpp (converts to 16kHz WAV if needed)
            let audioPreparationResult = FileUtility.withSecurityScopedAccess(to: fileURL) {
                AudioService.shared.prepareAudioForWhisper(
                    inputPath: filePathString,
                    projectName: projectName,
                    tempFolder: tempFolder,
                    processUpdate: { [weak self] process in
                        self?.setActiveExternalProcess(process)
                    }
                )
            }

            let outputWavFilePath: String
            switch audioPreparationResult {
            case .success(let wavFilePath):
                outputWavFilePath = wavFilePath
            case .failure(let error):
                DispatchQueue.main.async {
                    self.failTranscription("Error: \(error.userMessage)")
                }
                return
            }

            if self.hasCancellationRequest {
                self.finishCancelledTranscription()
                return
            }

            guard FileManager.default.fileExists(atPath: outputWavFilePath) else {
                DispatchQueue.main.async {
                    self.status = "Error: Failed to prepare audio"
                    self.processingState = .failed(self.status)
                }
                return
            }

            let segmentDuration = Double(settings.audioSegmentDuration)
            let validSegmentDuration = segmentDuration > 0 ? segmentDuration : 600.0
            let splitWavFilePaths = AudioService.shared.splitWav(
                inputFilePath: outputWavFilePath,
                segmentDuration: validSegmentDuration,
                processUpdate: { [weak self] process in
                    self?.setActiveExternalProcess(process)
                },
                isCancelled: { [weak self] in
                    self?.hasCancellationRequest ?? true
                }
            )

            if self.hasCancellationRequest {
                self.finishCancelledTranscription()
                return
            }

            guard !splitWavFilePaths.isEmpty else {
                DispatchQueue.main.async {
                    self.failTranscription("Error: Failed to split audio into processable segments")
                }
                return
            }

            DispatchQueue.main.async {
                self.totalBatch = splitWavFilePaths.count
                self.status = "Generating AI subtitles"
                self.currentBatch = 0
                self.transcribeSegments(
                    wavPaths: splitWavFilePaths,
                    nextIndex: 0,
                    srtFiles: [],
                    modelPath: modelPath.path,
                    settings: settings,
                    selectedLanguage: language,
                    segmentDurationSeconds: validSegmentDuration,
                    fps: fps,
                    outputWidth: outputWidth,
                    outputHeight: outputHeight,
                    titleStyle: titleStyle,
                    projectName: projectName
                )
            }
        }
    }

    private func transcribeSegments(
        wavPaths: [String],
        nextIndex: Int,
        srtFiles: [String],
        modelPath: String,
        settings: WhisperSettings,
        selectedLanguage: String,
        segmentDurationSeconds: TimeInterval,
        fps: Float,
        outputWidth: Int,
        outputHeight: Int,
        titleStyle: TitleStyleSettings,
        projectName: String
    ) {
        if hasCancellationRequest {
            finishCancelledTranscription()
            return
        }

        guard nextIndex < wavPaths.count else {
            finishTranscription(
                srtFiles: srtFiles,
                segmentDurationSeconds: segmentDurationSeconds,
                fps: fps,
                outputWidth: outputWidth,
                outputHeight: outputHeight,
                titleStyle: titleStyle,
                projectName: projectName
            )
            return
        }

        currentBatch = nextIndex + 1
        transcribeSegment(
            wavPath: wavPaths[nextIndex],
            modelPath: modelPath,
            settings: settings,
            selectedLanguage: selectedLanguage
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if self.hasCancellationRequest {
                    self.finishCancelledTranscription()
                    return
                }

                guard case .success(let srtFilePath) = result else {
                    if case .failure(let error) = result {
                        self.failTranscription("Error: Batch \(nextIndex + 1) failed. \(error.userMessage)")
                    } else {
                        self.failTranscription("Error: Failed to generate subtitles for batch \(nextIndex + 1)")
                    }
                    return
                }

                var nextSRTFiles = srtFiles
                nextSRTFiles.append(srtFilePath)
                self.progress = 0.0
                self.progressPercentage = 0
                self.transcribeSegments(
                    wavPaths: wavPaths,
                    nextIndex: nextIndex + 1,
                    srtFiles: nextSRTFiles,
                    modelPath: modelPath,
                    settings: settings,
                    selectedLanguage: selectedLanguage,
                    segmentDurationSeconds: segmentDurationSeconds,
                    fps: fps,
                    outputWidth: outputWidth,
                    outputHeight: outputHeight,
                    titleStyle: titleStyle,
                    projectName: projectName
                )
            }
        }
    }

    private func finishTranscription(
        srtFiles: [String],
        segmentDurationSeconds: TimeInterval,
        fps: Float,
        outputWidth: Int,
        outputHeight: Int,
        titleStyle: TitleStyleSettings,
        projectName: String
    ) {
        progress = 1.0
        progressPercentage = 100
        remainingTime = "00:00"

        if hasCancellationRequest {
            finishCancelledTranscription()
            return
        }

        guard !srtFiles.isEmpty else {
            failTranscription("Error: No subtitles generated")
            return
        }

        // Use SRTService for merging
        let outputSRTFilePath = SRTService.shared.mergeSRT(
            srtFiles: srtFiles,
            segmentDurationSeconds: segmentDurationSeconds
        )

        guard SRTService.shared.isValidSRTFile(outputSRTFilePath) else {
            failTranscription("Error: Merged SRT is invalid")
            return
        }

        let outputFCPXMLFilePath = FCPXMLService.srtToFCPXML(
            srtPath: outputSRTFilePath,
            fps: fps,
            projectName: projectName,
            width: outputWidth,
            height: outputHeight,
            titleStyle: titleStyle
        )
        guard FCPXMLService.isValidFCPXMLFile(outputFCPXMLFilePath) else {
            failTranscription("Error: Failed to generate FCPXML")
            return
        }

        status = "Done"
        self.outputSRTFilePath = outputSRTFilePath
        self.outputFCPXMLFilePath = outputFCPXMLFilePath
        processingState = .succeeded
    }

    private func failTranscription(_ message: String) {
        setActiveExternalProcess(nil)
        status = message
        processingState = .failed(message)
    }

    // MARK: - Whisper CLI Execution
    private func transcribeSegment(
        wavPath: String,
        modelPath: String,
        settings: WhisperSettings,
        selectedLanguage: String,
        completion: @escaping (Result<String, WhisperService.TranscriptionError>) -> Void
    ) {
        WhisperService.shared.transcribe(
            settings: settings,
            modelPath: modelPath,
            selectedLanguage: selectedLanguage,
            outputWavFilePath: wavPath,
            processStarted: { [weak self] process in
                self?.setActiveExternalProcess(process)
            },
            progressCallback: { [weak self] percentage, progress, remainingTime in
                self?.progressPercentage = percentage
                self?.progress = progress
                self?.remainingTime = remainingTime
            },
            outputCallback: { [weak self] captions in
                self?.outputCaptions += captions
            },
            completion: { [weak self] result in
                self?.setActiveExternalProcess(nil)
                completion(result)
            }
        )
    }

    // MARK: - Reset
    func reset() {
        outputCaptions = ""
        progress = 0.0
        progressPercentage = 0
        remainingTime = "00:00"
        startCreatingAutoCaptions = false
        processingState = .idle
        outputSRTFilePath = ""
        outputFCPXMLFilePath = ""
        totalBatch = nil
        currentBatch = nil
        status = "Splitting audio file..."
    }
    
    // MARK: - Model Validation
    func validateAndStartTranscription() {
        guard canStartTranscription else {
            if let reason = transcriptionBlockReason {
                status = "Error: \(reason)"
                processingState = .failed(status)
            }
            return
        }

        try? AppDirectoryUtility.ensureDirectoryExists()

        // Handle custom models
        if let customModel = customModelManager.findModel(byName: selectedModel) {
            validateAndStartCustomModel(customModel)
            return
        }

        // Handle built-in models
        guard let modelFileName = modelsMapping[selectedModel],
              let modelPath = try? AppDirectoryUtility.getModelPath(for: modelFileName) else {
            modelDownloadManager.errorMessage = String(localized: "Could not prepare the selected model path. Choose another model or check app storage permissions.", comment: "Built-in model path error")
            return
        }

        let displayName = selectedModel
        startOrDownloadModel(at: modelPath) { [weak self] in
            self?.queueBuiltInModelDownload(
                fileName: modelFileName,
                displayName: displayName,
                startsTranscriptionAfterDownload: true
            )
        }
    }

    /// Validate and start transcription for a custom model
    private func validateAndStartCustomModel(_ model: CustomModel) {
        guard let modelPath = try? customModelManager.getCustomModelPath(for: model) else {
            modelDownloadManager.errorMessage = String(localized: "Could not prepare the custom model path. Re-import the model or choose another model.", comment: "Custom model path error")
            return
        }

        startOrDownloadModel(at: modelPath) { [weak self] in
            self?.queueCustomModelDownload(model, startsTranscriptionAfterDownload: true)
        }
    }

    private func startOrDownloadModel(at modelPath: URL, download: @escaping () -> Void) {
        if isValidModelFile(at: modelPath) {
            startTranscription()
            return
        }

        if FileManager.default.fileExists(atPath: modelPath.path) {
            try? FileManager.default.removeItem(at: modelPath)
        }

        download()
    }

    private func isValidModelFile(at modelPath: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: modelPath.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: modelPath.path),
              let size = attributes[.size] as? Int64 else {
            return false
        }
        return size >= minimumValidModelSize
    }

    private var selectedModelDownloadTargetID: String? {
        if let customModel = customModelManager.findModel(byName: selectedModel) {
            return customModel.id.uuidString
        }

        guard let modelFileName = modelsMapping[selectedModel] else { return nil }
        return builtInDownloadTargetID(for: modelFileName)
    }

    private func builtInDownloadTargetID(for fileName: String) -> String {
        return "built-in:\(fileName)"
    }

    /// Download a custom model and optionally start transcription when complete.
    private func queueCustomModelDownload(_ model: CustomModel, startsTranscriptionAfterDownload: Bool) {
        guard case .url = model.source else {
            // Local models should already be imported - can't download
            modelDownloadManager.errorMessage = String(localized: "The selected local model file is missing. Re-import the model or choose another model.", comment: "Missing local custom model error")
            return
        }

        let targetID = model.id.uuidString
        if startsTranscriptionAfterDownload {
            pendingStartDownloadTargetIDs.insert(targetID)
        }

        customModelManager.downloadModel(model) { [weak self] success, _ in
            DispatchQueue.main.async {
                if startsTranscriptionAfterDownload {
                    self?.pendingStartDownloadTargetIDs.remove(targetID)
                }

                guard success, startsTranscriptionAfterDownload else { return }
                guard self?.selectedModel == model.name else { return }
                self?.startTranscription()
            }
        }
    }
}
