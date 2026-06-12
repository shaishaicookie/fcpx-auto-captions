# CLAUDE.md

## Project Overview
macOS SwiftUI app for generating captions/subtitles for Final Cut Pro X using OpenAI Whisper. Outputs FCPXML and SRT files.

## Build
```bash
xcodebuild -project "Whisper Auto Captions.xcodeproj" -scheme "Whisper Auto Captions" build
```

## Architecture (MVVM)
```
Whisper Auto Captions/
├── Views/           # SwiftUI views (Transcription, SRTConverter, Settings, Components)
├── ViewModels/      # HomeViewModel, SRTConverterViewModel
├── Models/          # FrameRate, VideoResolution, TitleStyleSettings, WhisperSettings
├── Services/        # Audio, Video, Whisper, SRT, FCPXML, Download, Gemini services
├── Managers/        # SettingsManager
├── Utilities/       # FileUtility, DownloadDelegate, AppDirectoryUtility
├── ffmpeg           # Bundled binary for audio conversion
└── whisper-cli      # Bundled whisper.cpp executable
```

## Processing Pipeline
1. Video/Audio → 16kHz WAV (ffmpeg)
2. Split into segments → whisper-cli → SRT files
3. Merge SRT → Convert to FCPXML

## Output Formats
- **SRT**: Standard subtitle format
- **FCPXML**: Final Cut Pro X project with Basic Title elements
