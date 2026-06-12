# Manual QA Checklist

Use this checklist for release smoke testing and feature verification that needs a real macOS app session, local media files, bundled command-line tools, or Final Cut Pro.

## Setup

- [ ] Build and launch the app on macOS 13.0 or newer.
- [ ] Confirm bundled `ffmpeg` and `whisper-cli` are present or install local binaries using `scripts/download-ffmpeg.sh`.
- [ ] Prepare a short media file with clear speech.
- [ ] Prepare an existing `.srt` file for SRT-to-FCPXML conversion.
- [ ] Use `docs/manual-qa-artifacts/` for local-only outputs, screenshots, temporary media, and logs that should not be committed.

## Caption Generation

- [ ] Import a media file and confirm the app accepts the selected file.
- [ ] Generate captions with the Balanced preset.
- [ ] Confirm progress updates while transcription is running.
- [ ] Confirm the final transcript is visible after processing completes.
- [ ] Export `.srt` and confirm the file opens with expected timestamps and text.
- [ ] Export `.fcpxml` and confirm the file is created.

## Final Cut Pro Workflow

- [ ] Send or import the generated FCPXML into Final Cut Pro.
- [ ] Confirm captions appear on the timeline.
- [ ] Confirm caption timing roughly matches the source media.
- [ ] Confirm custom title style settings are reflected in the imported captions.

## SRT Conversion

- [ ] Import an existing `.srt` file.
- [ ] Convert it to FCPXML.
- [ ] Confirm the generated FCPXML preserves subtitle order and timing.

## Settings

- [ ] Change whisper.cpp presets and confirm settings update in the UI.
- [ ] Adjust audio segment duration and confirm the selected value persists.
- [ ] Change title style options such as position, font, color, and alignment.
- [ ] Restart the app and confirm persistent settings are restored.
- [ ] If testing AI Assistant, save a Gemini API key and confirm it is stored and reused without re-entry.

## Error Handling

- [ ] Try an unsupported file and confirm the app shows an actionable error.
- [ ] Try a missing or invalid executable path and confirm processing fails clearly.
- [ ] Cancel or close a file picker and confirm the app remains usable.
