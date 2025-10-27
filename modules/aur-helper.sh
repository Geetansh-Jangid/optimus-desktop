#!/usr/bin/env bash
# Optimus Desktop: AUR Helper (paru/yay) Setup - Improved
set -euo pipefail

INFO() { printf "[INFO] %s\n" "$*"; }
WARN() { printf "[WARN] %s\n" "$*" >&2; }
ERROR() { printf "[ERROR] %s\n" "$*" >&2; }
SUCCESS() { printf "[SUCCESS] %s\n" "$*"; }

echo
INFO "==== Optimus Desktop :: AUR Helper Setup ===="

# ---- Requirements ----
# Packages we want to ensure are available for building AUR packages.
# 'base-devel' is a pacman group, the rest are regular packages/commands.
REQUIRED_PKG_GROUPS=(base-devel)
REQUIRED_PACKAGES=(git sudo curl pacman) # 'makepkg' provided by base-devel but we still check command
REQUIRED_COMMANDS=(git curl makepkg)

MISSING_PKGS=()
MISSING_CMDS=()

# helper to check pacman group installed
is_group_installed() {
  local group="$1"
  pacman -Qg "$group" &>/dev/null
}

# helper to check package installed
is_pkg_installed() {
  local pkg="$1"
  pacman -Qi "$pkg" &>/dev/null
}

# check groups
for g in "${REQUIRED_PKG_GROUPS[@]}"; do
  if ! is_group_installed "$g"; then
    MISSING_PKGS+=("$g")
  fi
done

# check packages (but many might be provided by groups)
for p in "${REQUIRED_PACKAGES[@]}"; do
  if ! is_pkg_installed "$p"; then
    # If it's a group we already will handle above
    MISSING_PKGS+=("$p")
  fi
done

# check commands (some dependencies might be commands from other packages)
for c in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v "$c" &>/dev/null; then
    MISSING_CMDS+=("$c")
  fi
done

if ((${#MISSING_PKGS[@]} + ${#MISSING_CMDS[@]})); then
  WARN "Missing package/groups: ${MISSING_PKGS[*]:-none}"
  WARN "Missing commands: ${MISSING_CMDS[*]:-none}"
  # Offer to install pacman group/packages (uses sudo)
  read -r -p "Install missing packages/groups now with sudo? [Y/n]: " ans
  ans=${ans:-y}
  ans=${ans,,}
  if [[ $ans != "n" && $ans != "no" ]]; then
    # Try to install only the pacman things (pacman groups and packages)
    # Filter duplicates and ensure we pass only real package names (not empty)
    PKGS_TO_INSTALL=()
    for pkg in "${MISSING_PKGS[@]}"; do
      [[ -n "$pkg" ]] && PKGS_TO_INSTALL+=("$pkg")
    done

    if ((${#PKGS_TO_INSTALL[@]})); then
      INFO "Running: sudo pacman -S --needed --noconfirm ${PKGS_TO_INSTALL[*]}"
      sudo pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}"
    fi

    # After pacman install, re-check commands
    for c in "${REQUIRED_COMMANDS[@]}"; do
      if ! command -v "$c" &>/dev/null; then
        WARN "Command '$c' still missing after package install. You may need to install it manually."
      fi
    done
  else
    ERROR "Cannot continue without required packages/commands."
    exit 1
  fi
else
  INFO "All required packages/commands appear present."
fi

# -------------------------------------------------------------------------
# Check existing AUR helpers (including -bin variants)
# -------------------------------------------------------------------------
AUR_HELPERS=(paru paru-bin yay yay-bin)

for helper in "${AUR_HELPERS[@]}"; do
  if command -v "$helper" &>/dev/null; then
    # Print whichever variant is present, and try to show version if it supports --version or -V
    ver=""
    if "$helper" --version &>/dev/null; then
      ver=$("$helper" --version | head -n1)
    elif "$helper" -V &>/dev/null; then
      ver=$("$helper" -V | head -n1)
    fi

    SUCCESS "Detected installed AUR helper: $helper ${ver:+- $ver}"
    exit 0
  fi
done

# -------------------------------------------------------------------------
# Ensure script not run as root (we need to build as normal user)
# -------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  WARN "It is not recommended to run this script as root."
  read -r -p "Continue running as root? [y/N]: " rootans
  rootans=${rootans:-n}
  rootans=${rootans,,}
  if [[ $rootans != "y" && $rootans != "yes" ]]; then
    ERROR "Please run this script as a regular user with sudo privileges. Exiting."
    exit 1
  fi
fi

# -------------------------------------------------------------------------
# User choice
# -------------------------------------------------------------------------
echo
echo "Which AUR helper would you like to install?"
echo "1) paru (Rust-based, actively maintained)"
echo "2) yay  (Go-based, well-established)"
CHOICE=""
while true; do
  read -r -p $'❯ Enter your choice (1 or 2): ' choice_num
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

read -r -p "Proceed to install ${CHOICE}? [Y/n]: " proceed
proceed=${proceed:-y}
proceed=${proceed,,}
if [[ $proceed == "n" || $proceed == "no" ]]; then
  INFO "Skipping installation."
  exit 0
fi

# -------------------------------------------------------------------------
# Prepare build
# -------------------------------------------------------------------------
INFO "Installing $CHOICE..."
if [[ "$CHOICE" == "paru" ]]; then
  REPO_URL="https://aur.archlinux.org/paru-bin.git"
  PKG_NAME="paru-bin"
elif [[ "$CHOICE" == "yay" ]]; then
  REPO_URL="https://aur.archlinux.org/yay-bin.git"
  PKG_NAME="yay-bin"
else
  ERROR "Unrecognized choice '$CHOICE'"
  exit 1
fi

BUILD_DIR=$(mktemp -d -t aurbuild.XXXXXX)
trap 'rc=$?; rm -rf "$BUILD_DIR" || true; exit $rc' EXIT

INFO "Cloning $PKG_NAME from AUR..."
if ! git clone --depth=1 "$REPO_URL" "$BUILD_DIR/$PKG_NAME"; then
  ERROR "git clone failed. Check network and that git is installed."
  exit 1
fi

# Build and install
INFO "Building and installing $PKG_NAME (this may take a while)..."
(
  set -e
  cd "$BUILD_DIR/$PKG_NAME"
  # ensure we run makepkg as the non-root user; makepkg refuses to run as root by design
  if [[ $EUID -eq 0 ]]; then
    WARN "makepkg should not run as root. Attempting to run as the original user."
    # If SUDO_USER exists, try to run as them; otherwise abort.
    if [[ -n "${SUDO_USER:-}" ]]; then
      sudo -u "$SUDO_USER" makepkg -si --noconfirm
    else
      ERROR "Cannot determine non-root user to run makepkg. Run this script as a normal user."
      exit 1
    fi
  else
    makepkg -si --noconfirm
  fi
)

# -------------------------------------------------------------------------
# Final check
# -------------------------------------------------------------------------
if command -v "$PKG_NAME" &>/dev/null; then
  SUCCESS "$PKG_NAME successfully installed! 🎉"
  # print a safe version output if supported
  if "$PKG_NAME" --version &>/dev/null; then
    "$PKG_NAME" --version | head -n1
  elif "$PKG_NAME" -V &>/dev/null; then
    "$PKG_NAME" -V | head -n1
  fi
  exit 0
else
  ERROR "$PKG_NAME failed to install. Inspect the preceding output for errors."
  exit 1
fi
