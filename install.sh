#!/usr/bin/env bash
# ===================================================
# 🚀 Optimus Desktop :: Master Installer
# A flexible, guided installer for your desktop environment.
# ===================================================

set -euo pipefail

if ! command -v gum &>/dev/null; then
  echo "❌ gum not found. Installing it first (sudo pacman -S gum)."
  sudo pacman -S gum
fi

# --- Constants & Global Variables ---
readonly MODULES_DIR="$(dirname "$0")/modules"
readonly EXECUTION_ORDER=(
  "aur-helper.sh"
  "chaotic-aur-setup.sh"
  "package-install.sh"
  "editor.sh"
  "browser-setup.sh"
  "setup-zsh.sh"
  "config-copy.sh"
  "scripts-copy.sh"
)

# --- Module Metadata ---
declare -A MODULE_DESCRIPTIONS
MODULE_DESCRIPTIONS=(
#!/bin/bash

# ==============================================================================
# --- CONFIGURATION: DEFINE MODULES ---
# ==============================================================================
# This script should be in the root directory of your dotfiles repo.
# It expects a 'modules/' directory containing the individual installer scripts.

# The directory where your individual installer scripts are located.
readonly MODULES_DIR="modules"

# The order in which the scripts should be executed during a full install.
# The update module has been added as the first step.
readonly EXECUTION_ORDER=(
  "update.sh"
  "aur-helper.sh"
  "chaotic-aur-setup.sh"
  "package-install.sh"
  "editor.sh"
  "browser-setup.sh"
  "setup-zsh.sh"
  "config-copy.sh"
  "scripts-copy.sh"
)

# Descriptions for each module, used in the interactive installer.
declare -A MODULE_DESCRIPTIONS
MODULE_DESCRIPTIONS=(
  ["update.sh"]="Refreshes package repositories and upgrades all system packages (Arch, AUR, Flatpak, Snap) to their latest versions."
  ["aur-helper.sh"]="Installs a helper program ('paru' or 'yay') to easily build and install software from the Arch User Repository (AUR)."
  ["chaotic-aur-setup.sh"]="Configures the Chaotic-AUR, a third-party repository that provides pre-built binary packages for many popular AUR applications, saving you significant compilation time."
  ["package-install.sh"]="Reads package lists from the 'data/' directory and installs all core applications, utilities, fonts, and system libraries using the '--needed' flag to prevent re-installing existing packages."
  ["editor.sh"]="Prompts you to select and install a code editor."
  ["browser-setup.sh"]="Prompts you to select and install a web browser."
  ["setup-zsh.sh"]="Installs and configures the Zsh shell with Oh My Zsh, Powerlevel10k theme, and useful plugins (like auto-suggestions) for a powerful terminal experience."
  ["config-copy.sh"]="Copies all personal configuration files (dotfiles) from the 'config/' directory to their correct locations in your home directory (~/.config/). This applies your custom settings to applications."
  ["scripts-copy.sh"]="Copies custom helper scripts from the 'bin/' directory to ~/.local/bin/, making them available as commands in your terminal."
)

# The potential impact of skipping each module.
declare -A MODULE_IMPACTS
MODULE_IMPACTS=(
  ["update.sh"]="HIGHLY RECOMMENDED. Skipping this can lead to outdated packages and potential dependency issues during installation."
  ["aur-helper.sh"]="CRITICAL. Skipping this will cause AUR package installations in later steps to fail."
  ["chaotic-aur-setup.sh"]="Recommended. Skipping this means AUR packages will be built from source, which can be very time-consuming."
  ["package-install.sh"]="CRITICAL for first install. On subsequent runs, it safely updates existing packages."
  ["editor.sh"]="Optional. You can skip this if you don't need a code editor or prefer to install one manually later."
  ["browser-setup.sh"]="Optional. You can skip this if you don't need a graphical web browser or prefer to install one manually."
  ["setup-zsh.sh"]="Recommended. Skipping this will leave you with a default system shell (like bash)."
  ["config-copy.sh"]="HIGHLY RECOMMENDED. Skipping this will result in default application settings, not your personalized ones."
  ["scripts-copy.sh"]="Optional. Skip this if you do not have any custom scripts to install."
)

# --- Helper Functions ---

# Displays help message and exits.
show_help() {
  echo "🚀 Optimus Desktop :: Master Installer"
  echo
  echo "Usage: install.sh [FLAG]"
  echo
  echo "Flags:"
  echo "  --install         Run the full guided installation for a new system. (Default)"
  echo "  --upgrade         Run a non-interactive upgrade of packages and configs."
  echo "  --run-module <name> Run a single, specific module. (e.g., --run-module config-copy.sh)"
  echo "  --help            Show this help message and exit."
  echo
  echo "Available modules for --run-module:"
  for module in "${EXECUTION_ORDER[@]}"; do
    echo "  - $module"
  done
  exit 0
}

# Executes a single module with styled feedback.
run_module() {
  local script_path="$1"
  local script_name
  script_name=$(basename "$script_path")

  gum style --foreground 212 --bold --margin "1 0" \
    "🚀 Executing module: $script_name"
  echo "──────────────────────────────────────────────────"

  if ! "$script_path"; then
    gum style --foreground 196 --bold --margin "1 0" \
      "❌ Module '$script_name' failed with an error. Aborting."
    exit 1
  fi

  gum style --foreground 82 --bold --margin "1 0" \
    "✅ Module '$script_name' completed successfully."
  echo "--------------------------------------------------" | gum style --foreground 240
}

# --- Main Execution Flows ---

# The interactive, guided installation for a new system.
run_install_flow() {
  gum style --border normal --margin "1 2" --padding "1 2" \
    --border-foreground 212 \
    "🚀 Optimus Desktop :: Guided Setup" \
    "──────────────────────────────────" \
    "You will be prompted to run each setup module one by one."

  gum style --border double --margin "1 0" --padding "1 2" --border-foreground 220 "Starting Guided Installation"

  for script_basename in "${EXECUTION_ORDER[@]}"; do
    local friendly_name
    friendly_name=$(echo "$script_basename" | sed -e 's/\.sh$//' -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g')

    local desc="${MODULE_DESCRIPTIONS[$script_basename]}"
    local impact="${MODULE_IMPACTS[$script_basename]}"

    local info_box_content
    info_box_content=$(printf '# %s\n\n**Function:** %s\n\n**Impact if Skipped:** %s' \
      "$friendly_name" "$desc" "$impact")

    echo "$info_box_content" | gum format -t markdown

    if gum confirm "Do you want to run the '$friendly_name' module?"; then
      run_module "$MODULES_DIR/$script_basename"
    else
      gum style --foreground 240 --margin "0 2" "⏩ Skipping '$friendly_name'..."
      echo "--------------------------------------------------" | gum style --foreground 240
    fi
  done

  gum style --border double --margin "1 0" --padding "1 2" --border-foreground 82 "🎉 Guided setup finished!"
}

# A faster, less-interactive flow for updating an existing system.
run_upgrade_flow() {
  gum style --border normal --margin "1 2" --padding "1 2" \
    --border-foreground 212 "🚀 Optimus Desktop :: System Upgrade"

  # MODIFIED: Added 'update.sh' to the upgrade routine.
  local -r UPGRADE_MODULES=(
    "update.sh"
    "package-install.sh"
    "config-copy.sh"
    "scripts-copy.sh"
  )

  gum style --margin "1 2" "This will run the following modules to update your system:"
  for module in "${UPGRADE_MODULES[@]}"; do
    gum style --margin "0 4" "- $module"
  done

  if ! gum confirm "Proceed with the upgrade?"; then
    exit 0
  fi

  for module in "${UPGRADE_MODULES[@]}"; do
    run_module "$MODULES_DIR/$module"
  done

  gum style --border double --margin "1 0" --padding "1 2" --border-foreground 82 "🎉 System upgrade finished!"
}

# --- Main Program Logic ---
main() {
  # Guard: Require gum
  if ! command -v gum &>/dev/null; then
    echo "❌ gum not found. Please install it first (sudo pacman -S gum)."
    exit 1
  fi

  # Default mode
  local MODE="install"
  local SINGLE_MODULE=""

  # --- Argument Parsing ---
  if [[ $# -gt 0 ]]; then
    case "$1" in
    --install)
      MODE="install"
      ;;
    --upgrade)
      MODE="upgrade"
      ;;
    --run-module)
      if [[ -z "$2" ]]; then
        gum style --foreground 196 "ERROR: --run-module requires a module name."
        show_help
      fi
      MODE="single"
      SINGLE_MODULE="$2"
      ;;
    --help)
      show_help
      ;;
    *)
      gum style --foreground 196 "ERROR: Unknown flag '$1'."
      show_help
      ;;
    esac
  fi

  # --- Prepare modules ---
  gum style --foreground 45 "🔧 Making modules executable..."
  if ! chmod +x "$MODULES_DIR"/*.sh; then
    gum style --foreground 196 "ERROR: Failed to make modules executable."
    exit 1
  fi

  # --- Execute based on mode ---
  case "$MODE" in
  install)
    run_install_flow
    ;;
  upgrade)
    run_upgrade_flow
    ;;
  single)
    if [[ -f "$MODULES_DIR/$SINGLE_MODULE" ]]; then
      run_module "$MODULES_DIR/$SINGLE_MODULE"
    else
      gum style --foreground 196 "ERROR: Module '$SINGLE_MODULE' not found."
      show_help
    fi
    ;;
  esac
} # <--- CORRECT: The main function definition ends here.

# --- Run the main function with all command-line arguments ---
main "$@" # <--- CORRECT: Call the function at the very end of the script.
