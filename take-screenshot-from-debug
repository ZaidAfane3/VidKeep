#!/bin/bash

# ===========================================
# Take Screenshot from Android Debug Device
# ===========================================
# Usage: ./take-screenshot-from-debug
# ===========================================

# Device IP and Port (modify as needed)
DEVICE="100.99.14.10:42131"

# Local directory to save screenshots
OUTPUT_DIR="$(dirname "$0")/screenshots-debugging"

# Remote path on device
REMOTE_PATH="/sdcard/debug_screenshot.png"

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="screenshot_${TIMESTAMP}.png"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "📱 Taking screenshot from $DEVICE..."

# Take screenshot on device
adb -s "$DEVICE" shell screencap -p "$REMOTE_PATH"
if [ $? -ne 0 ]; then
    echo "❌ Failed to take screenshot"
    exit 1
fi

# Pull screenshot to local machine
adb -s "$DEVICE" pull "$REMOTE_PATH" "$OUTPUT_DIR/$FILENAME"
if [ $? -ne 0 ]; then
    echo "❌ Failed to download screenshot"
    exit 1
fi

# Delete screenshot from device
adb -s "$DEVICE" shell rm "$REMOTE_PATH"
if [ $? -ne 0 ]; then
    echo "⚠️  Warning: Failed to delete remote screenshot"
fi

echo "✅ Screenshot saved: $OUTPUT_DIR/$FILENAME"

# Open the screenshot (macOS)
# open "$OUTPUT_DIR/$FILENAME" 2>/dev/null || true
