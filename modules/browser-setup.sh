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

BROWSERS_SELECTED=$(gum choose --no-limit \
  "firefox" \
  "librewolf" \
  "brave-bin" \
  "ungoogled-chromium-bin" \
  "zen-browser-bin" \
  "helium-bin")

if [[ -z "$BROWSERS_SELECTED" ]]; then
  gum style --foreground 196 "❌ No browser selected. Exiting."
  exit 1
fi

# --- Step 2: Sort browsers by installation source ---
PACMAN_PKGS=()
AUR_PKGS=()

# Read the newline-separated string from gum into an array
mapfile -t BROWSER_ARRAY <<<"$BROWSERS_SELECTED"

for browser in "${BROWSER_ARRAY[@]}"; do
  case "$browser" in
  firefox | librewolf)
    PACMAN_PKGS+=("$browser")
    ;;
  brave-bin | helium-bin | zen-browser-bin | ungoogled-chromium-bin)
    AUR_PKGS+=("$browser")
    ;;
  esac
done

# --- Step 3: Confirm & Proceed ---
gum style --border normal --padding "1 2" --margin "1 0" \
  --border-foreground 212 "Installation Plan"

if ((${#PACMAN_PKGS[@]})); then
  gum style --foreground 45 "Official Repositories (pacman):"
  gum join --vertical --align left -- "${PACMAN_PKGS[@]}"
fi

if ((${#AUR_PKGS[@]})); then
  gum style --foreground 159 "AUR ($AUR_HELPER):"
  gum join --vertical --align left -- "${AUR_PKGS[@]}"
fi

if ! gum confirm "🚀 Ready to proceed with the installation plan?"; then
  gum style --foreground 196 "❌ Installation cancelled."
  exit 0
fi

# --- Step 4: Preload sudo credentials cleanly ---
gum style --foreground 244 "🔑 Checking sudo access (you may be prompted for your password)..."
sudo -v

# --- Step 5: Installation Logic ---
INSTALL_FAILED=false

# Install packages from official repositories if any were selected
if ((${#PACMAN_PKGS[@]})); then
  gum style --foreground 45 "Installing from official repositories..."
  if ! sudo pacman -S --noconfirm "${PACMAN_PKGS[@]}"; then
    gum style --foreground 196 "❌ Failed to install packages with pacman."
    INSTALL_FAILED=true
  fi
fi

# Install packages from AUR if any were selected
if ((${#AUR_PKGS[@]})); then
  gum style --foreground 159 "Installing from the AUR with $AUR_HELPER..."
  if ! "$AUR_HELPER" -S --noconfirm "${AUR_PKGS[@]}"; then
    gum style --foreground 196 "❌ Failed to install packages with $AUR_HELPER."
    INSTALL_FAILED=true
  fi
fi

# --- Step 6: Final status ---
if [[ "$INSTALL_FAILED" == true ]]; then
  gum style --foreground 196 --bold "❌ One or more installations failed. Please review the output above."
  exit 1
fi

gum style --foreground 82 --bold "✅ Installation complete!"
gum style --foreground 244 "You can now launch your new browser(s) from the applications menu."
