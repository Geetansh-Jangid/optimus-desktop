#!/usr/bin/env bash
# ==============================================
# Optimus Desktop: AUR Helper (Paru/Yay) Setup
# ==============================================
set -euo pipefail

echo "[INFO] ==== Optimus Desktop :: AUR Helper Setup ===="

# ---- Check Dependencies ----
echo "[INFO] Checking required dependencies..."
# Dependencies are for building AUR packages, required for both Paru and Yay from source
DEPS=(base-devel git sudo curl)
MISSING=()

# Function to check if a package is installed (either via command or pacman query)
is_installed() {
  local pkg=$1
  # Check for command existence OR pacman installed package
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
# ---- Check if an AUR helper is already installed (including -bin versions)
# -------------------------------------------------------------------------

# Define the list of possible AUR helper commands to check
AUR_HELPERS=(paru paru-bin yay yay-bin)

for helper in "${AUR_HELPERS[@]}"; do
  if command -v "$helper" &>/dev/null; then
    # Use parameter expansion to remove the '-bin' suffix if present (e.g., paru-bin -> paru).
    # If the suffix is not present (e.g., paru), the result is just 'paru'.
    local_cmd="${helper%-bin}"

    # Check if the stripped command is available for a version check
    if command -v "$local_cmd" &>/dev/null; then
      echo "[OK] AUR helper '$helper' already installed: $("$local_cmd" --version | head -n1)"
    else
      echo "[OK] AUR helper '$helper' already installed."
    fi
    exit 0
  fi
done

# -------------------------------------------------------------------------
# ---- User Choice and Confirmation for Installation
# -------------------------------------------------------------------------

echo
echo "Which AUR helper would you like to install?"
echo "1) paru (Rust-based, newer)"
echo "2) yay (Go-based, well-established)"

# Loop until a valid choice is made
CHOICE=""
while true; do
  read -rp "❯ Enter your choice (1 or 2): " choice_num
  case "$choice_num" in
  1)
    CHOICE="paru"
    break
    ;;
  2)
    CHOICE="yay"
    break
    ;;
  *) echo "[ERROR] Invalid choice. Please enter '1' or '2'." ;;
  esac
done

echo "[INFO] You have selected to install: $CHOICE"

read -rp "❯ Proceed to install $CHOICE? [Y/n]: " ans
ans=${ans,,}
[[ $ans == "n" ]] && echo "[INFO] Skipping $CHOICE installation." && exit 0

# -------------------------------------------------------------------------
# ---- Installation Logic
# -------------------------------------------------------------------------

echo "[INFO] Installing $CHOICE..."

# Create a temporary directory for the build
BUILD_DIR=$(mktemp -d)
# Ensure the temporary directory is cleaned up when the script exits
trap 'rm -rf "$BUILD_DIR"' EXIT

if [[ "$CHOICE" == "paru" ]]; then
  # Install paru
  REPO_URL="https://aur.archlinux.org/paru.git"
  PKG_NAME="paru"
elif [[ "$CHOICE" == "yay" ]]; then
  # Install yay
  REPO_URL="https://aur.archlinux.org/yay.git"
  PKG_NAME="yay"
else
  # This should be unreachable due to the validation loop, but good practice
  echo "[ERROR] Invalid helper selection logic."
  exit 1
fi

echo "[INFO] Cloning $PKG_NAME repository..."
# Must be run as the current user, not with sudo
git clone "$REPO_URL" "$BUILD_DIR/$PKG_NAME"

echo "[INFO] Building and installing $PKG_NAME..."
# Change directory, build, and install the package
(
  cd "$BUILD_DIR/$PKG_NAME"
  # makepkg -si: -s syncs dependencies, -i installs, --noconfirm avoids prompts
  makepkg -si --noconfirm
)

# ---- Final Check ----
if command -v "$PKG_NAME" &>/dev/null; then
  echo "[SUCCESS] $PKG_NAME successfully installed! 🎉"
  "$PKG_NAME" --version | head -n1
else
  echo "[ERROR] $PKG_NAME failed to install."
  exit 1
fi
