#!/usr/bin/env bash
# ======================================
# Copy all files from bin/ to ~/.local/bin/
# ======================================

set -euo pipefail

SOURCE_DIR="bin"
DEST_DIR="$HOME/.local/bin"

echo "[INFO] Copying binaries from '$SOURCE_DIR' to '$DEST_DIR'..."

# Create destination if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy recursively and overwrite
cp -rT "$SOURCE_DIR" "$DEST_DIR"

echo "[SUCCESS] All binaries copied to ~/.local/bin/"
