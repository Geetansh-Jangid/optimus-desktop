#!/bin/bash
# ===========================================
# 🌐 Optimus Desktop :: Unified System Upgrade
# ===========================================
set -euo pipefail

# This function will be called if any command fails
on_error() {
  gum style --foreground 196 --bold "❌ An error occurred. Update process halted."
  exit 1
}

# Trap any error signal and call the on_error function
trap 'on_error' ERR

gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Unified System Upgrade" \
  "─────────────────────────────────────────────" \
  "Updates all detected package managers on the system. ✨"

# --- Step 1: Detect available package managers ---
gum style --foreground 45 "[INFO] Detecting available package managers..."

UPGRADE_PLAN=()
AUR_HELPER=""
FLATPAK_CMD=""
SNAP_CMD=""

# Check for AUR Helper
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
fi

# Check for Flatpak
if command -v flatpak &>/dev/null; then
  FLATPAK_CMD="flatpak"
fi

# Check for Snap
if command -v snap &>/dev/null; then
  SNAP_CMD="snap"
fi

# --- Step 2: Build and Display the Upgrade Plan ---
if [[ -n "$AUR_HELPER" ]]; then
  # The AUR helper handles both official and AUR packages
  UPGRADE_PLAN+=("Official Repositories + AUR ($AUR_HELPER)")
else
  # Fallback to pacman if no helper is found
  UPGRADE_PLAN+=("Official Repositories (pacman)")
fi

if [[ -n "$FLATPAK_CMD" ]]; then
  UPGRADE_PLAN+=("Flatpak Packages")
fi

if [[ -n "$SNAP_CMD" ]]; then
  UPGRADE_PLAN+=("Snap Packages")
fi

gum style --border normal --padding "1 2" --margin "1 0" \
  --border-foreground 212 "System Upgrade Plan"
gum join --vertical --align left -- "${UPGRADE_PLAN[@]}"

# --- Step 3: Confirm & Proceed ---
if ! gum confirm "🚀 Ready to proceed with the full system upgrade?"; then
  gum style --foreground 196 "❌ Operation cancelled by user."
  exit 0
fi

# --- Step 4: Preload sudo credentials cleanly ---
gum style --foreground 244 "🔑 Checking sudo access (required for pacman/snap)..."
sudo -v

# --- Step 5: Execute Upgrade Plan ---

# Update Official Repos and/or AUR
if [[ -n "$AUR_HELPER" ]]; then
  gum spin --spinner line --title "Upgrading via $AUR_HELPER..." -- \
    "$AUR_HELPER" -Syu --noconfirm
else
  gum spin --spinner line --title "Upgrading via pacman..." -- \
    sudo pacman -Syu --noconfirm
fi

# Update Flatpaks if detected
if [[ -n "$FLATPAK_CMD" ]]; then
  gum spin --spinner line --title "Upgrading Flatpaks..." -- \
    flatpak update -y
fi

# Update Snaps if detected
if [[ -n "$SNAP_CMD" ]]; then
  gum spin --spinner line --title "Upgrading Snaps..." -- \
    sudo snap refresh
fi

# --- Final Status ---
# If the script reaches this point, the trap was not sprung, so all is well.
gum style --foreground 82 --bold "✅ System upgrade completed successfully!"
