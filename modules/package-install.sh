#!/usr/bin/env bash
# =============================================
# Optimus Desktop :: Package Installer
# Installs pacman + AUR packages from text lists
# =============================================

set -euo pipefail

PACMAN_FILE="data/pkgs-pacman.txt"
AUR_FILE="data/pkgs-aur.txt"

# ---- Detect AUR Helper ----
if command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
else
  echo "[ERROR] No AUR helper found (paru/yay). Please install one first."
  exit 1
fi

echo "[INFO] Using AUR helper: $AUR_HELPER"

# ---- Function to read non-empty, non-comment lines ----
read_packages() {
  local file="$1"
  grep -Ev '^\s*#|^\s*$' "$file" 2>/dev/null || true
}

# ---- Install Pacman Packages ----
if [[ -f "$PACMAN_FILE" ]]; then
  echo "[INFO] Installing pacman packages from $PACMAN_FILE..."
  pacman_pkgs=($(read_packages "$PACMAN_FILE"))
  if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
    sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"
  else
    echo "[INFO] No pacman packages to install."
  fi
else
  echo "[WARN] Pacman list not found: $PACMAN_FILE"
fi

# ---- Install AUR Packages ----
if [[ -f "$AUR_FILE" ]]; then
  echo "[INFO] Installing AUR packages from $AUR_FILE..."
  aur_pkgs=($(read_packages "$AUR_FILE"))
  if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
    $AUR_HELPER -S --needed --noconfirm "${aur_pkgs[@]}"
  else
    echo "[INFO] No AUR packages to install."
  fi
else
  echo "[WARN] AUR list not found: $AUR_FILE"
fi

echo "[DONE] All packages processed successfully!"
