#!/usr/bin/env bash
# ======================================
# Optimus Desktop :: Sync Config Files
# Syncs local config/ to ~/.config/
# ======================================

set -euo pipefail

SOURCE_DIR="config/"
DEST_DIR="$HOME/.config/"

echo "[INFO] ==== Syncing config files ===="
mkdir -p "$DEST_DIR"

rsync -avh --progress "$SOURCE_DIR" "$DEST_DIR"

echo "[SUCCESS] Config files synced to ~/.config/"
