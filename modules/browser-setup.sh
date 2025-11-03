#!/bin/bash

# --- Auto-detect AUR Helper ---
AUR_HELPER=""
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
fi

if [[ -z "$AUR_HELPER" ]]; then
  gum style --foreground 196 "❌ No AUR helper (paru or yay) found. Please install one first."
  exit 1
fi
gum style --foreground 82 "[OK] Detected AUR Helper: $AUR_HELPER"

# --- Step 1: Choose the browsers to install ---
gum style --foreground 212 --bold --margin "1 0" \
  "Please choose the browser(s) you wish to install." \
  "Use <space> to select, <enter> to confirm."

BROWSERS=$(gum choose --no-limit \
  "firefox" \
  "zen-browser-bin" \
  "brave-bin" \
  "ungoogled-chromium-bin" \
  "helium-bin" \
  "librewolf")

if [[ -z "$BROWSERS" ]]; then
  gum style --foreground 196 "❌ No browser selected. Exiting."
  exit 1
fi

# --- Step 2: Choose Installation Source ---
SOURCE_CHOICE=$(gum choose --cursor "👉 " \
  "Chaotic AUR (Prebuilt binaries)" \
  "AUR Helper ($AUR_HELPER)" \
  --header "Choose an installation source for the selected browser(s):")

# --- Step 3: Confirm & Proceed ---
# Use 'gum join' to display the selected browsers in a formatted list for confirmation
gum style --border normal --padding "1 2" --margin "1 0" \
  "You are about to install:" \
  "$(gum join --vertical --align left -- "$BROWSERS")"

if ! gum confirm "🚀 Ready to install using ${SOURCE_CHOICE%% *}? Continue?"; then
  gum style --foreground 196 "❌ Installation cancelled."
  exit 0
fi

# --- Step 4: Preload sudo credentials cleanly ---
gum style --foreground 244 "🔑 Checking sudo access (you may be prompted for your password)..."
sudo -v

# --- Step 5: Installation Logic ---
# Note: The $BROWSERS variable is intentionally unquoted to allow the shell
# to split the newline-separated list into multiple arguments for the command.
if [[ "$SOURCE_CHOICE" == "Chaotic AUR (Prebuilt binaries)" ]]; then
  gum style --foreground 45 "Installing selected browsers via Chaotic AUR..."
  sudo pacman -S --noconfirm $BROWSERS
else
  gum style --foreground 45 "Installing selected browsers via $AUR_HELPER..."
  "$AUR_HELPER" -S --noconfirm $BROWSERS
fi

# --- Step 6: Check for errors ---
if [[ $? -ne 0 ]]; then
  gum style --foreground 196 --bold "❌ An error occurred during the installation."
  exit 1
fi

# --- Done ---
gum style --foreground 82 --bold "✅ Installation complete!"
gum style --foreground 244 "You can now launch your new browser(s) from the applications menu."
