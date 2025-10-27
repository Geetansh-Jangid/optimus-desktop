#!/usr/bin/env bash
# ======================================
# Copy all files from config/ to ~/.config/
# ======================================

set -euo pipefail

SOURCE_DIR="config"
DEST_DIR="$HOME/.config"

echo "[INFO] Copying configs from '$SOURCE_DIR' to '$DEST_DIR'..."

# Create ~/.config if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy recursively, preserving structure and overwriting existing files
cp -rT "$SOURCE_DIR" "$DEST_DIR"

echo "[SUCCESS] All configuration files copied to ~/.config/"
