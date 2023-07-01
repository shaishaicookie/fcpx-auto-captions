import SwiftUI
import Foundation
import AVFoundation

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    var model: String
    var progressHandler: ((Double) -> Void)?
    var completionHandler: (() -> Void)?

    init(model: String, progressHandler: ((Double) -> Void)? = nil, completionHandler: (() -> Void)? = nil) {
        self.model = model
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handle downloaded file here
        let fileManager = FileManager.default
        let applicationSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let whisperAutoCaptionsURL = applicationSupportDirectory.appendingPathComponent("Whisper Auto Captions")
        let destinationURL = whisperAutoCaptionsURL.appendingPathComponent("ggml-\(model.lowercased()).bin")

        // Move the downloaded file to the destination URL
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            print("File downloaded and moved to: \(destinationURL.path)")
            completionHandler?()
        } catch {
            print("Error moving file: \(error)")
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler?(progress)
    }
}


struct ContentView: View {
    @State var startCreatingAutoCaptions = false
    @State var progress = 0.0
    @State var progressPercentage = 0
    @State var totalBatch = 100000
    @State var currentBatch = -100000
    @State var remainingTime = "00:00"
    @State var projectName = ""
    @State var outputCaptions = ""
    @State var outputSRTFilePath = ""
    @State var outputFCPXMLFilePath = ""
    var body: some View {
        if startCreatingAutoCaptions {
            ProcessView(progress: $progress, progressPercentage: $progressPercentage, totalBatch: $totalBatch, currentBatch: $currentBatch, remainingTime: $remainingTime, outputCaptions: $outputCaptions, projectName: $projectName, outputFCPXMLFilePath: $outputFCPXMLFilePath, outputSRTFilePath: $outputSRTFilePath,isPresented: $startCreatingAutoCaptions).frame(minWidth: 600, minHeight: 600)
        } else {
            HomeView(startCreatingAutoCaptions: $startCreatingAutoCaptions, progress: $progress, progressPercentage: $progressPercentage, totalBatch: $totalBatch, currentBatch: $currentBatch, remainingTime: $remainingTime, outputCaptions: $outputCaptions, projectName: $projectName, outputFCPXMLFilePath: $outputFCPXMLFilePath, outputSRTFilePath: $outputSRTFilePath).frame(minWidth: 600, minHeight: 600)
        }
    }
}



struct HomeView: View {
    @State var fileURL: URL?
    @State var isSelected: Bool = false
    @State private var fps: String = ""
    @State private var selectedLanguage = "Chinese"
    @State private var selectedModel = "Medium"
    let languages = ["Arabic", "Azerbaijani", "Armenian", "Albanian", "Afrikaans", "Amharic", "Assamese", "Bulgarian", "Bengali", "Breton", "Basque", "Bosnian", "Belarusian", "Bashkir", "Chinese", "Catalan", "Czech", "Croatian", "Dutch", "Danish", "English", "Estonian", "French", "Finnish", "Faroese", "German", "Greek", "Galician", "Georgian", "Gujarati", "Hindi", "Hebrew", "Hungarian", "Haitian creole", "Hawaiian", "Hausa", "Italian", "Indonesian", "Icelandic", "Japanese", "Javanese", "Korean", "Kannada", "Kazakh", "Khmer", "Lithuanian", "Latin", "Latvian", "Lao", "Luxembourgish", "Lingala", "Malay", "Maori", "Malayalam", "Macedonian", "Mongolian", "Marathi", "Maltese", "Myanmar", "Malagasy", "Norwegian", "Nepali", "Nynorsk", "Occitan", "Portuguese", "Polish", "Persian", "Punjabi", "Pashto", "Russian", "Romanian", "Spanish", "Swedish", "Slovak", "Serbian", "Slovenian", "Swahili", "Sinhala", "Shona", "Somali", "Sindhi", "Sanskrit", "Sundanese", "Turkish", "Tamil", "Thai", "Telugu", "Tajik", "Turkmen", "Tibetan", "Tagalog", "Tatar", "Ukrainian", "Urdu", "Uzbek", "Vietnamese", "Welsh", "Yoruba", "Yiddish"]
    let languagesMapping = ["Arabic": "ar", "Azerbaijani": "az", "Armenian": "hy", "Albanian": "sq", "Afrikaans": "af", "Amharic": "am", "Assamese": "as", "Bulgarian": "bg", "Bengali": "bn", "Breton": "br", "Basque": "eu", "Bosnian": "bs", "Belarusian": "be", "Bashkir": "ba", "Chinese": "zh", "Catalan": "ca", "Czech": "cs", "Croatian": "hr", "Dutch": "nl", "Danish": "da", "English": "en", "Estonian": "et", "French": "fr", "Finnish": "fi", "Faroese": "fo", "German": "de", "Greek": "el", "Galician": "gl", "Georgian": "ka", "Gujarati": "gu", "Hindi": "hi", "Hebrew": "he", "Hungarian": "hu", "Haitian creole": "ht", "Hawaiian": "haw", "Hausa": "ha", "Italian": "it", "Indonesian": "id", "Icelandic": "is", "Japanese": "ja", "Javanese": "jw", "Korean": "ko", "Kannada": "kn", "Kazakh": "kk", "Khmer": "km", "Lithuanian": "lt", "Latin": "la", "Latvian": "lv", "Lao": "lo", "Luxembourgish": "lb", "Lingala": "ln", "Malay": "ms", "Maori": "mi", "Malayalam": "ml", "Macedonian": "mk", "Mongolian": "mn", "Marathi": "mr", "Maltese": "mt", "Myanmar": "my", "Malagasy": "mg", "Norwegian": "no", "Nepali": "ne", "Nynorsk": "nn", "Occitan": "oc", "Portuguese": "pt", "Polish": "pl", "Persian": "fa", "Punjabi": "pa", "Pashto": "ps", "Russian": "ru", "Romanian": "ro", "Spanish": "es", "Swedish": "sv", "Slovak": "sk", "Serbian": "sr", "Slovenian": "sl", "Swahili": "sw", "Sinhala": "si", "Shona": "sn", "Somali": "so", "Sindhi": "sd", "Sanskrit": "sa", "Sundanese": "su", "Turkish": "tr", "Tamil": "ta", "Thai": "th", "Telugu": "te", "Tajik": "tg", "Turkmen": "tk", "Tibetan": "bo", "Tagalog": "tl", "Tatar": "tt", "Ukrainian": "uk", "Urdu": "ur", "Uzbek": "uz", "Vietnamese": "vi", "Welsh": "cy", "Yoruba": "yo", "Yiddish": "yi"]
    let models = ["Large", "Medium", "Small", "Base", "Tiny"]
    let modelsMapping = ["Large": "ggml-large", "Medium": "ggml-medium", "Small": "ggml-small", "Base":"ggml-base", "Tiny":"ggml-tiny"]

    
    @State var fileName: String = ""
    
    @Binding var startCreatingAutoCaptions: Bool
    @Binding var progress: Double
    @Binding var progressPercentage: Int
    @Binding var totalBatch: Int
    @Binding var currentBatch: Int
    @Binding var remainingTime: String
    @Binding var outputCaptions: String
    @Binding var projectName: String
    @Binding var outputFCPXMLFilePath: String
    @Binding var outputSRTFilePath: String


    
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @State private var showAlert = false
    
    
    
    var body: some View {
        VStack {
            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 20) {
                GridRow {
                        Text("Audio File:")
                        HStack {
                            Button(action: {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = true
                                panel.canChooseDirectories = true
                                panel.allowsMultipleSelection = false
                                panel.allowedContentTypes = [.mp3]
                                if panel.runModal() == .OK {
                                    self.fileURL = panel.urls.first
                                    if let fileName = panel.urls.first?.lastPathComponent {
                                        self.fileName = fileName
                                        self.projectName = fileName.replacingOccurrences(of: ".mp3", with: "")
                                    }
                                }
                            }) {
                                Text("Choose File")
                            }
        
                            if self.fileURL != nil {
                                Text(fileName)
                            }
                        }
                }
                
                GridRow {
                    Text("Frame Rate:")
                    TextField (
                        "eg: 30, 29.97",
                        text: $fps
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                }
                
                GridRow {
                    Text("Model:")
                    Picker(selection: $selectedModel, label: EmptyView()) {
                        ForEach(models, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                }
                
                GridRow {
                    Text("Language:")
                    Picker(selection: $selectedLanguage, label: EmptyView()) {
                        ForEach(languages, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                }
                
                GridRow {
                    Button(action: {
                        let fileManager = FileManager.default
                        let applicationSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                        let whisperAutoCaptionsURL = applicationSupportDirectory.appendingPathComponent("Whisper Auto Captions")
                        let destinationURL = whisperAutoCaptionsURL.appendingPathComponent("ggml-\(selectedModel.lowercased()).bin")
                        
                        if fileManager.fileExists(atPath: destinationURL.path) {
                            print("File exists")
                            whisper_auto_captions()
                        } else {
                            print("File does not exist")
                            download_model(model: selectedModel.lowercased()) { success in
                                if success {
                                    whisper_auto_captions()
                                } else {
                                    // Handle download failure
                                }
                            }
                        }
                    }, label: {
                        Text("Create")
                    }).buttonStyle(BorderedProminentButtonStyle())
                        .gridCellAnchor(.center)
                        .disabled(fileURL == nil || fps.isEmpty)
                }.gridCellColumns(2)
            }
            if isDownloading {
                ProgressView(value: downloadProgress)
                    .padding()
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
            }
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("Downloading \(selectedModel)"),
                message: Text(String(format: "Download progress: %.0f%%", downloadProgress * 100)),
                primaryButton: .destructive(Text("Cancel"), action: {
                    // Cancel the download task
                    self.isDownloading = false
                    self.showAlert = false
                }),
                secondaryButton: .default(Text(""), action: {})
            )
        }
    }
    
    
    func whisper_auto_captions() {
        self.startCreatingAutoCaptions = true
        let filePathString = fileURL!.path
        let tempFolder = NSTemporaryDirectory()

        // convert mp3 to 16kHz wav file
        let outputWavFilePath = mp3_to_wav(filePathString: filePathString, projectName: projectName, tempFolder: tempFolder)

        let splitedWavFilesPaths = spilt_wav(inputFilePath: outputWavFilePath)

        self.totalBatch = splitedWavFilesPaths.count

        var srtFiles = [String]()

        for (b, splitedWavFilePath) in splitedWavFilesPaths.enumerated() {
            self.currentBatch = b + 1
            var outputSplitSRTFilePath: String?
            whisper_cpp(selectedModel: selectedModel, selectedLanguage: selectedLanguage, outputWavFilePath: splitedWavFilePath) { srtFilePath in
                outputSplitSRTFilePath = srtFilePath
            }

            while outputSplitSRTFilePath == nil {
                RunLoop.current.run(mode: .default, before: .distantFuture)
            }
            srtFiles.append(outputSplitSRTFilePath!)
        }

        print("srt_files是这些", srtFiles)

        let outputSRTFilePath = merge_srt(srt_files: srtFiles)
        // srt to fcpxml
        self.outputFCPXMLFilePath = srt_to_fcpxml(srt_path: outputSRTFilePath, fps: Float(fps)!, project_name: projectName, language: selectedLanguage)

        self.outputSRTFilePath = outputSRTFilePath
    }
    
    


    
    func spilt_wav(inputFilePath: String) -> [String] {
        var result: [String] = []
        // Append file:// to the beginning
        let fileURL = URL(fileURLWithPath: inputFilePath)
        if let asset: AVAudioPlayer = try? AVAudioPlayer(contentsOf: fileURL), asset.duration > 0 {
            let duration: TimeInterval = asset.duration
            let segmentDuration: Double = 600
            if duration < segmentDuration {
                return [inputFilePath]
            }
            let numberOfSegments = Int(ceil(duration / segmentDuration) - 1)
            
            let outputPrefix = "\(inputFilePath)_p"
            for i in 0...numberOfSegments {
                let outputFilePath = "\(outputPrefix)\(i).wav"
                
                let task = Process()
                let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil)
                task.launchPath = ffmpegPath
                task.arguments = ["-i", inputFilePath, "-ss", String(i*Int(segmentDuration)), "-t", String(Int(segmentDuration)), "-c", "copy", outputFilePath]
                task.launch()
                task.waitUntilExit()
                result.append(outputFilePath)
            }
        } else {
            print("unable to get audio duation")
        }
        return result
    }
    
    func adjustSrtTime(srtTime: String, factor: Int) -> String {
        let timeComponents = srtTime.components(separatedBy: ":")
        let hours = Int(timeComponents[0]) ?? 0
        let minutes = Int(timeComponents[1]) ?? 0
        let secondsAndMilliseconds = timeComponents[2].components(separatedBy: ",")
        let seconds = Int(secondsAndMilliseconds[0]) ?? 0
        
        let totalMinutes = (hours * 60) + minutes
        let newTotalMinutes = totalMinutes + (factor * 10)
        let newHours = newTotalMinutes / 60
        let newMinutes = newTotalMinutes % 60
        
        let newTime = String(format: "%02d:%02d:%02d,%@", newHours, newMinutes, seconds, secondsAndMilliseconds[1])
        
        return newTime
    }


    func merge_srt(srt_files: [String]) -> String {
        let merged_srt_path = srt_files[0] + "_merged.srt"
        var merged_contents = ""
        var index = 1
        for (i, srt_path) in srt_files.enumerated() {
            do {
                let srt_content = try String(contentsOfFile: srt_path, encoding: .utf8)
                        let subtitles: [String] = srt_content.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n\n")
                for (_, subtitle) in subtitles.enumerated() {
                    let subtitle_item = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
                    let time_range = subtitle_item[1].components(separatedBy: " --> ")

                    let start = time_range[0]
                    let end = time_range[1]

                    let new_start = adjustSrtTime(srtTime: start, factor: i)
                    let new_end = adjustSrtTime(srtTime: end, factor: i)

                    let new_time_range = new_start + " --> " + new_end
                    let subtitle_content = subtitle_item[2]

                    merged_contents += "\(index)\n"
                    merged_contents += "\(new_time_range)\n"
                    merged_contents += "\(subtitle_content)\n\n"
                    index += 1
                    
                }
            } catch {
                print("error with reading srt files \(error)")
            }
        }
        do {
            try merged_contents.write(toFile: merged_srt_path, atomically: true, encoding: .utf8)

        } catch {
            print("write with error：\(error)")
        }
        return merged_srt_path
    }
    
    
    func download_model(model: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/ggml-\(model.lowercased()).bin") else {
            completion(false)
            return
        }

        let delegate = DownloadDelegate(model: selectedModel, progressHandler: { progress in
            self.downloadProgress = progress
        }, completionHandler: {
            self.isDownloading = false
            self.showAlert = false
            completion(true)
        })

        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.downloadTask(with: url)

        self.isDownloading = true
        self.showAlert = true

        task.resume()
    }
        
 
    
    func mp3_to_wav(filePathString: String, projectName: String, tempFolder: String) -> String {
        var wavFileName = projectName + ".wav"
        var wavFilePath = tempFolder + wavFileName

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: wavFilePath) {
            // Rename the file if it already exists
            var counter = 1
            while fileManager.fileExists(atPath: wavFilePath) {
                wavFileName = "\(projectName)_\(counter).wav"
                wavFilePath = tempFolder + wavFileName
                counter += 1
            }
        }

        let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil)
        let task = Process()
        task.launchPath = ffmpegPath
        task.arguments = ["-i", filePathString, "-ar", "16000", wavFilePath]
        task.launch()
        task.waitUntilExit()
        let status = task.terminationStatus
        print("Task completed with status: \(status)")
        return wavFilePath
    }
    
    func whisper_cpp(selectedModel: String, selectedLanguage: String, outputWavFilePath: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let applicationSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let whisperAutoCaptionsURL = applicationSupportDirectory.appendingPathComponent("Whisper Auto Captions")
            let modelPath = whisperAutoCaptionsURL.appendingPathComponent("ggml-\(selectedModel.lowercased()).bin")
            
            
            if let mainPath = Bundle.main.path(forResource: "main", ofType: nil),
               let selectedLanguageShortCut = languagesMapping[selectedLanguage]
            {
                let task = Process()
                task.launchPath = mainPath
                task.arguments = ["-m", modelPath.path, "-l", selectedLanguageShortCut, "-pp", "-osrt", "-f", outputWavFilePath]
                
            
                
                let errorPipe = Pipe()
                let outputPipe = Pipe()
                
                task.standardError = errorPipe
                task.standardOutput = outputPipe
                
                task.launch()
                let startTime = Date()
                
                let errorHandle = errorPipe.fileHandleForReading
                let outputHandle = outputPipe.fileHandleForReading
                
                
                while task.isRunning || errorHandle.availableData.count > 0 {
                    let errorData = errorHandle.availableData
                    if !errorData.isEmpty {
                        if let error = String(data: errorData, encoding: .utf8) {
                            let lines = error.split(separator: "\n")
                            if let lastLine = lines.last, lastLine.hasPrefix("whisper_full_with_state: progress") {
                                if let progressString = lastLine.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespacesAndNewlines).dropLast() {
                                    let progressPercentage = Int(progressString) ?? 0
                                    let progress = Double(Int(progressString) ?? 0) * 0.01
                                    DispatchQueue.main.async {
                                        self.progressPercentage = progressPercentage
                                        self.progress = progress
                                    }
                                    let currentTime = Date()
                                    let elapsed = currentTime.timeIntervalSince(startTime)
                                    let remainingSeconds = round((1 - Double(progress)) / Double(progress) * elapsed)
                                    let remainingTime = formatSeconds(remainingSeconds)
                                    DispatchQueue.main.async {
                                        self.remainingTime = remainingTime
                                    }
//                                    print("my current progerss is", progress, remainingTime)
                                }
                            }
                        }
                    }
                    let outputData = outputHandle.availableData
                    if !outputData.isEmpty {
                        if let outputCaptions = String(data: outputData, encoding: .utf8) {
                            DispatchQueue.main.async {
                                self.outputCaptions += outputCaptions
                            }
                        }
                    }
                }
                
                
                task.waitUntilExit()
                
                DispatchQueue.main.async {
                    self.progress = 1.0
                    self.progressPercentage = 100
                    self.remainingTime = "00:00"
                }
                
                let outputData = outputHandle.readDataToEndOfFile()
                _ = String(data: outputData, encoding: .utf8)
//                    print("Standard output: \(output)")
                
                print("My process is done!")
                
            }
            
                let srtFilePath = outputWavFilePath + ".srt"
                completion(srtFilePath)
            }
        }
    
    
    func format_text(full_text: String) -> String {
        let words = full_text.split(separator: " ")
        var lines = [String]()
        for i in stride(from: 0, to: words.count, by: 16) {
            let endIndex = min(i + 16, words.count)
            let line = words[i..<endIndex].joined(separator: " ")
            lines.append(line)
        }
        let formatted_text = lines.joined(separator: "\n")
        return formatted_text
    }


    func srt_time_to_frame(srt_time: String, fps: Float) -> Int {
        // convert srt time to ms
        let ms = Int(srt_time.suffix(3))!
        let time_components = srt_time.prefix(srt_time.count - 4).split(separator: ":")
        let srt_time_ms = (Int(time_components[0])! * 3600 + Int(time_components[1])! * 60 + Int(time_components[2])!) * 1000 + ms
        // convert ms to frame
        let frame = Int(floor(Float(srt_time_ms) / (1000 / fps)))
        return frame
    }



    func srt_to_fcpxml(srt_path: String, fps: Float, project_name: String, language: String) -> String  {
        do {
            let srt_content = try String(contentsOfFile: srt_path, encoding: .utf8)
            let subtitles: [String] = srt_content.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n\n")
            
            // ectract total duratioin from srt
            let last_subtitle = subtitles.last!
            let total_srt_time = last_subtitle.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")[1].components(separatedBy: " --> ")[1]
            let total_frame = srt_time_to_frame(srt_time: total_srt_time, fps: Float(fps));
            let hundred_fold_total_frame = String(100 * total_frame)
            let hundred_fold_fps = String(Int(fps * 100))

            // fcpxml
            let fcpxmlElement = XMLElement(name: "fcpxml")
            fcpxmlElement.addAttribute(XMLNode.attribute(withName: "version", stringValue: "1.9") as! XMLNode)

            // resource
            let resourcesElement = XMLElement(name: "resources")

            // format
            let formatElement = XMLElement(name: "format")
            formatElement.addAttribute(XMLNode.attribute(withName: "id", stringValue: "r1") as! XMLNode)
            formatElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "FFVideoFormat1080p\(hundred_fold_fps)") as! XMLNode)
            formatElement.addAttribute(XMLNode.attribute(withName: "frameDuration", stringValue: "100/\(hundred_fold_fps)s") as! XMLNode)
            formatElement.addAttribute(XMLNode.attribute(withName: "width", stringValue: "1920") as! XMLNode)
            formatElement.addAttribute(XMLNode.attribute(withName: "height", stringValue: "1080") as! XMLNode)
            formatElement.addAttribute(XMLNode.attribute(withName: "colorSpace", stringValue: "1-1-1 (Rec. 709)") as! XMLNode)
            resourcesElement.addChild(formatElement)

            // effect
            let effectElement = XMLElement(name: "effect")
            effectElement.addAttribute(XMLNode.attribute(withName: "id", stringValue: "r2") as! XMLNode)
            effectElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Basic Title") as! XMLNode)
            effectElement.addAttribute(XMLNode.attribute(withName: "uid", stringValue: ".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti") as! XMLNode)
            resourcesElement.addChild(effectElement)


            // library
            let libraryElement = XMLElement(name: "library")


            // event
            let eventElement = XMLElement(name: "event")
            eventElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Whisper Auto Captions") as! XMLNode)
            libraryElement.addChild(eventElement)

            // project
            let projectElement = XMLElement(name: "project")
            projectElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "\(project_name)") as! XMLNode)
            eventElement.addChild(projectElement)

            // sequence
            let sequenceElement = XMLElement(name: "sequence")
            sequenceElement.addAttribute(XMLNode.attribute(withName: "format", stringValue: "r1") as! XMLNode)
            sequenceElement.addAttribute(XMLNode.attribute(withName: "tcStart", stringValue: "0s") as! XMLNode)
            sequenceElement.addAttribute(XMLNode.attribute(withName: "tcFormat", stringValue: "NDF") as! XMLNode)
            sequenceElement.addAttribute(XMLNode.attribute(withName: "audioLayout", stringValue: "stereo") as! XMLNode)
            sequenceElement.addAttribute(XMLNode.attribute(withName: "audioRate", stringValue: "48k") as! XMLNode)
            sequenceElement.addAttribute(XMLNode.attribute(withName: "duration", stringValue: "\(total_frame)/\(hundred_fold_fps)s") as! XMLNode)
            projectElement.addChild(sequenceElement)


            // spine
            let spineElement = XMLElement(name: "spine")
            sequenceElement.addChild(spineElement)

            // gap
            let gapElement = XMLElement(name: "gap")
            gapElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Gap") as! XMLNode)
            gapElement.addAttribute(XMLNode.attribute(withName: "offset", stringValue: "0s") as! XMLNode)
            gapElement.addAttribute(XMLNode.attribute(withName: "duration", stringValue: "\(hundred_fold_total_frame)/\(hundred_fold_fps)s") as! XMLNode)
            spineElement.addChild(gapElement)


            for (i, subtitle) in subtitles.enumerated() {
                let subtitle_item = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
                let time_range = subtitle_item[1].components(separatedBy: " --> ")

                let offset = time_range[0]
                let end = time_range[1]
                let offset_frame = srt_time_to_frame(srt_time: offset, fps: fps)
                let end_frame = srt_time_to_frame(srt_time: end, fps: fps)
                let duration_frame = end_frame - offset_frame

                let hundred_fold_offset_frame = String(100 * offset_frame)
                let hundred_fold_duration_frame = String(100 * duration_frame)
                var subtitle_content = subtitle_item[2]
                if language == "English" {
                    if subtitle_content.split(separator: " ").count > 16 {
                        subtitle_content = format_text(full_text: subtitle_content)
                        }
                    }
                
     
                if language == "Chinese" {
                    // title
                    let titleElement = XMLElement(name: "title")
                    titleElement.addAttribute(XMLNode.attribute(withName: "ref", stringValue: "r2") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "lane", stringValue: "1") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "offset", stringValue: "\(hundred_fold_offset_frame)/\(hundred_fold_fps)s") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "duration", stringValue: "\(hundred_fold_duration_frame)/\(hundred_fold_fps)s") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "\(subtitle_content) - Basic Title") as! XMLNode)

                    // param1
                    let param1Element = XMLElement(name: "param")
                    param1Element.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Position") as! XMLNode)
                    param1Element.addAttribute(XMLNode.attribute(withName: "key", stringValue: "9999/999166631/999166633/1/100/101") as! XMLNode)
                    param1Element.addAttribute(XMLNode.attribute(withName: "value", stringValue: "0 -465") as! XMLNode)
                    titleElement.addChild(param1Element)

                    // param2
                    let param2Element = XMLElement(name: "param")
                    param2Element.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Flatten") as! XMLNode)
                    param2Element.addAttribute(XMLNode.attribute(withName: "key", stringValue: "999/999166631/999166633/2/351") as! XMLNode)
                    param2Element.addAttribute(XMLNode.attribute(withName: "value", stringValue: "1") as! XMLNode)
                    titleElement.addChild(param2Element)

                    // param3
                    let param3Element = XMLElement(name: "param")
                    param3Element.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Alignment") as! XMLNode)
                    param3Element.addAttribute(XMLNode.attribute(withName: "key", stringValue: "9999/999166631/999166633/2/354/999169573/401") as! XMLNode)
                    param3Element.addAttribute(XMLNode.attribute(withName: "value", stringValue: "1 (Center)") as! XMLNode)
                    titleElement.addChild(param3Element)

                    // text
                    let textElement = XMLElement(name: "text")
                    titleElement.addChild(textElement)

                    // text style
                    let textStyleElement = XMLElement(name: "text-style")
                    textStyleElement.addAttribute(XMLNode.attribute(withName: "ref", stringValue: "ts\(String(i))") as! XMLNode)
                    textStyleElement.stringValue = subtitle_content
                    textElement.addChild(textStyleElement)


                    // text style def
                    let textStyleDefElement = XMLElement(name: "text-style-def")
                    textStyleDefElement.addAttribute(XMLNode.attribute(withName: "id", stringValue: "ts\(String(i))") as! XMLNode)
                    titleElement.addChild(textStyleDefElement)

                    // text style 2
                    let textStyle2Element = XMLElement(name: "text-style")
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "font", stringValue: "PingFang SC") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "fontSize", stringValue: "50") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "fontFace", stringValue: "Semibold") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "fontColor", stringValue: "1 1 1 1") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "bold", stringValue: "1") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "shadowColor", stringValue: "0 0 0 0.75") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "shadowOffset", stringValue: "4 315") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "alignment", stringValue: "center") as! XMLNode)
                    textStyleDefElement.addChild(textStyle2Element)

                    gapElement.addChild(titleElement)

                } else {
                    // title
                    let titleElement = XMLElement(name: "title")
                    titleElement.addAttribute(XMLNode.attribute(withName: "ref", stringValue: "r2") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "lane", stringValue: "1") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "offset", stringValue: "\(hundred_fold_offset_frame)/\(hundred_fold_fps)s") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "duration", stringValue: "\(hundred_fold_duration_frame)/\(hundred_fold_fps)s") as! XMLNode)
                    titleElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "\(subtitle_content) - Basic Title") as! XMLNode)

                    // param1
                    let param1Element = XMLElement(name: "param")
                    param1Element.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Position") as! XMLNode)
                    param1Element.addAttribute(XMLNode.attribute(withName: "key", stringValue: "9999/999166631/999166633/1/100/101") as! XMLNode)
                    param1Element.addAttribute(XMLNode.attribute(withName: "value", stringValue: "0 -465") as! XMLNode)
                    titleElement.addChild(param1Element)

                    // param2
                    let param2Element = XMLElement(name: "param")
                    param2Element.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Flatten") as! XMLNode)
                    param2Element.addAttribute(XMLNode.attribute(withName: "key", stringValue: "999/999166631/999166633/2/351") as! XMLNode)
                    param2Element.addAttribute(XMLNode.attribute(withName: "value", stringValue: "1") as! XMLNode)
                    titleElement.addChild(param2Element)

                    // param3
                    let param3Element = XMLElement(name: "param")
                    param3Element.addAttribute(XMLNode.attribute(withName: "name", stringValue: "Alignment") as! XMLNode)
                    param3Element.addAttribute(XMLNode.attribute(withName: "key", stringValue: "9999/999166631/999166633/2/354/999169573/401") as! XMLNode)
                    param3Element.addAttribute(XMLNode.attribute(withName: "value", stringValue: "1 (Center)") as! XMLNode)
                    titleElement.addChild(param3Element)

                    // text
                    let textElement = XMLElement(name: "text")
                    titleElement.addChild(textElement)

                    // text style
                    let textStyleElement = XMLElement(name: "text-style")
                    textStyleElement.addAttribute(XMLNode.attribute(withName: "ref", stringValue: "ts\(String(i))") as! XMLNode)
                    textStyleElement.stringValue = subtitle_content
                    textElement.addChild(textStyleElement)


                    // text style def
                    let textStyleDefElement = XMLElement(name: "text-style-def")
                    textStyleDefElement.addAttribute(XMLNode.attribute(withName: "id", stringValue: "ts\(String(i))") as! XMLNode)
                    titleElement.addChild(textStyleDefElement)

                    // text style 2
                    let textStyle2Element = XMLElement(name: "text-style")
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "font", stringValue: "Helvetica") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "fontSize", stringValue: "45") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "fontFace", stringValue: "Regular") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "fontColor", stringValue: "1 1 1 1") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "shadowColor", stringValue: "0 0 0 0.75") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "shadowOffset", stringValue: "4 315") as! XMLNode)
                    textStyle2Element.addAttribute(XMLNode.attribute(withName: "alignment", stringValue: "center") as! XMLNode)
                    textStyleDefElement.addChild(textStyle2Element)

                    gapElement.addChild(titleElement)

                }
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
            let fileUrl = URL(fileURLWithPath: srt_path + ".fcpxml")
            try! xmlData.write(to: fileUrl)
            return srt_path + ".fcpxml"
        }
        
        catch {
//            print("Error: \(error)")
            return "Error "
        }
    }
    func formatSeconds(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        if seconds >= 3600 {
            formatter.maximumUnitCount = 3
        } else  {
            formatter.maximumUnitCount = 2
            formatter.allowedUnits = [.minute, .second]
        }
        let formattedTime = formatter.string(from: seconds)!
        return formattedTime
    }
}

struct ProcessView: View {
    @Binding var progress: Double
    @Binding var progressPercentage: Int
    @Binding var totalBatch: Int
    @Binding var currentBatch: Int
    @Binding var remainingTime: String
    @Binding var outputCaptions: String
    @Binding var projectName: String
    @Binding var outputFCPXMLFilePath: String
    @Binding var outputSRTFilePath: String
    @Binding var isPresented: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack() {
                HStack{
                    Text("Project: \(projectName)").font(.title2)
                    Spacer()
                    Button(action: {
                        self.outputCaptions = ""
                        self.progress = 0.0
                        self.progressPercentage = 0
                        self.remainingTime = "00:00"
                        self.isPresented = false
                        self.outputSRTFilePath = ""
                        self.outputFCPXMLFilePath = ""
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    
                }.padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, -28).padding(.top, -20)
                
                
                
                ScrollView {
                    Text(outputCaptions)
                        .font(.title3)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, -2)
                        .padding(.vertical, -26)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                }.overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .red, .pink, .purple, .blue, .cyan, .green, .yellow]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding()
                .padding(.bottom, -20)
                .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 0, y: 2)
        
                
                HStack {
                    Text("Download files: ").font(.title2)
                    Button(action: {
                        downloadFile(filePath: outputSRTFilePath)
                    }) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Download .srt file")
                    }.buttonStyle(.borderedProminent).controlSize(.large)
                        .tint(.purple)
                        .disabled(self.currentBatch == self.totalBatch && progressPercentage < 100)
                    
                    Button(action: {
                        downloadFile(filePath: outputFCPXMLFilePath)
                    }) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Download .fcpxml file")
                    }.buttonStyle(.borderedProminent).controlSize(.large)
                        .tint(.blue)
                        .disabled(self.currentBatch == self.totalBatch && progressPercentage < 100)
                    
                    Button(action: {
                        downloadFile(filePath: outputSRTFilePath)
                        downloadFile(filePath: outputFCPXMLFilePath)
                    }) {
                        Image(systemName: "folder.badge.plus")
                        Text("Download All")
                    }.buttonStyle(.borderedProminent).controlSize(.large)
                        .tint(.green)
                        .disabled(self.currentBatch == self.totalBatch && progressPercentage < 100)
                    
                }
                .padding().padding(.bottom, -20)
                .frame(width: geometry.size.width,  alignment: .leading)
                
                
                
                HStack {
                    Text("Open in Final Cut Pro: ")
                        .font(.title2)
                    Button(action: {
                        print("back to fcpx")
                        backtofcpx(fcpxml_path: outputFCPXMLFilePath)
                    }) {
                        if let imagePath = Bundle.main.path(forResource: "fcpx-icon", ofType: "png"),
                           let nsImage = NSImage(contentsOfFile: imagePath) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: nsImage.size.width * 0.05, height: nsImage.size.height * 0.05)
                        }
                        Text("Click here to check auto captions in Final Cut Pro X")
                    }.buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.gray)
                        .disabled(self.currentBatch == self.totalBatch && progressPercentage < 100)
                }.padding().padding(.bottom, -20).frame(width: geometry.size.width,  alignment: .leading)
                
                LinearGradient(gradient: Gradient(colors: [.orange, .red, .pink, .purple, .blue, .cyan, .green, .yellow]), startPoint: .leading, endPoint: .trailing)
                    .mask(
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 6)
                                .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
                        }
                    )
                
                    .frame(height:8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(gradient: Gradient(colors: [.orange.opacity(0.3), .red.opacity(0.3), .pink.opacity(0.3), .purple.opacity(0.3), .blue.opacity(0.3), .cyan.opacity(0.3), .green.opacity(0.3), .yellow.opacity(0.3)]), startPoint: .leading, endPoint: .trailing)
                            )
                    ).padding().padding(.bottom, -16)
                Text("Batch (\(currentBatch == -100000 ? "···" : String(currentBatch)) / \(totalBatch == 100000 ? "···" : String(totalBatch))): \(progressPercentage)% completed - \(remainingTime) remaining")
    
            }
        }
        .padding()
    }
    
    func backtofcpx(fcpxml_path: String) {
        let command =
        """
        tell application "Final Cut Pro"
            launch
            activate
            open POSIX file "\(fcpxml_path)"
        end tell
        """
        DispatchQueue.global(qos: .background).async {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: command) {
                if let output = scriptObject.executeAndReturnError(&error).stringValue {
                    print(output)
                } else if (error != nil) {
//                    print("Error: \(error!)")
                }
            }
        }
    }
    func downloadFile(filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

        guard let destinationURL = downloadsURL?.appendingPathComponent(fileURL.lastPathComponent) else {
            return
        }
        

        let fileManager = FileManager.default
        var updatedDestinationURL = destinationURL

        if fileManager.fileExists(atPath: updatedDestinationURL.path) {
            let originalFileName = updatedDestinationURL.deletingPathExtension().lastPathComponent
            let originalFileExtension = updatedDestinationURL.pathExtension

            var counter = 1
            while fileManager.fileExists(atPath: updatedDestinationURL.path) {
                let newFileName = "\(originalFileName)_\(counter).\(originalFileExtension)"
                updatedDestinationURL = updatedDestinationURL.deletingLastPathComponent().appendingPathComponent(newFileName)
                counter += 1
            }
        }

        let task = URLSession.shared.downloadTask(with: fileURL) { location, _, error in
            guard let location = location else {
                if let error = error {
                    print("Download failed: \(error.localizedDescription)")
                }
                return
            }

            do {
                try fileManager.moveItem(at: location, to: updatedDestinationURL)
                print("Download completed")
            } catch {
                print("Failed to move downloaded file: \(error.localizedDescription)")
            }
        }

        task.resume()
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


