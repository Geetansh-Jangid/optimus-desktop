#!/usr/bin/env bash
# ===================================================
# Optimus Desktop :: Zsh + Oh My Zsh + Powerlevel10k
# ===================================================
set -euo pipefail

echo "[INFO] ==== Starting Zsh + Oh My Zsh + Powerlevel10k setup (Arch Linux) ===="

# ---- Step 1: Install required packages ----
echo "[INFO] Installing dependencies..."
sudo pacman -Syu --needed --noconfirm zsh git curl

# ---- Step 2: Change default shell ----
ZSH_PATH="$(command -v zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "[INFO] Changing default shell to zsh..."
  chsh -s "$ZSH_PATH" "$USER" || echo "[WARN] Run manually: chsh -s $ZSH_PATH $USER"
else
  echo "[INFO] Default shell is already zsh."
fi

# ---- Step 3: Install Oh My Zsh ----
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[INFO] Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "[INFO] Oh My Zsh already installed."
fi

# ---- Step 4: Install Powerlevel10k ----
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "[INFO] Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "[INFO] Powerlevel10k already installed."
fi

# ---- Step 5: Configure ~/.zshrc ----
ZSHRC="$HOME/.zshrc"

echo "[INFO] Setting up .zshrc..."
cat >"$ZSHRC" <<'EOF'
# ===================================================
# Optimus Desktop :: Zsh Configuration with Powerlevel10k
# ===================================================

export ZSH="$HOME/.oh-my-zsh"

# --- Theme ---
ZSH_THEME="powerlevel10k/powerlevel10k"

# --- Plugins ---
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ---- Custom Aliases ----
alias cls='clear'
alias ll='ls -la --color=auto'
alias gs='git status'
alias ga='git add .'
alias gp='git push'
alias update='sudo pacman -Syu'

# ---- Path additions ----
export PATH="$HOME/.local/bin:$PATH"

# ---- Load Powerlevel10k configuration if exists ----
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

EOF

# ---- Step 6: Install Plugins (Optional but useful) ----
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "[INFO] Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "[INFO] Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

echo
echo "[SUCCESS] Setup complete!"
echo "[INFO] Start using zsh with:  exec zsh"
echo "[TIP] On first launch, Powerlevel10k will guide you through interactive setup."
echo "[TIP] You can rerun it anytime with:  p10k configure"
