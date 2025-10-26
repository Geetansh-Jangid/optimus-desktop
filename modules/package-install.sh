#!/usr/bin/env bash
# ==============================================
# Optimus Desktop: Package Installer
# ==============================================
set -euo pipefail

DATA_DIR="$(dirname "$0")/../data"
PACMAN_FILE="$DATA_DIR/packages-pacman.txt"
AUR_FILE="$DATA_DIR/packages-aur.txt"
LOG_FILE="$DATA_DIR/install-log-$(date +%Y%m%d-%H%M%S).txt"

echo "⚙️  ==== Optimus Desktop :: System Package Installer ===="

# ---- Check for data files ----
if [[ ! -f "$PACMAN_FILE" || ! -f "$AUR_FILE" ]]; then
  echo "❌ Package list files not found in $DATA_DIR"
  echo "   Please run 'scripts/package-export.sh' first."
  exit 1
fi

# ---- Detect AUR helper ----
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
elif command -v trizen &>/dev/null; then
  AUR_HELPER="trizen"
else
  AUR_HELPER=""
fi

if [[ -z "$AUR_HELPER" ]]; then
  echo "⚠️  No AUR helper detected!"
  echo "   Please install one (e.g., paru) using 'scripts/paru-setup.sh'."
  exit 1
fi

# ---- Confirm action ----
echo "📦 Found package lists:"
echo "   • Repo packages: $(wc -l <"$PACMAN_FILE")"
echo "   • AUR packages:  $(wc -l <"$AUR_FILE")"
read -rp "❯ Proceed to install all packages? [Y/n]: " ans
ans=${ans,,}
[[ $ans == "n" ]] && echo "❌ Installation aborted." && exit 0

# ---- Install official repo packages ----
echo "🚀 Installing repo packages..."
sudo pacman -Syu --needed --noconfirm - <"$PACMAN_FILE" | tee -a "$LOG_FILE" || true

# ---- Install AUR packages ----
echo "🌐 Installing AUR packages via $AUR_HELPER..."
"$AUR_HELPER" -S --needed --noconfirm - <"$AUR_FILE" | tee -a "$LOG_FILE" || true

# ---- Post-install summary ----
echo
echo "✅ All packages processed."
echo "🧾 Log saved at: $LOG_FILE"
