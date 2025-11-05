#!/usr/bin/env bash
# =======================================================
# 🌐 Optimus Desktop :: Code Editor Installation (Multi)
# =======================================================
set -euo pipefail

# --- Initialize AUR_HELPER ---
AUR_HELPER=""

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
  "Select your preferred code editor(s) to install."

# -------------------------------------------------------------------------
# ---- Define Options ----
# Format: "Description"="package_name:install_type"
# -------------------------------------------------------------------------
declare -A EDITORS=(
  ["Visual Studio Code :: Microsoft's popular, feature-rich editor (AUR)"]="visual-studio-code-bin:aur"
  ["Neovim :: Powerful, keyboard-centric text editor (Official)"]="nvim:pacman"
  ["Geany :: Fast and lightweight IDE (Official)"]="geany:pacman"
  ["Vim :: The ubiquitous text editor (Official)"]="vim:pacman"
  ["Emacs :: An extensible, customizable, self-documenting text editor (Official)"]="emacs:pacman"
  ["Mousepad :: Simple and easy-to-use text editor for XFCE (Official)"]="mousepad:pacman"
)

# Prepare choices array for gum choose
CHOICES=("${!EDITORS[@]}")

# -------------------------------------------------------------------------
# ---- User Choice (Multiple selections allowed) ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Please select the editor(s) you would like to install:" \
  "Use <space> to select, <enter> to confirm."

SELECTED_DESCS=$(gum choose --no-limit \
  "${CHOICES[@]}" \
  --header "Select one or more editors:")

if [[ -z "$SELECTED_DESCS" ]]; then
  gum style --foreground 240 "[INFO] No editor selected. Exiting."
  exit 0
fi

# --- Sort selections by installation source ---
PACMAN_PKGS=()
AUR_PKGS=()

mapfile -t SELECTED_ARRAY <<<"$SELECTED_DESCS"

for desc in "${SELECTED_ARRAY[@]}"; do
  EDITOR_DATA="${EDITORS[$desc]}"
  IFS=':' read -r package install_type <<<"$EDITOR_DATA"

  if [[ "$install_type" == "pacman" ]]; then
    PACMAN_PKGS+=("$package")
  elif [[ "$install_type" == "aur" ]]; then
    AUR_PKGS+=("$package")
  fi
done

# --- Display plan and ask for final confirmation ---
gum style --border normal --padding "1 2" --margin "1 0" \
  --border-foreground 212 "Editor Installation Plan"

if ((${#PACMAN_PKGS[@]})); then
  gum style --foreground 45 "Official Repositories (pacman):"
  gum join --vertical --align left -- "${PACMAN_PKGS[@]}"
fi

if ((${#AUR_PKGS[@]})); then
  AUR_HELPER=$(detect_aur_helper)
  if [[ -z "$AUR_HELPER" ]]; then
    gum style --foreground 196 "❌ ERROR: AUR packages selected, but no helper (paru/yay) was found."
    exit 1
  fi
  gum style --foreground 159 "AUR ($AUR_HELPER):"
  gum join --vertical --align left -- "${AUR_PKGS[@]}"
fi

if ! gum confirm "Proceed to install the selected editors?"; then
  gum style --foreground 240 "[INFO] Installation canceled."
  exit 0
fi

# -------------------------------------------------------------------------
# ---- Installation Logic ----
# -------------------------------------------------------------------------
INSTALL_FAILED=false

# Install packages from official repositories
if ((${#PACMAN_PKGS[@]})); then
  gum style --border thick --margin "1 0" -- "--- Installing from Official Repositories ---"
  if ! sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"; then
    gum style --foreground 196 "❌ Failed to install packages with pacman."
    INSTALL_FAILED=true
  fi
fi

# Install packages from AUR
if [[ -n "$AUR_HELPER" ]] && ((${#AUR_PKGS[@]})) && [[ "$INSTALL_FAILED" == false ]]; then
  gum style --border thick --margin "1 0" -- "--- Installing from the AUR via $AUR_HELPER ---"
  if ! "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"; then
    gum style --foreground 196 "❌ Failed to install packages with $AUR_HELPER."
    INSTALL_FAILED=true
  fi
fi

# -------------------------------------------------------------------------
# ---- Final Verification ----
# -------------------------------------------------------------------------
if [[ "$INSTALL_FAILED" == true ]]; then
  gum style --foreground 196 --bold "❌ One or more editor installations failed. Please review the output above."
  exit 1
fi

gum style --foreground 82 --bold "✅ Successfully installed all selected editors!"
gum style --foreground 240 "You can now launch them from your applications menu."
