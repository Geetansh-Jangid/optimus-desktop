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

# --- Header ---
gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Code Editor Selection" \
  "──────────────────────────────────────────" \
  "Select your preferred code editor to install (using pacman/aur)."

# -------------------------------------------------------------------------
# ---- Define Options ----
# -------------------------------------------------------------------------
# Map descriptive name to the actual Arch/AUR package name
declare -A EDITORS=(
  ["zed :: High-performance, collaborative editor (pacman)"]="zed"
  ["visual-studio-code-bin :: Microsoft's popular, feature-rich editor (AUR)"]="visual-studio-code-bin"
  ["nvim :: Powerful, keyboard-centric text editor (Official Repo)"]="nvim"
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

# Extract the package name from the associative array
# The actual package name is the value associated with the descriptive key
PACKAGE_TO_INSTALL="${EDITORS["$SELECTED_DESC"]}"

gum style --foreground 212 "[INFO] Selected package: $PACKAGE_TO_INSTALL"

if ! gum confirm "Proceed to install $PACKAGE_TO_INSTALL?"; then
  gum style --foreground 240 "[INFO] Installation canceled."
  exit 0
fi

# -------------------------------------------------------------------------
# ---- Installation ----
# -------------------------------------------------------------------------

# Installation command check
INSTALL_CMD="sudo pacman -S --needed --noconfirm"

# If the package is an AUR package, we need an AUR helper (assuming 'paru' is available)
if [[ "$PACKAGE_TO_INSTALL" == *"bin"* ]]; then
  if command -v paru &>/dev/null; then
    INSTALL_CMD="paru -S --needed --noconfirm"
    gum style --foreground 45 "[NOTE] Using 'paru' as AUR helper for '$PACKAGE_TO_INSTALL'."
  else
    gum style --foreground 196 "❌ ERROR: '$PACKAGE_TO_INSTALL' is an AUR package, but 'paru' (or similar helper) was not found."
    gum style --foreground 208 "Please install an AUR helper first, or manually install '$PACKAGE_TO_INSTALL'."
    exit 1
  fi
fi

gum style --foreground 45 "[INFO] Starting installation..."

gum spin --spinner line --title "Installing $PACKAGE_TO_INSTALL..." -- \
  bash -c "$INSTALL_CMD '$PACKAGE_TO_INSTALL'"

# -------------------------------------------------------------------------
# ---- Final Verification ----
# -------------------------------------------------------------------------

# Remove the '-bin' suffix for the final verification check if necessary
BIN_NAME="${PACKAGE_TO_INSTALL//-bin/}"

if command -v "$BIN_NAME" &>/dev/null || command -v code &>/dev/null || command -v nvim &>/dev/null; then
  gum style --foreground 82 --bold "✅ Successfully installed $PACKAGE_TO_INSTALL!"
  gum style --foreground 240 "You can now launch it."
else
  gum style --foreground 196 "❌ Installation of $PACKAGE_TO_INSTALL failed or binary not found."
  exit 1
fi
