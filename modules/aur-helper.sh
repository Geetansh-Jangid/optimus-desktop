#!/usr/bin/env bash
# ==============================================
# Optimus Desktop: AUR Helper (Paru) Setup
# ==============================================
set -euo pipefail

echo "[INFO] ==== Optimus Desktop :: AUR Helper Setup ===="

# ---- Check Dependencies ----
echo "[INFO] Checking required dependencies..."
DEPS=(base-devel git sudo curl)
MISSING=()

for pkg in "${DEPS[@]}"; do
  if ! command -v "$pkg" &>/dev/null && ! pacman -Qi "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
  fi
done

if ((${#MISSING[@]})); then
  echo "[WARN] Missing packages: ${MISSING[*]}"
  read -rp "Install them now? [Y/n]: " ans
  ans=${ans,,}
  if [[ $ans != "n" ]]; then
    sudo pacman -S --needed --noconfirm "${MISSING[@]}"
  else
    echo "[ERROR] Cannot continue without dependencies."
    exit 1
  fi
else
  echo "[OK] All dependencies satisfied."
fi

# ---- Check if paru already exists ----
if command -v paru &>/dev/null; then
  echo "[OK] Paru already installed: $(paru --version | head -n1)"
  exit 0
fi

# ---- Confirm install ----
read -rp "❯ Proceed to install paru (paru)? [Y/n]: " ans
ans=${ans,,}
[[ $ans == "n" ]] && echo "[INFO] Skipping paru installation." && exit 0

# ---- Build paru from AUR ----
echo "[INFO] Installing paru..."
cd /tmp || exit 1
rm -rf paru-bin
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si --noconfirm

# ---- Verify ----
if command -v paru &>/dev/null; then
  echo "[OK] Paru successfully installed: $(paru --version | head -n1)"
else
  echo "[ERROR] Paru installation failed."
  exit 1
fi
