<p align="center">
    <img height="256" src="https://github.com/shaishaicookie/fcpx-auto-captions/blob/main/Whisper%20Auto%20Captions/Assets.xcassets/AppIcon.appiconset/1024.png" />
</p>
<h1 align="center">Whisper Auto Captions</h1>
<p align="center">Auto Captions for Final Cut Pro Powered by OpenAI's Whisper Model</p>

<p align="center">
    <a href="README_KO.md">한국어</a>
</p>

## Demo
<img src="demo.gif">

## Demo Video
Youtube: [https://youtu.be/2_QOACyuZIk](https://youtu.be/n1qMG87aJcw)

## Website
https://whisperautocaptions.com/

## Download

**[Download Latest Release](https://github.com/zerodice0/fcpx-auto-captions/releases/latest)**

The app now ships as a **Universal binary** that works on both Apple Silicon (M1/M2/M3/M4) and Intel Macs.

* [All Releases](https://github.com/zerodice0/fcpx-auto-captions/releases)

## Features
* Accurate transcription in over 90 languages
* Live output & Progress bar
* Send FCPXML directly to Final Cut Pro X
* SRT file download for seamless editing in Adobe Premiere Pro, DaVinci Resolve & Sony Vegas
* **SRT to FCPXML conversion** - Convert existing SRT files to FCPXML format
* **Advanced whisper.cpp settings** with presets (Fastest, Fast, Balanced, Quality, Best Quality)
* **Multi-language UI** - English, Korean, Japanese
* **AI Assistant** - AI-powered Whisper settings recommendation using Google Gemini
* **Custom Title Style** - Full customization for FCPXML caption styling
* **Auto Frame Rate Detection** - Automatic frame rate detection from video files
* **Configurable Audio Segments** - Adjustable segment duration (1-30 minutes)
* **Persistent Settings** - All settings saved across app restarts
* **Auto Updates** - Built-in automatic update checking via Sparkle

## AI Assistant

The app integrates with Google Gemini AI to help you find the optimal Whisper settings for your specific use case.

### How It Works
1. Describe your situation in natural language (e.g., "I have a podcast recording with two speakers in a quiet room")
2. Gemini AI analyzes your description and recommends the best Whisper settings
3. Apply the recommended settings with one click

### Setup
1. Get a free API key from [Google AI Studio](https://aistudio.google.com/)
2. Enter your API key in the Settings tab
3. Your API key is securely stored in macOS Keychain

## Title Style Customization

Customize the appearance of captions in your FCPXML output:

| Option | Description |
|--------|-------------|
| Position | 7 presets (Lower Third, Center, Top, etc.) + Custom X/Y offset |
| Font | Font family, size (10-200pt), and weight |
| Colors | Text color, stroke color, and shadow color with opacity |
| Alignment | Left, Center, or Right text alignment |

## Advanced Settings

The app provides comprehensive whisper.cpp configuration options:

### Presets
| Preset | Use Case |
|--------|----------|
| Fastest | Quick previews, maximum speed |
| Fast | Fast processing with reasonable accuracy |
| Balanced | Recommended for most use cases |
| Quality | Higher accuracy at the cost of speed |
| Best Quality | Maximum accuracy, significantly slower |
| Custom | Fine-tune all parameters manually |

### Settings Categories
- **Quality**: Beam size, best-of sampling, entropy threshold
- **Performance**: Thread count, processor count, flash attention
- **Output**: Output format options
- **Advanced**: Temperature, audio context settings
- **Audio Segment Duration**: Split audio into segments (1-30 minutes) for processing
