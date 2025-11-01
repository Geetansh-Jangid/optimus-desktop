#!/usr/bin/env bash
# =======================================================
# 🌐 Optimus Desktop :: Zsh Shell & Powerlevel10k Setup
# =======================================================
set -euo pipefail

# --- Require gum ---
if ! command -v gum &>/dev/null; then
  echo "❌ gum not found. Please install it first (sudo pacman -S gum)."
  exit 1
fi

gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "🌐 Optimus Desktop :: Zsh Shell & Powerlevel10k Setup" \
  "────────────────────────────────────────────────────" \
  "Installs Zsh, Oh My Zsh, Powerlevel10k, and essential plugins."

# --- Define Paths ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
OHMYZSH_DIR="$HOME/.oh-my-zsh"
#!/bin/bash

# --- Configuration ---
OHMYZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$OHMYZSH_DIR/custom"
ZSHRC_TEMPLATE_PATH="./zshrc"
ZSHRC_FINAL_PATH="$HOME/.zshrc"

#!/bin/bash

# --- Configuration ---
OHMYZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$OHMYZSH_DIR/custom"
ZSHRC_TEMPLATE_PATH="./zshrc"
ZSHRC_FINAL_PATH="$HOME/.zshrc"

# -------------------------------------------------------------------------
# ---- Step 1: Check and Install Dependencies ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Checking required dependencies (zsh, git, curl)..."
DEPS=(zsh git curl)
MISSING=()

for pkg in "${DEPS[@]}"; do
  if ! command -v "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
  fi
done

if ((${#MISSING[@]})); then
  gum style --foreground 208 "⚠ Missing required packages: ${MISSING[*]}"
  if gum confirm "Install them now?"; then
    echo "Installing dependencies..."
    sudo pacman -S --needed --noconfirm "${MISSING[@]}"
    gum style --foreground 82 "✔ Dependencies installed successfully."
  else
    gum style --foreground 196 "❌ Cannot continue without dependencies. Exiting."
    exit 1
  fi
else
  gum style --foreground 82 "[OK] All dependencies satisfied."
fi

# -------------------------------------------------------------------------
# ---- Step 2: Install Oh My Zsh (OMZ) ----
# -------------------------------------------------------------------------
if [ ! -d "$OHMYZSH_DIR" ]; then
  gum style --foreground 45 "[INFO] Oh My Zsh not found. Installing..."
  echo "Cloning Oh My Zsh into $OHMYZSH_DIR..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$OHMYZSH_DIR"
  gum style --foreground 82 "✔ Oh My Zsh installed."
else
  gum style --foreground 82 "[OK] Oh My Zsh already installed."
fi

# -------------------------------------------------------------------------
# ---- Step 3: Install Powerlevel10k Theme (p10k) ----
# -------------------------------------------------------------------------
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  gum style --foreground 45 "[INFO] Installing Powerlevel10k theme..."
  echo "Cloning Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  gum style --foreground 82 "✔ Powerlevel10k installed."
else
  gum style --foreground 82 "[OK] Powerlevel10k already installed."
fi

# -------------------------------------------------------------------------
# ---- Step 4: Install Plugins ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Checking Zsh plugins..."
PLUGINS_TO_INSTALL=(
  "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
  "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

for ((i = 0; i < ${#PLUGINS_TO_INSTALL[@]}; i += 2)); do
  PLUGIN_NAME="${PLUGINS_TO_INSTALL[i]}"
  PLUGIN_URL="${PLUGINS_TO_INSTALL[i + 1]}"
  PLUGIN_PATH="$ZSH_CUSTOM/plugins/$PLUGIN_NAME"

  if [ ! -d "$PLUGIN_PATH" ]; then
    echo "Installing $PLUGIN_NAME..."
    git clone "$PLUGIN_URL" "$PLUGIN_PATH"
  fi
done
gum style --foreground 82 "✔ All Zsh plugins checked/installed."

# -------------------------------------------------------------------------
# ---- Step 5: Configure .zshrc from template ----
# -------------------------------------------------------------------------
gum style --foreground 45 "[INFO] Configuring $ZSHRC_FINAL_PATH from $ZSHRC_TEMPLATE_PATH..."

if [ ! -f "$ZSHRC_TEMPLATE_PATH" ]; then
  gum style --foreground 196 "❌ ERROR: Zsh configuration template not found at $ZSHRC_TEMPLATE_PATH."
  exit 1
fi

# 5a. Copy the template to $HOME/.zshrc
cp "$ZSHRC_TEMPLATE_PATH" "$ZSHRC_FINAL_PATH"

# 5b. Use sed to replace the ZSH_THEME and plugins line in the new .zshrc
sed -i 's/^ZSH_THEME=.*$/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_FINAL_PATH"
sed -i 's/^plugins=(.*)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC_FINAL_PATH"

# 5c. Ensure p10k is sourced at the end
if ! grep -q "source ~/\.p10k\.zsh" "$ZSHRC_FINAL_PATH"; then
  echo -e '\n# --- Powerlevel10k Sourcing ---' | tee -a "$ZSHRC_FINAL_PATH" >/dev/null
  echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.' | tee -a "$ZSHRC_FINAL_PATH" >/dev/null
  echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' | tee -a "$ZSHRC_FINAL_PATH" >/dev/null
fi

gum style --foreground 82 "✔ Configuration complete."

# -------------------------------------------------------------------------
# ---- Step 6: Set Zsh as the Default Shell ----
# -------------------------------------------------------------------------
ZSH_PATH=$(which zsh)
CURRENT_SHELL=$(getent passwd "$LOGNAME" | cut -d: -f7)

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
  gum style --foreground 45 "[INFO] Setting Zsh as the default shell..."

  # Add Zsh to the list of approved shells if it's not already there
  if ! grep -Fxq "$ZSH_PATH" /etc/shells; then
    echo "Adding $ZSH_PATH to /etc/shells. Sudo password may be required."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi

  # Change the shell
  if gum confirm "Change default shell to Zsh for user '$LOGNAME'?"; then
    chsh -s "$ZSH_PATH"
    if [[ $? -eq 0 ]]; then
      gum style --foreground 82 "✔ Default shell changed successfully."
    else
      gum style --foreground 196 "❌ Failed to change default shell. Please try running 'chsh -s $ZSH_PATH' manually."
    fi
  else
    gum style --foreground 208 "⚠ Skipped changing default shell."
  fi
else
  gum style --foreground 82 "[OK] Zsh is already the default shell."
fi

# -------------------------------------------------------------------------
# ---- Step 7: Final Message ----
# -------------------------------------------------------------------------
gum style --border normal --border-foreground 82 --margin "1 2" --padding "1 2" \
  --align center \
  "✨ Setup complete! Welcome to Zsh with Powerlevel10k ✨" \
  "" \
  "$(gum style --foreground 212 'IMPORTANT: For changes to take effect, you must LOG OUT and LOG BACK IN.')" \
  "" \
  "$(gum style --foreground 208 'After you log back in, you can run the Powerlevel10k setup:')" \
  "p10k configure"
