#!/usr/bin/env bash
# ===========================================
# 🌐 Optimus Desktop :: AUR Helper Setup (yay-bin)
# ===========================================
set -euo pipefail

gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: AUR Helper Setup (yay-bin)" \
  "──────────────────────────────────────────────" \
  "Installs yay-bin, a popular AUR helper ✨"

# -------------------------------------------------------------------------
# ---- Check Dependencies ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Checking required dependencies..."
DEPS=(base-devel git sudo curl)
MISSING=()

is_installed() {
  local pkg=$1
  # Check command existence (for git, sudo, curl) or pacman database (for base-devel)
  command -v "$pkg" &>/dev/null || pacman -Qi "$pkg" &>/dev/null
}

for pkg in "${DEPS[@]}"; do
  if ! is_installed "$pkg"; then
    MISSING+=("$pkg")
  fi
done

if ((${#MISSING[@]})); then
  gum style --foreground 208 "⚠ Missing packages: ${MISSING[*]}"
  if gum confirm "Install them now?"; then
    gum spin --spinner line --title "Installing dependencies..." -- \
      sudo pacman -S --needed --noconfirm "${MISSING[@]}"
    gum style --foreground 82 "✔ Dependencies installed successfully."
  else
    gum style --foreground 196 "❌ Cannot continue without dependencies."
    exit 1
  fi
else
  gum style --foreground 82 "[OK] All dependencies satisfied."
fi

# -------------------------------------------------------------------------
# ---- Check if yay is already installed ----
# -------------------------------------------------------------------------
if command -v "yay" &>/dev/null; then
  version=$(yay --version 2>/dev/null | head -n1)
  gum style --foreground 82 "✔ AUR helper 'yay' already installed: $version"
  exit 0
fi

# -------------------------------------------------------------------------
# ---- Confirmation ----
# -------------------------------------------------------------------------
if ! gum confirm "Proceed to install yay-bin?"; then
  gum style --foreground 240 "[INFO] Installation canceled."
  exit 0
fi

# -------------------------------------------------------------------------
# ---- Install yay-bin from AUR manually ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Installing yay-bin from AUR..."
CHOICE="yay-bin"

# Create temp directory first (outside of gum spin)
BUILD_DIR=$(mktemp -d)
# Ensure the temporary directory is cleaned up on exit or interruption
trap 'rm -rf "$BUILD_DIR"' EXIT
gum style --foreground 240 "[OK] Temporary build directory created: $BUILD_DIR"

REPO_URL="https://aur.archlinux.org/${CHOICE}.git"
PACKAGE_DIR="$BUILD_DIR/$CHOICE"

# 1. Cloning the repository
gum spin --spinner line --title "Cloning $CHOICE from AUR..." -- \
  git clone "$REPO_URL" "$PACKAGE_DIR"

# 2. Building and Installing
# NOTE: makepkg -si requires sudo access (for -i) which will prompt for a
# password. This should be run outside of gum spin to allow for interactive input.
gum style --foreground 45 "[INFO] Building and installing $CHOICE (sudo required)..."

# Run the makepkg command inside a subshell so 'cd' does not affect the main script
if ! (cd "$PACKAGE_DIR" && makepkg -si --noconfirm); then
  gum style --foreground 196 "❌ Installation of $CHOICE failed during makepkg."
  exit 1
fi

# -------------------------------------------------------------------------
# ---- Final Verification ----
# -------------------------------------------------------------------------
BIN_NAME="yay"
if command -v "$BIN_NAME" &>/dev/null; then
  version=$("$BIN_NAME" --version 2>/dev/null | head -n1)
  gum style --foreground 82 "✨ Success! '$BIN_NAME' is installed and working: $version"
  exit 0
else
  gum style --foreground 196 "❌ Installation failed: '$BIN_NAME' command not found."
  exit 1
fi
