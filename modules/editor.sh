#!/usr/bin/env bash
# =======================================================
# 🌐 Optimus Desktop :: Direct Editor Installation
# =======================================================
set -euo pipefail

# --- Helper Function: Detect available AUR helper ---
detect_aur_helper() {
  if command -v paru &>/dev/null; then
    echo "paru"
  elif command -v yay &>/dev/null; then
    echo "yay"
  else
    echo ""
  fi
}

# --- Header ---
gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Installing Editors" \
  "──────────────────────────────────────────" \
  "Installing Visual Studio Code and Geany..."

# --- 1. Install Geany (Official Repos) ---
gum style --foreground 45 "📦 Step 1: Installing Geany via pacman..."
sudo pacman -S --needed --noconfirm geany

# --- 2. Install VS Code (AUR) ---
AUR_HELPER=$(detect_aur_helper)

if [[ -z "$AUR_HELPER" ]]; then
  gum style --foreground 196 "❌ ERROR: VS Code requires an AUR helper (paru/yay), but none was found."
  exit 1
fi

gum style --foreground 159 "📦 Step 2: Installing VS Code via $AUR_HELPER..."
"$AUR_HELPER" -S --needed --noconfirm visual-studio-code-bin

# --- Final Verification ---
gum style --foreground 82 --bold "✅ Successfully installed Geany and VS Code!"
gum style --foreground 240 "You can now launch them from your applications menu."