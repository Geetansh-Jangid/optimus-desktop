#!/usr/bin/env bash
# ===========================================
# Optimus Desktop :: Copy zshrc contents
# ===========================================
set -euo pipefail

SOURCE_FILE="zshrc"
TARGET_FILE="$HOME/.zshrc"

echo "[INFO] Copying contents from '$SOURCE_FILE' to '$TARGET_FILE'..."

# Ensure source exists
if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "[ERROR] Source file '$SOURCE_FILE' not found!"
  exit 1
fi

# Create target if it doesn't exist
touch "$TARGET_FILE"

# Overwrite contents safely
cat "$SOURCE_FILE" >"$TARGET_FILE"

echo "[SUCCESS] Contents copied successfully to '$TARGET_FILE'."
