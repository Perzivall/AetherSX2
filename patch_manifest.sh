#!/bin/bash
set -e

INPUT_APK="app-release-unsigned.apk"
OUTPUT_APK="app-release-patched.apk"
DECODE_DIR="temp_decoded"

echo "=== Patching AndroidManifest.xml ==="

if [ -d "$DECODE_DIR" ]; then
    rm -rf "$DECODE_DIR"
fi

echo "Decompiling $INPUT_APK..."
apktool d -f "$INPUT_APK" -o "$DECODE_DIR"

MANIFEST_FILE="$DECODE_DIR/AndroidManifest.xml"

if grep -q "android.permission.INTERNET" "$MANIFEST_FILE"; then
    echo "Permission already present."
else
    echo "Adding INTERNET permission..."
    # Insert permission before the application tag
    sed -i '' '/<application/i \
    <uses-permission android:name="android.permission.INTERNET"/>' "$MANIFEST_FILE"
fi

echo "Rebuilding APK..."
apktool b "$DECODE_DIR" -o "$OUTPUT_APK"

echo "Cleaning up..."
rm -rf "$DECODE_DIR"

echo "Success! Created $OUTPUT_APK"
