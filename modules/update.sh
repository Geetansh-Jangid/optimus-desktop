#!/bin/bash
# ===========================================
# 🌐 Optimus Desktop :: Unified System Upgrade (Verbose)
# ===========================================
set -euo pipefail

gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Unified System Upgrade (Verbose)" \
  "───────────────────────────────────────────────────────" \
  "Updates all detected package managers with raw log output. ✨"

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

# --- Step 5: Execute Upgrade Plan with Raw Logs ---
INSTALL_FAILED=false

# Update Official Repos and/or AUR
gum style --border heavy --border-foreground 212 --margin "1 0" "--- Updating Arch Packages ---"
if [[ -n "$AUR_HELPER" ]]; then
  if ! "$AUR_HELPER" -Syu --noconfirm; then
    gum style --foreground 196 "❌ $AUR_HELPER upgrade failed."
    INSTALL_FAILED=true
  fi
else
  if ! sudo pacman -Syu --noconfirm; then
    gum style --foreground 196 "❌ pacman upgrade failed."
    INSTALL_FAILED=true
  fi
fi

# Update Flatpaks if detected and no previous error occurred
if [[ -n "$FLATPAK_CMD" && "$INSTALL_FAILED" == false ]]; then
  gum style --border heavy --border-foreground 212 --margin "1 0" "--- Updating Flatpak Packages ---"
  if ! flatpak update -y; then
    gum style --foreground 196 "❌ Flatpak upgrade failed."
    INSTALL_FAILED=true
  fi
fi

# Update Snaps if detected and no previous error occurred
if [[ -n "$SNAP_CMD" && "$INSTALL_FAILED" == false ]]; then
  gum style --border heavy --border-foreground 212 --margin "1 0" "--- Updating Snap Packages ---"
  if ! sudo snap refresh; then
    gum style --foreground 196 "❌ Snap upgrade failed."
    INSTALL_FAILED=true
  fi
fi

# --- Final Status ---
if [[ "$INSTALL_FAILED" == true ]]; then
  gum style --foreground 196 --bold "❌ One or more update commands failed. Please review the output above."
  exit 1
fi

gum style --foreground 82 --bold "✅ System upgrade completed successfully!"
