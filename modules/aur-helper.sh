#!/usr/bin/env bash
# ===========================================
# Optimus Desktop: AUR Helper (Paru/Yay) Setup (bin versions)
# ===========================================
set -euo pipefail

echo "[INFO] ==== Optimus Desktop :: AUR Helper Setup (bin) ===="

# ---- Check Dependencies ----
echo "[INFO] Checking required dependencies..."
DEPS=(base-devel git sudo curl)
MISSING=()

is_installed() {
  local pkg=$1
  command -v "$pkg" &>/dev/null || pacman -Qi "$pkg" &>/dev/null
}

for pkg in "${DEPS[@]}"; do
  if ! is_installed "$pkg"; then
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

# -------------------------------------------------------------------------
# ---- Check if AUR helper already installed ----
# -------------------------------------------------------------------------

AUR_HELPERS=(paru paru-bin yay yay-bin)

for helper in "${AUR_HELPERS[@]}"; do
  if command -v "$helper" &>/dev/null; then
    local_cmd="${helper%-bin}"
    echo "[OK] AUR helper '$helper' already installed: $("$local_cmd" --version | head -n1)"
    exit 0
  fi
done

# -------------------------------------------------------------------------
# ---- User Choice ----
# -------------------------------------------------------------------------

echo
echo "Which AUR helper would you like to install (bin version)?"
echo "1) paru-bin (Rust-based, lightweight)"
echo "2) yay-bin (Go-based, stable)"

CHOICE=""
while true; do
  read -rp "❯ Enter your choice (1 or 2): " choice_num
  case "$choice_num" in
  1)
    CHOICE="paru-bin"
    break
    ;;
  2)
    CHOICE="yay-bin"
    break
    ;;
  *) echo "[ERROR] Invalid choice. Please enter '1' or '2'." ;;
  esac
done

echo "[INFO] Selected helper: $CHOICE"

read -rp "❯ Proceed to install $CHOICE? [Y/n]: " ans
ans=${ans,,}
[[ $ans == "n" ]] && echo "[INFO] Installation canceled." && exit 0

# -------------------------------------------------------------------------
# ---- Install from AUR manually ----
# -------------------------------------------------------------------------

echo "[INFO] Installing $CHOICE from AUR..."

BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

REPO_URL="https://aur.archlinux.org/${CHOICE}.git"

echo "[INFO] Cloning $CHOICE repository..."
git clone "$REPO_URL" "$BUILD_DIR/$CHOICE"

echo "[INFO] Building and installing $CHOICE..."
(
  cd "$BUILD_DIR/$CHOICE"
  makepkg -si --noconfirm
)

# -------------------------------------------------------------------------
# ---- Final Verification ----
# -------------------------------------------------------------------------

BIN_NAME="${CHOICE%-bin}"

if command -v "$BIN_NAME" &>/dev/null; then
  echo "[SUCCESS] $CHOICE successfully installed! 🎉"
  "$BIN_NAME" --version | head -n1
else
  echo "[ERROR] $CHOICE failed to install."
  exit 1
fi
