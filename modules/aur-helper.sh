#!/usr/bin/env bash
# ============================================================
# Optimus Desktop — AUR Helper Setup
# Author: Geetansh Jangid
# ============================================================

set -e

AUR_HELPER="paru"
AUR_URL="https://aur.archlinux.org/paru.git"
AUR_DIR="/tmp/aur_helper_install"
LOG_FILE="${HOME}/.local/share/optimus-desktop/logs/aur_helper.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo -e "[${1}] ${2}" | tee -a "$LOG_FILE"
}

ask() {
  read -rp "❯ $1 [Y/n]: " choice
  case "$choice" in
  [nN]*) return 1 ;;
  *) return 0 ;;
  esac
}

require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    log "WARN" "Missing dependency: $1"
    MISSING_DEPS+=("$1")
  fi
}

install_dependency() {
  local pkg="$1"
  log "INFO" "Installing missing dependency: $pkg"
  sudo pacman -S --needed --noconfirm "$pkg" >>"$LOG_FILE" 2>&1
}

check_dependencies() {
  log "INFO" "Checking required dependencies..."
  MISSING_DEPS=()

  require_cmd git
  require_cmd makepkg
  require_cmd sudo

  if ! pacman -Qi base-devel &>/dev/null; then
    MISSING_DEPS+=("base-devel")
  fi

  if ((${#MISSING_DEPS[@]} > 0)); then
    log "WARN" "Missing: ${MISSING_DEPS[*]}"
    if ask "Install missing dependencies using pacman?"; then
      sudo pacman -Sy --needed --noconfirm "${MISSING_DEPS[@]}"
      log "SUCCESS" "Dependencies installed successfully."
    else
      log "ERROR" "User declined dependency installation. Exiting."
      exit 1
    fi
  else
    log "OK" "All dependencies satisfied."
  fi
}

install_paru() {
  log "INFO" "Installing $AUR_HELPER..."
  rm -rf "$AUR_DIR"
  mkdir -p "$AUR_DIR"
  cd "$AUR_DIR"

  git clone "$AUR_URL" . >>"$LOG_FILE" 2>&1
  makepkg -si --noconfirm >>"$LOG_FILE" 2>&1

  cd -
  rm -rf "$AUR_DIR"

  if command -v "$AUR_HELPER" &>/dev/null; then
    log "SUCCESS" "$AUR_HELPER installed successfully!"
  else
    log "ERROR" "Failed to install $AUR_HELPER."
    exit 1
  fi
}

main() {
  log "INFO" "==== Optimus Desktop :: AUR Helper Setup ===="

  if command -v "$AUR_HELPER" &>/dev/null; then
    log "OK" "$AUR_HELPER is already installed. Skipping setup."
    exit 0
  fi

  check_dependencies

  if ask "Proceed to install $AUR_HELPER (paru)?"; then
    install_paru
  else
    log "INFO" "Installation skipped by user."
  fi
}

main "$@"
