#!/usr/bin/env bash
# ===================================================
# 🌐 Optimus Desktop :: Sync Bin Scripts (Gum Enhanced)
# ===================================================

set -euo pipefail

# --- Require gum ---
if ! command -v gum &>/dev/null; then
  echo "❌ gum not found. Please install it first (sudo pacman -S gum)."
  exit 1
fi

# --- Define Paths ---
SOURCE_DIR="bin/"
DEST_DIR="$HOME/.local/bin/"

# -------------------------------------------------------------------------
# ---- Header ----
# -------------------------------------------------------------------------
gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Sync Bin Scripts" \
  "───────────────────────────────────" \
  "Synchronizes local 'bin/' scripts to \$HOME/.local/bin/"

# -------------------------------------------------------------------------
# ---- Sync Operation ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Initiating synchronization..."

if [ ! -d "$SOURCE_DIR" ]; then
  gum style --foreground 196 "❌ ERROR: Source directory '$SOURCE_DIR' not found. Cannot sync."
  exit 1
fi

gum spin --spinner dot --title "Creating destination directory and copying scripts..." -- \
  bash -c "mkdir -p '$DEST_DIR' && rsync -avh '$SOURCE_DIR' '$DEST_DIR'"

# -------------------------------------------------------------------------
# ---- Final Message ----
# -------------------------------------------------------------------------
gum style --foreground 82 --bold "✅ Scripts successfully synced to $DEST_DIR"
gum style --foreground 240 "[TIP] Ensure '$DEST_DIR' is included in your \$PATH."
