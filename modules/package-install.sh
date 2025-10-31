#!/usr/bin/env bash
# =============================================
# 🌐 Optimus Desktop :: Package Installer (GUM)
# Installs pacman + AUR packages from text lists
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

# ------------------------------------------------------------------
# --- MODIFICATION: Install Pacman Packages (Iterative) ---
# ------------------------------------------------------------------
if [[ -f "$PACMAN_FILE" ]]; then
  gum style --foreground 45 "[INFO] Installing pacman packages from $PACMAN_FILE..."
  pacman_pkgs=($(read_packages "$PACMAN_FILE"))

  if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
    for pkg in "${pacman_pkgs[@]}"; do
      gum spin --spinner line --title "Installing pacman package: **$pkg**" -- \
        sudo pacman -S --needed --noconfirm "$pkg"
      # Check the exit status of the pacman command
      if [[ $? -eq 0 ]]; then
        gum style --foreground 82 "✔ Successfully installed: $pkg"
      else
        gum style --foreground 196 "❌ Failed to install: $pkg"
      fi
    done
    gum style --foreground 82 "✔ All Pacman packages processed."
  else
    gum style --foreground 240 "[INFO] No pacman packages to install."
  fi
else
  gum style --foreground 208 "[WARN] Pacman list not found: $PACMAN_FILE"
fi

# ------------------------------------------------------------------
# --- MODIFICATION: Install AUR Packages (Iterative) ---
# ------------------------------------------------------------------
if [[ -f "$AUR_FILE" ]]; then
  gum style --foreground 45 "[INFO] Installing AUR packages from $AUR_FILE..."
  aur_pkgs=($(read_packages "$AUR_FILE"))

  if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
    for pkg in "${aur_pkgs[@]}"; do
      gum spin --spinner line --title "Installing AUR package: **$pkg** via $AUR_HELPER" -- \
        $AUR_HELPER -S --needed --noconfirm "$pkg"
      # Check the exit status of the AUR helper command
      if [[ $? -eq 0 ]]; then
        gum style --foreground 82 "✔ Successfully installed: $pkg"
      else
        gum style --foreground 196 "❌ Failed to install: $pkg"
      fi
    done
    gum style --foreground 82 "✔ All AUR packages processed."
  else
    gum style --foreground 240 "[INFO] No AUR packages to install."
  fi
else
  gum style --foreground 208 "[WARN] AUR list not found: $AUR_FILE"
fi

gum style --border double --padding "1 2" --border-foreground 82 \
  "🎉 All packages processed successfully!"
