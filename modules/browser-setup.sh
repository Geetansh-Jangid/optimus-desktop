#!/bin/bash

# Assume AUR_HELPER and BROWSER variables are set earlier in the script
# Example values:
# AUR_HELPER="yay"
# BROWSER="firefox"

# --- Choose Installation Source ---
SOURCE_CHOICE=$(gum choose --cursor "👉 " \
  "Chaotic AUR (Prebuilt binaries)" \
  "AUR Helper ($AUR_HELPER)" \
  --header "Choose installation source:")

# --- Confirm & Proceed ---
if ! gum confirm "🚀 Ready to install $BROWSER using ${SOURCE_CHOICE%% *}? Continue?"; then
  gum style --foreground 196 "❌ Installation cancelled."
  exit 0
fi

# --- Preload sudo credentials cleanly ---
gum style --foreground 244 "🔑 Checking sudo access (you may be prompted for your password)..."
sudo -v

# --- Installation Logic ---
if [[ "$SOURCE_CHOICE" == "Chaotic AUR (Prebuilt binaries)" ]]; then
  gum style --foreground 45 "Installing $BROWSER via Chaotic AUR..."
  sudo pacman -S --noconfirm "$BROWSER"
else
  gum style --foreground 45 "Installing $BROWSER via $AUR_HELPER..."
  "$AUR_HELPER" -S --noconfirm "$BROWSER"
fi

# --- Check for errors ---
if [[ $? -ne 0 ]]; then
  gum style --foreground 196 --bold "❌ An error occurred during installation."
  exit 1
fi

# --- Done ---
gum style --foreground 82 --bold "✅ $BROWSER installed successfully!"
gum style --foreground 244 "You can now launch it from your applications menu."

# --- Choose Installation Source ---
SOURCE_CHOICE=$(gum choose --cursor "👉 " \
  "Chaotic AUR (Prebuilt binaries)" \
  "AUR Helper ($AUR_HELPER)" \
  --header "Choose installation source:")

# --- Confirm & Proceed ---
gum confirm "🚀 Ready to install $BROWSER using ${SOURCE_CHOICE%% *}? Continue?" || {
  echo "❌ Installation cancelled." | gum style --foreground 11
  exit 0
}

# --- Preload sudo credentials cleanly ---
echo "🔑 Checking sudo access (you may be prompted for password)..." | gum style --foreground 244
sudo -v

# --- Installation Spinner ---
if [[ "$SOURCE_CHOICE" == "Chaotic AUR (Prebuilt binaries)" ]]; then
  gum spin --spinner line --title "Installing $BROWSER via Chaotic AUR..." -- \
    bash -c "sudo pacman -S --noconfirm $BROWSER"
else
  gum spin --spinner line --title "Installing $BROWSER via $AUR_HELPER..." -- \
    bash -c "$AUR_HELPER -S --noconfirm $BROWSER"
fi

# --- Done ---
echo "✅ $BROWSER installed successfully!" | gum style --foreground 10 --bold
echo "You can now launch it from your applications menu." | gum style --foreground 244
