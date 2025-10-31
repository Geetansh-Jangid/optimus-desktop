#!/usr/bin/env bash
# ==============================================
# 🌐 Optimus Desktop :: Chaotic-AUR Mirror Setup
# ==============================================
set -euo pipefail

# --- Require gum ---
if ! command -v gum &>/dev/null; then
  echo "❌ gum not found. Please install it first (sudo pacman -S gum)."
  exit 1
fi

gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Chaotic-AUR Mirror Setup" \
  "────────────────────────────────────────────" \
  "Adds the Chaotic-AUR repository for pre-built packages."

# -------------------------------------------------------------------------
# ---- Check Dependencies (using gum spin for installation) ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Checking required dependencies..."
DEPS=(sudo pacman curl)
MISSING=()

for pkg in "${DEPS[@]}"; do
  if ! command -v "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
  fi
done

if ((${#MISSING[@]})); then
  gum style --foreground 208 "⚠ Missing required packages: ${MISSING[*]}"
  if gum confirm "Install them now?"; then
    gum spin --spinner line --title "Installing dependencies..." -- \
      sudo pacman -Sy --needed --noconfirm "${MISSING[@]}"
    gum style --foreground 82 "✔ Dependencies installed successfully."
  else
    gum style --foreground 196 "❌ Required dependencies are missing. Exiting."
    exit 1
  fi
else
  gum style --foreground 82 "[OK] All dependencies satisfied."
fi

# -------------------------------------------------------------------------
# ---- Check if already configured ----
# -------------------------------------------------------------------------
if grep -q "chaotic-aur" /etc/pacman.conf; then
  gum style --foreground 82 "✅ Chaotic-AUR repo already configured."
  exit 0
fi

# -------------------------------------------------------------------------
# ---- User Confirmation (FIXED: Removed --header flag) ----
# -------------------------------------------------------------------------
CHOICE_PROMPT="Chaotic-AUR Setup\nChaotic-AUR allows you to install popular AUR packages without building them yourself.\nDo you want to proceed with the installation?"

if ! gum confirm "$CHOICE_PROMPT" --default=true --prompt.foreground 45; then
  gum style --foreground 240 "❌ Skipped Chaotic-AUR setup."
  exit 0
fi

gum style --foreground 45 "[INFO] Setting up Chaotic-AUR mirrorlist..."

# -------------------------------------------------------------------------
# ---- Import key ----
# -------------------------------------------------------------------------
gum spin --spinner dot --title "🔑 Importing Chaotic-AUR key (3056513887B78AEB)..." -- \
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com

gum spin --spinner dot --title "✍️ Signing key locally..." -- \
  sudo pacman-key --lsign-key 3056513887B78AEB

# -------------------------------------------------------------------------
# ---- Install keyring and mirrorlist ----
# -------------------------------------------------------------------------
gum spin --spinner line --title "📦 Installing keyring and mirrorlist packages..." -- \
  bash -c "sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'"

# -------------------------------------------------------------------------
# ---- Add repo if not exists ----
# -------------------------------------------------------------------------
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
  gum spin --spinner minidot --title "📝 Adding [chaotic-aur] repository to /etc/pacman.conf..." -- \
    bash -c "echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf >/dev/null"
fi

# -------------------------------------------------------------------------
# ---- Refresh databases ----
# -------------------------------------------------------------------------
gum spin --spinner globe --title "🔄 Refreshing package databases..." -- \
  sudo pacman -Syy

# -------------------------------------------------------------------------
# ---- Final Message ----
# -------------------------------------------------------------------------
gum style --foreground 82 --bold "✅ Chaotic-AUR setup complete! You can now install packages from the repository."
