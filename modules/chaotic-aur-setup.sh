#!/usr/bin/env bash
# ==============================================
# Optimus Desktop: Chaotic-AUR Mirror Setup
# ==============================================
set -euo pipefail

echo "🔍 Checking system requirements..."
for pkg in sudo pacman curl; do
  if ! command -v "$pkg" &>/dev/null; then
    echo "❌ Missing dependency: $pkg"
    read -rp "➡️  Install $pkg now? [Y/n] " ans
    ans=${ans,,}
    if [[ $ans != "n" ]]; then
      sudo pacman -Sy --needed --noconfirm "$pkg"
    else
      echo "⚠️  $pkg is required. Exiting."
      exit 1
    fi
  fi
done

# Check if already configured
if grep -q "chaotic-aur" /etc/pacman.conf; then
  echo "✅ Chaotic-AUR repo already configured."
  exit 0
fi

echo "Chaotic-AUR helps you to install famous AUR packages without building them by yourself : https://aur.chaotic.cx/"
read -rp "➡️  Proceed to install Chaotic-AUR? [Y/n] " ans
ans=${ans,,}
[[ $ans == "n" ]] && echo "❌ Skipped Chaotic-AUR setup." && exit 0
echo "🌀 Setting up Chaotic-AUR mirrorlist..."

# ---- Import key ----
echo "🔑 Importing Chaotic-AUR key..."
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

# ---- Install keyring and mirrorlist ----
echo "📦 Installing keyring and mirrorlist..."
sudo pacman -U --noconfirm \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U --noconfirm \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# ---- Add repo if not exists ----
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
  echo "📝 Adding [chaotic-aur] repository to pacman.conf..."
  echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" |
    sudo tee -a /etc/pacman.conf >/dev/null
fi

# ---- Refresh databases ----
echo "🔄 Refreshing package databases..."
sudo pacman -Syy

echo "✅ Chaotic-AUR setup complete!"
