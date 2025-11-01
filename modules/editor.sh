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
# ---- Define Options (with corrected metadata) ----
# Format: "Description"="package_name:install_type:binary_name"
# ❗ FIXED: Zed is now correctly identified as an official 'pacman' package
# from the [extra] repository.
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
# ---- Installation (with conditional spinner logic) ----
# -------------------------------------------------------------------------
INSTALL_SUCCESS=false

if [[ "$INSTALL_TYPE" == "aur" ]]; then
  AUR_HELPER=$(detect_aur_helper)
  if [[ -n "$AUR_HELPER" ]]; then
    gum style --foreground 45 "[NOTE] Using '$AUR_HELPER' for AUR installation..."
    # A spinner is appropriate here because AUR builds can be slow.
    if gum spin --spinner line --title "Installing $PACKAGE_TO_INSTALL via $AUR_HELPER..." -- \
      "$AUR_HELPER" -S --needed --noconfirm "$PACKAGE_TO_INSTALL"; then
      INSTALL_SUCCESS=true
    fi
  else
    gum style --foreground 196 "❌ ERROR: '$PACKAGE_TO_INSTALL' is an AUR package, but no AUR helper (paru/yay) was found."
    exit 1
  fi

elif [[ "$INSTALL_TYPE" == "pacman" ]]; then
  gum style --foreground 45 "[INFO] Running pacman. You will see the live output below."
  echo # Add a newline for cleaner separation

  # --- NO SPINNER for pacman ---
  # We run pacman directly to show all its output: dependency lists,
  # download progress, and any potential errors. This provides full transparency.
  if sudo pacman -S --needed "$PACKAGE_TO_INSTALL"; then
    INSTALL_SUCCESS=true
  fi
else
  gum style --foreground 196 "❌ ERROR: Unknown installation type '$INSTALL_TYPE' for package '$PACKAGE_TO_INSTALL'."
  exit 1
fi

# -------------------------------------------------------------------------
# ---- Final Verification ----
# -------------------------------------------------------------------------
if [[ "$INSTALL_SUCCESS" = true ]] && command -v "$BINARY_NAME" &>/dev/null; then
  gum style --foreground 82 --bold "✅ Successfully installed $PACKAGE_TO_INSTALL!"
  gum style --foreground 240 "You can now launch it by running '$BINARY_NAME'."
else
  gum style --foreground 196 "❌ Installation of $PACKAGE_TO_INSTALL failed or its command '$BINARY_NAME' was not found."
  gum style --foreground 208 "Please review the output above for error messages."
  exit 1
fi
