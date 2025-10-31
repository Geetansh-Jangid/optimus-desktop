#!/usr/bin/env bash
# ===========================================
# Optimus Desktop: Browser Installer (GUM Edition)
# ===========================================
# Supports Zen Browser & Brave Browser
# Detects AUR helper (paru/yay) and installs using
# either Chaotic AUR or user's AUR helper.
# ===========================================

set -euo pipefail

# --- Header ---
echo "🌐 Optimus Desktop :: Browser Installer" | gum style --foreground 212 --bold
echo "------------------------------------------" | gum style --foreground 250

# --- Detect AUR Helper ---
detect_aur_helper() {
  if command -v paru &>/dev/null; then
    echo "paru"
  elif command -v yay &>/dev/null; then
    echo "yay"
  else
    echo ""
  fi
}

AUR_HELPER=$(detect_aur_helper)

if [[ -z "$AUR_HELPER" ]]; then
  echo "[ERROR] No AUR helper found (paru or yay)." | gum style --foreground 9 --bold
  echo "Please install one first, then re-run this script." | gum style --foreground 11
  exit 1
fi

# --- Choose Browser ---
BROWSER_CHOICE=$(gum choose --cursor "👉 " "Zen Browser" "Brave Browser" --header "Choose your browser:")

case "$BROWSER_CHOICE" in
"Zen Browser") BROWSER="zen-browser-bin" ;;
"Brave Browser") BROWSER="brave-bin" ;;
esac

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
