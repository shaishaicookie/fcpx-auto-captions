#!/bin/bash
# Download Universal FFmpeg binary for local development
# Run this script before building the project if ffmpeg is missing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FFMPEG_PATH="$PROJECT_DIR/Whisper Auto Captions/ffmpeg"

echo "Downloading Universal FFmpeg binary..."

# Check if ffmpeg already exists
if [ -f "$FFMPEG_PATH" ]; then
    echo "FFmpeg already exists at: $FFMPEG_PATH"
    file "$FFMPEG_PATH"
    exit 0
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download arm64 and Intel FFmpeg binaries
echo "Downloading arm64 binary..."
curl -L -o "$TEMP_DIR/ffmpeg-arm64.zip" \
    "https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffmpeg.zip"

echo "Downloading Intel binary..."
curl -L -o "$TEMP_DIR/ffmpeg-intel.zip" \
    "https://ffmpeg.martin-riedl.de/redirect/latest/macos/amd64/release/ffmpeg.zip"

# Extract binaries
echo "Extracting binaries..."
unzip -o "$TEMP_DIR/ffmpeg-arm64.zip" -d "$TEMP_DIR/arm64"
unzip -o "$TEMP_DIR/ffmpeg-intel.zip" -d "$TEMP_DIR/intel"

# Create Universal binary with lipo
echo "Creating Universal binary..."
lipo -create "$TEMP_DIR/arm64/ffmpeg" "$TEMP_DIR/intel/ffmpeg" -output "$FFMPEG_PATH"

# Make executable
chmod +x "$FFMPEG_PATH"

# Verify Universal binary
echo ""
echo "FFmpeg downloaded successfully!"
file "$FFMPEG_PATH"
