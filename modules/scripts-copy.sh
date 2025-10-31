#!/usr/bin/env bash
# ======================================
# Optimus Desktop :: Sync Bin Scripts
# Syncs local bin/ to ~/.local/bin/
# ======================================

set -euo pipefail

SOURCE_DIR="bin/"
DEST_DIR="$HOME/.local/bin/"

echo "[INFO] ==== Syncing bin scripts ===="
mkdir -p "$DEST_DIR"

rsync -avh --progress "$SOURCE_DIR" "$DEST_DIR"

echo "[SUCCESS] Scripts synced to ~/.local/bin/"
