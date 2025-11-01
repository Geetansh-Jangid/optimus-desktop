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

# --- Step 1: Ask for the browser to install ---
gum style --foreground 212 --bold --margin "1 0" "Please specify the browser you wish to install."
BROWSER=$(gum input --placeholder "e.g., brave-bin, vivaldi, librewolf, ...")

if [[ -z "$BROWSER" ]]; then
  gum style --foreground 196 "❌ No browser package name entered. Exiting."
  exit 1
fi

# --- Step 2: Choose Installation Source ---
SOURCE_CHOICE=$(gum choose --cursor "👉 " \
  "Chaotic AUR (Prebuilt binaries)" \
  "AUR Helper ($AUR_HELPER)" \
  --header "Choose an installation source for '$BROWSER':")

# --- Step 3: Confirm & Proceed ---
if ! gum confirm "🚀 Ready to install '$BROWSER' using ${SOURCE_CHOICE%% *}? Continue?"; then
  gum style --foreground 196 "❌ Installation cancelled."
  exit 0
fi

# --- Step 4: Preload sudo credentials cleanly ---
gum style --foreground 244 "🔑 Checking sudo access (you may be prompted for your password)..."
sudo -v

# --- Step 5: Installation Logic ---
if [[ "$SOURCE_CHOICE" == "Chaotic AUR (Prebuilt binaries)" ]]; then
  gum style --foreground 45 "Installing '$BROWSER' via Chaotic AUR..."
  sudo pacman -S --noconfirm "$BROWSER"
else
  gum style --foreground 45 "Installing '$BROWSER' via $AUR_HELPER..."
  "$AUR_HELPER" -S --noconfirm "$BROWSER"
fi

# --- Step 6: Check for errors ---
if [[ $? -ne 0 ]]; then
  gum style --foreground 196 --bold "❌ An error occurred during the installation of '$BROWSER'."
  exit 1
fi

# --- Done ---
gum style --foreground 82 --bold "✅ '$BROWSER' installed successfully!"
gum style --foreground 244 "You can now launch it from your applications menu."
