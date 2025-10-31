#!/usr/bin/env bash
# ===================================================
# 🚀 Optimus Desktop :: Guided Setup Script
# Orchestrates the setup, asking for each step.
# ===================================================

set -euo pipefail

# --- Constants ---
MODULES_DIR="$(dirname "$0")/modules"

# --- Guard: Require gum ---
if ! command -v gum &>/dev/null; then
  echo "❌ gum not found. Please install it first (sudo pacman -S gum)."
  exit 1
fi

# --- Module Metadata ---
# This is where we define the descriptions and impact for each module.
# Using associative arrays makes this clean and easy to maintain.

declare -A MODULE_DESCRIPTIONS
MODULE_DESCRIPTIONS=(
  ["aur-helper.sh"]="Installs a helper program (like 'paru' or 'yay') to easily build and install software from the Arch User Repository (AUR)."
  ["chaotic-aur-setup.sh"]="Configures the Chaotic-AUR, a third-party repository that provides pre-built binary packages for many popular AUR applications, saving you significant compilation time."
  ["package-install.sh"]="Reads package lists from the 'data/' directory and installs all core applications, utilities, fonts, and system libraries."
  ["editor.sh"]="Prompts you to select and install a code editor like VS Code or Neovim."
  ["browser-setup.sh"]="Prompts you to select and install a web browser like Brave."
  ["setup-zsh.sh"]="Installs and configures the Zsh shell with Oh My Zsh, Powerlevel10k theme, and useful plugins (like auto-suggestions) for a powerful terminal experience."
  ["config-copy.sh"]="Copies all personal configuration files (dotfiles) from the 'config/' directory to their correct locations in your home directory (~/.config/). This applies your custom settings to applications."
  ["scripts-copy.sh"]="Copies custom helper scripts from the 'bin/' directory to ~/.local/bin/, making them available as commands in your terminal."
)

declare -A MODULE_IMPACTS
MODULE_IMPACTS=(
  ["aur-helper.sh"]="CRITICAL. Skipping this will cause AUR package installations in later steps to fail."
  ["chaotic-aur-setup.sh"]="Recommended. Skipping this means AUR packages will be built from source, which can be very time-consuming."
  ["package-install.sh"]="CRITICAL. Skipping this means no applications or desktop environment components will be installed."
  ["editor.sh"]="Optional. You can skip this if you don't need a code editor or prefer to install one manually later."
  ["browser-setup.sh"]="Optional. You can skip this if you don't need a graphical web browser or prefer to install one manually."
  ["setup-zsh.sh"]="Recommended. Skipping this will leave you with a default system shell (like bash) without custom prompts or features."
  ["config-copy.sh"]="HIGHLY RECOMMENDED. Skipping this will result in default application settings, not your personalized ones."
  ["scripts-copy.sh"]="Optional. Skip this if you do not have any custom scripts to install."
)

# --- Main Logic ---
main() {
  # --- Fancy Header ---
  gum style --border normal --margin "1 2" --padding "1 2" \
    --border-foreground 212 \
    "🚀 Optimus Desktop :: Guided Setup" \
    "──────────────────────────────────" \
    "You will be prompted to run each setup module one by one."

  # --- Make modules executable ---
  gum spin --spinner line --title "Preparing modules..." -- bash -c "chmod +x '$MODULES_DIR'/*.sh"

  # --- Define the correct execution order ---
  local -r EXECUTION_ORDER=(
    "aur-helper.sh"
    "chaotic-aur-setup.sh"
    "package-install.sh"
    "editor.sh"
    "browser-setup.sh"
    "setup-zsh.sh"
    "config-copy.sh"
    "scripts-copy.sh"
  )

  gum style --border double --margin "1 0" --padding "1 2" --border-foreground 220 "Starting Guided Installation"

  # --- Iterate through modules one by one ---
  for script_basename in "${EXECUTION_ORDER[@]}"; do
    local friendly_name
    friendly_name=$(echo "$script_basename" | sed -e 's/\.sh$//' -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g')

    # --- Display the Details Box ---
    local desc="${MODULE_DESCRIPTIONS[$script_basename]:-No description available.}"
    local impact="${MODULE_IMPACTS[$script_basename]:-No impact information available.}"

    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 250 \
      "Module: $(gum style --bold --foreground 212 "$friendly_name")" \
      "$(gum style --bold 'Function:') $desc" \
      "" \
      "$(gum style --bold --foreground 208 'Impact if Skipped:') $impact"

    # --- Ask for confirmation for THIS module ---
    if gum confirm "Do you want to run the '$friendly_name' module?"; then
      run_module "$MODULES_DIR/$script_basename"
    else
      gum style --foreground 240 --margin "0 2" "⏩ Skipping '$friendly_name'..."
      # Add a separator for clarity
      gum style --border hidden --margin "1 0" "--------------------------------------------------"
    fi
  done

  gum style --border double --margin "1 0" --padding "1 2" --border-foreground 82 "🎉 Guided setup finished!"
}

# --- Function to run a single module ---
run_module() {
  local script_path="$1"
  local script_name
  script_name=$(basename "$script_path")

  gum style --foreground 212 --bold --margin "1 0" \
    "🚀 Executing module: $script_name"
  echo "──────────────────────────────────────────────────"

  if ! "$script_path"; then
    gum style --foreground 196 --bold --margin "1 0" \
      "❌ Module '$script_name' failed with an error." \
      "Please check the output above. Aborting."
    exit 1
  fi

  gum style --foreground 82 --bold --margin "1 0" \
    "✅ Module '$script_name' completed successfully."
  # Add a separator after successful execution
  gum style --border hidden --margin "1 0" "--------------------------------------------------"
}

# --- Run the main function ---
main
