#!/usr/bin/env bash
# ==============================================
# Optimus Desktop: Chaotic-AUR Mirror Setup
# ==============================================
set -e

echo "🔍 Checking system requirements..."
for pkg in sudo pacman curl; do
  if ! command -v "$pkg" &>/dev/null; then
    echo "❌ Missing dependency: $pkg"
    read -p "➡️  Install $pkg now? [Y/n] " ans
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

echo "🌀 Setting up Chaotic-AUR mirrorlist..."
read -p "➡️  Proceed to install Chaotic-AUR? [Y/n] " ans
ans=${ans,,}
[[ $ans == "n" ]] && echo "❌ Skipped Chaotic-AUR setup." && exit 0

# Import key
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

# Install mirrorlist
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'# Add repo if not exists

if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
  echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
fi

# Refresh databases
echo "🔄 Refreshing package databases..."
sudo pacman -Syy

echo "✅ Chaotic-AUR setup complete!"
