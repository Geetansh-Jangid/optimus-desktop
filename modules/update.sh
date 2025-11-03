#!/bin/bash
# ===========================================
# 🌐 Optimus Desktop :: System Updater
# ===========================================
set -euo pipefail

gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: System Updater" \
  "────────────────────────────────────" \
  "Refresh repositories and upgrade your system with style ✨"

# --- Step 1: Preload sudo credentials cleanly ---
gum style --foreground 244 "🔑 Checking sudo access (you may be prompted for your password)..."
if ! sudo -v; then
  gum style --foreground 196 "❌ sudo credentials failed. Exiting."
  exit 1
fi
gum style --foreground 82 "[OK] Sudo access verified."

# --- Step 2: Auto-detect AUR Helper ---
AUR_HELPER=""
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
fi

# --- Step 3: Choose Action ---
# Dynamically build the list of choices
CHOICES=("Refresh Repositories (pacman -Sy)" "Upgrade Official Packages (pacman -Syu)")
if [[ -n "$AUR_HELPER" ]]; then
  # Add the AUR option if a helper was found
  CHOICES+=("Upgrade Official + AUR Packages ($AUR_HELPER)")
  gum style --foreground 82 "[OK] Detected AUR Helper: $AUR_HELPER"
fi

gum style --foreground 212 --bold --margin "1 0" "Please choose an action to perform:"
ACTION=$(gum choose "${CHOICES[@]}")

if [[ -z "$ACTION" ]]; then
  gum style --foreground 196 "❌ No action selected. Exiting."
  exit 1
fi

# --- Step 4: Confirm & Proceed ---
if ! gum confirm "🚀 Ready to proceed with: '$ACTION'?"; then
  gum style --foreground 196 "❌ Operation cancelled."
  exit 0
fi

# --- Step 5: Execution Logic ---
COMMAND_TO_RUN=""
SPINNER_TITLE=""

case "$ACTION" in
"Refresh Repositories (pacman -Sy)")
  SPINNER_TITLE="Refreshing package lists..."
  # Use an array to build the command safely
  COMMAND_TO_RUN=(sudo pacman -Sy)
  ;;
"Upgrade Official Packages (pacman -Syu)")
  SPINNER_TITLE="Upgrading system via pacman..."
  COMMAND_TO_RUN=(sudo pacman -Syu --noconfirm)
  ;;
"Upgrade Official + AUR Packages ($AUR_HELPER)")
  SPINNER_TITLE="Upgrading system and AUR packages via $AUR_HELPER..."
  # AUR helpers handle both official and AUR packages
  COMMAND_TO_RUN=("$AUR_HELPER" -Syu --noconfirm)
  ;;
esac

# Execute the chosen command with a spinner
gum spin --spinner line --title "$SPINNER_TITLE" -- \
  "${COMMAND_TO_RUN[@]}"

# --- Step 6: Final status ---
if [[ $? -ne 0 ]]; then
  gum style --foreground 196 --bold "❌ An error occurred during the operation."
  exit 1
fi

gum style --foreground 82 --bold "✅ System is up to date!"
