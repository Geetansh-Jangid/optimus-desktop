#!/usr/bin/env bash
# =======================================================
# 🌐 Optimus Desktop :: Code Editor Installation (Gum)
# =======================================================
set -euo pipefail

# --- Require gum ---
if ! command -v gum &>/dev/null; then
  echo "❌ gum not found. Please install it first (sudo pacman -S gum)."
  exit 1
fi

# --- Helper Function: Detect available AUR helper ---
detect_aur_helper() {
  if command -v paru &>/dev/null; then
    echo "paru"
  elif command -v yay &>/dev/null; then
    echo "yay"
  else
    echo ""
  fi
}

# --- Header ---
gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Code Editor Selection" \
  "──────────────────────────────────────────" \
  "Select your preferred code editor to install."

# -------------------------------------------------------------------------
# ---- Define Options (with metadata) ----
# Format: "Description"="package_name:install_type:binary_name"
# install_type can be 'pacman' or 'aur'
# -------------------------------------------------------------------------
declare -A EDITORS=(
  ["Zed :: A high-performance, multiplayer code editor (Official Repo)"]="zed:pacman:zed"
  ["Visual Studio Code :: Microsoft's popular, feature-rich editor (AUR)"]="visual-studio-code-bin:aur:code"
  ["Neovim :: Powerful, keyboard-centric text editor (Official Repo)"]="nvim:pacman:nvim"
)

# Prepare choices array for gum choose
CHOICES=("${!EDITORS[@]}")

# -------------------------------------------------------------------------
# ---- User Choice ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Please select the editor you would like to install:"

SELECTED_DESC=$(gum choose \
  "${CHOICES[@]}" \
  --header "Select one:")

# If the user cancels the selection, exit gracefully
if [[ -z "$SELECTED_DESC" ]]; then
  gum style --foreground 240 "[INFO] No editor selected. Exiting."
  exit 0
fi

# --- Parse the selected editor's metadata ---
EDITOR_DATA="${EDITORS[$SELECTED_DESC]}"
IFS=':' read -r PACKAGE_TO_INSTALL INSTALL_TYPE BINARY_NAME <<<"$EDITOR_DATA"

gum style --foreground 212 "[INFO] Selected package: $PACKAGE_TO_INSTALL"

if ! gum confirm "Proceed to install $PACKAGE_TO_INSTALL?"; then
  gum style --foreground 240 "[INFO] Installation canceled."
  exit 0
fi

# -------------------------------------------------------------------------
# ---- Installation ----
# -------------------------------------------------------------------------
INSTALL_CMD=""
AUR_HELPER=$(detect_aur_helper)

if [[ "$INSTALL_TYPE" == "aur" ]]; then
  if [[ -n "$AUR_HELPER" ]]; then
    INSTALL_CMD="$AUR_HELPER -S --needed --noconfirm"
    gum style --foreground 45 "[NOTE] Using '$AUR_HELPER' as AUR helper for '$PACKAGE_TO_INSTALL'."
  else
    gum style --foreground 196 "❌ ERROR: '$PACKAGE_TO_INSTALL' is an AUR package, but no AUR helper (paru/yay) was found."
    gum style --foreground 208 "Please run the 'aur-helper.sh' module first."
    exit 1
  fi
elif [[ "$INSTALL_TYPE" == "pacman" ]]; then
  INSTALL_CMD="sudo pacman -S --needed --noconfirm"
else
  gum style --foreground 196 "❌ ERROR: Unknown installation type '$INSTALL_TYPE' for package '$PACKAGE_TO_INSTALL'."
  exit 1
fi

gum style --foreground 45 "[INFO] Starting installation..."

# Pre-cache sudo if needed, to prevent getting stuck in the spinner
if [[ "$INSTALL_TYPE" == "pacman" ]]; then
  sudo -v
fi

gum spin --spinner line --title "Installing $PACKAGE_TO_INSTALL..." -- \
  bash -c "$INSTALL_CMD '$PACKAGE_TO_INSTALL'"

# -------------------------------------------------------------------------
# ---- Final Verification ----
# -------------------------------------------------------------------------
if command -v "$BINARY_NAME" &>/dev/null; then
  gum style --foreground 82 --bold "✅ Successfully installed $PACKAGE_TO_INSTALL!"
  gum style --foreground 240 "You can now launch it by running '$BINARY_NAME'."
else
  gum style --foreground 196 "❌ Installation of $PACKAGE_TO_INSTALL failed or its command '$BINARY_NAME' was not found."
  exit 1
fi
