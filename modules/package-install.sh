#!/usr/bin/env bash
# =============================================
# 🌐 Optimus Desktop :: Package Installer (Interactive)
# Installs pacman + AUR packages from text lists, requiring passwords/confirmations
# =============================================

set -euo pipefail

# --- File Paths ---
PACMAN_FILE="data/pkgs-pacman.txt"
AUR_FILE="data/pkgs-aur.txt"

# --- Require gum ---
if ! command -v gum &>/dev/null; then
  echo "❌ gum not found. Please install it first (sudo pacman -S gum)."
  exit 1
fi

# --- Fancy Header ---
gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐  Optimus Desktop :: Package Installer" \
  "───────────────────────────────────────────" \
  "Installs pacman + AUR packages from text lists"

# --- Detect AUR Helper ---
AUR_HELPER=""
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
else
  gum style --foreground 196 "❌ No AUR helper found (paru/yay). Please install one first."
  exit 1
fi

gum style --foreground 212 "✅ Using AUR helper:" "$AUR_HELPER"

# --- Function: read non-empty, non-comment lines ---
read_packages() {
  local file="$1"
  grep -Ev '^\s*#|^\s*$' "$file" 2>/dev/null || true
}

# --- Confirm before proceeding ---
gum confirm "Proceed with package installation?" || exit 0

---

### 1. Interactive Pacman Installation

if [[ -f "$PACMAN_FILE" ]]; then
  gum style --foreground 45 "[INFO] Preparing to install pacman packages from $PACMAN_FILE..."
  pacman_pkgs=($(read_packages "$PACMAN_FILE"))

  if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
    # Use gum style to display the command about to run
    gum style --foreground 220 "➡️ Running: sudo pacman -S --needed ${pacman_pkgs[@]}"

    # Run the installation *without* gum spin and *without* --noconfirm
    # This ensures the standard sudo password prompt and pacman confirmation appear.
    sudo pacman -S --needed "${pacman_pkgs[@]}"

    if [[ $? -eq 0 ]]; then
      gum style --foreground 82 "✔ Pacman packages installed successfully."
    else
      gum style --foreground 196 "❌ Pacman installation failed or was cancelled."
    fi
  else
    gum style --foreground 240 "[INFO] No pacman packages to install."
  fi
else
  gum style --foreground 208 "[WARN] Pacman list not found: $PACMAN_FILE"
fi

---

### 2. Interactive AUR Installation

if [[ -f "$AUR_FILE" ]]; then
  gum style --foreground 45 "[INFO] Preparing to install AUR packages from $AUR_FILE..."
  aur_pkgs=($(read_packages "$AUR_FILE"))

  if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
    # Use gum style to display the command about to run
    gum style --foreground 220 "➡️ Running: $AUR_HELPER -S --needed ${aur_pkgs[@]}"

    # Run the installation *without* gum spin and *without* --noconfirm
    # This allows the AUR helper to prompt for confirmation and password (if needed).
    $AUR_HELPER -S --needed "${aur_pkgs[@]}"

    if [[ $? -eq 0 ]]; then
      gum style --foreground 82 "✔ AUR packages installed successfully."
    else
      gum style --foreground 196 "❌ AUR installation failed or was cancelled."
    fi
  else
    gum style --foreground 240 "[INFO] No AUR packages to install."
  fi
else
  gum style --foreground 208 "[WARN] AUR list not found: $AUR_FILE"
fi

---

gum style --border double --padding "1 2" --border-foreground 82 \
  "🎉 Installation sequence finished!"
