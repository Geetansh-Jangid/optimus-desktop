#!/bin/bash

# --- Configuration ---
THEMES_DIR="$HOME/.config/themes"

# Define symlink targets in the ~/.config/current/ folder
LAZYVIM_LINK="$HOME/.config/current/lazyvim"
ALACRITTY_LINK="$HOME/.config/current/alacritty-theme.toml"
ROFI_LINK="$HOME/.config/current/rofi-theme.rasi"
NIRI_WALLPAPER_DIR_LINK="$HOME/.config/current/wallpapers"
SWAYNC_LINK="$HOME/.config/current/swaync-style.css"
QBITTORRENT_LINK="$HOME/Qbittorrent/theme/qbittorrent.qbtheme"

# NEW WAYBAR SYMLINK TARGET
WAYBAR_STYLE_LINK="$HOME/.config/current/waybar-style.css"

# Define the explicit VS Code settings symlink path
VSCODE_SETTINGS_LINK="/home/geetansh/.config/Code/User/settings.json"

# Define the fixed, physical files/directories for Direct Copy/Replacement/Sync
NIRI_LAYOUT_TARGET_FILE="$HOME/.config/niri/config/layout.kdl"
NWG_LOOK_TARGET_DIR="$HOME/.local/share/nwg-look"
BTOP_THEMES_DIR="$HOME/.config/btop/themes"

# Define the path to scripts
WALLPAPER_SETTER_SCRIPT="$HOME/.local/bin/wallpaper.sh"

# --- NWG-LOOK GTK CONFIGURATION ---
# *** REPLACE 'gsettings.conf' with the actual filename nwg-look uses! ***
NWG_LOOK_CONFIG_FILENAME="gsettings"
NWG_LOOK_LINK="$NWG_LOOK_TARGET_DIR/$NWG_LOOK_CONFIG_FILENAME"

# ----------------------------------------------------------------------
# 1. Generate the list of available themes from directory names (FIXED PREDICATE)
# ----------------------------------------------------------------------
THEME_LIST=$(find "$THEMES_DIR" -maxdepth 1 -mindepth 1 -type d -print | sed "s|^$THEMES_DIR/||" | sort)

# --- 2. Use Rofi (in dmenu mode) to get the user's selection ---
SELECTED_THEME=$(
  echo -e "$THEME_LIST" | rofi \
    -dmenu \
    -i \
    -p "Select Global Theme" \
    -lines 8
)

# --- 3. Check selection and execute theme switching logic ---

if [ -z "$SELECTED_THEME" ]; then
  echo "Theme selection cancelled."
  exit 0
fi

echo "Switching theme to: $SELECTED_THEME"

# ----------------------------------------------------------------------
# 3a. Update LazyVim Theme (Symlink)
# ----------------------------------------------------------------------
LAZYVIM_TARGET="$THEMES_DIR/$SELECTED_THEME/lazyvim"
if [ -f "$LAZYVIM_TARGET" ]; then
  ln -snf "$LAZYVIM_TARGET" "$LAZYVIM_LINK"
  echo " -> LazyVim theme link updated."
fi

# ----------------------------------------------------------------------
# 3b. Update Alacritty Theme (Symlink)
# ----------------------------------------------------------------------
ALACRITTY_TARGET="$THEMES_DIR/$SELECTED_THEME/alacritty-theme.toml"
if [ -f "$ALACRITTY_TARGET" ]; then
  ln -snf "$ALACRITTY_TARGET" "$ALACRITTY_LINK"
  echo " -> Alacritty theme link updated."
fi

# ----------------------------------------------------------------------
# 3c. Update Rofi Theme (Symlink)
# ----------------------------------------------------------------------
ROFI_TARGET="$THEMES_DIR/$SELECTED_THEME/rofi/main.rasi"
if [ -f "$ROFI_TARGET" ]; then
  ln -snf "$ROFI_TARGET" "$ROFI_LINK"
  echo " -> Rofi theme link updated."
fi

# ----------------------------------------------------------------------
# 3d. Update Niri Layout Theme (File Replacement)
# ----------------------------------------------------------------------
NIRI_LAYOUT_SOURCE="$THEMES_DIR/$SELECTED_THEME/niri/layout.kdl"

if [ -f "$NIRI_LAYOUT_SOURCE" ]; then
  echo " -> Performing physical copy for Niri layout.kdl..."
  cp -f "$NIRI_LAYOUT_SOURCE" "$NIRI_LAYOUT_TARGET_FILE"
  echo " -> Niri layout.kdl file replaced."
fi

# ----------------------------------------------------------------------
# 3e. Update Niri Wallpaper (Symlink + Script Execution)
# ----------------------------------------------------------------------
NIRI_WALLPAPER_TARGET_DIR="$THEMES_DIR/$SELECTED_THEME/wallpapers"

if [ -d "$NIRI_WALLPAPER_TARGET_DIR" ] && [ -x "$WALLPAPER_SETTER_SCRIPT" ]; then
  ln -snf "$NIRI_WALLPAPER_TARGET_DIR" "$NIRI_WALLPAPER_DIR_LINK"
  bash "$WALLPAPER_SETTER_SCRIPT"
  echo " -> Wallpaper set."
fi

# ----------------------------------------------------------------------
# 3f. Update Waybar Theme (NEW - Single File Symlink)
# ----------------------------------------------------------------------
WAYBAR_TARGET_STYLE="$THEMES_DIR/$SELECTED_THEME/waybar-style.css"

if [ -f "$WAYBAR_TARGET_STYLE" ]; then
  echo " -> Updating Waybar style symlink..."

  # Ensure the parent directory for the symlink exists
  mkdir -p "$(dirname "$WAYBAR_STYLE_LINK")"

  # Create the symlink
  ln -snf "$WAYBAR_TARGET_STYLE" "$WAYBAR_STYLE_LINK"
  echo " -> Waybar style symlink updated."

  # Restart Waybar to apply the changes
  killall -q waybar
  sleep 0.1
  setsid waybar &
  disown
  echo " -> Waybar fully restarted to apply new style."
else
  echo " -> Warning: Waybar style file ($WAYBAR_TARGET_STYLE) not found."
fi

# ----------------------------------------------------------------------
# 3g. GTK Theme via nwg-look (Cleanup, Symlink, and Apply)
# ----------------------------------------------------------------------
# 1. Cleanup old files
if [ -d "$NWG_LOOK_TARGET_DIR" ]; then
  echo " -> Clearing old nwg-look config files..."
  find "$NWG_LOOK_TARGET_DIR" -maxdepth 1 -type f -delete 2>/dev/null
  echo " -> Old nwg-look files removed."
fi
mkdir -p "$NWG_LOOK_TARGET_DIR" # Ensure the directory exists

# 2. Symlink the new theme file
GTK_SOURCE_FILE="$THEMES_DIR/$SELECTED_THEME/gtk/$NWG_LOOK_CONFIG_FILENAME"

if [ -f "$GTK_SOURCE_FILE" ]; then
  echo " -> Updating nwg-look GTK settings symlink..."
  ln -snf "$GTK_SOURCE_FILE" "$NWG_LOOK_LINK"
  echo " -> nwg-look config file symlinked."

  # 3. Apply the settings immediately
  if command -v nwg-look >/dev/null; then
    nwg-look -a
    echo " -> GTK settings applied using 'nwg-look -a'."
  else
    echo " -> Warning: 'nwg-look' not found. GTK theme not applied immediately."
  fi
else
  echo " -> Warning: nwg-look config file ($GTK_SOURCE_FILE) not found for $SELECTED_THEME."
fi

# ----------------------------------------------------------------------
# 3h. Update SwayNC Style (Symlink + Restart)
# ----------------------------------------------------------------------
SWAYNC_TARGET="$THEMES_DIR/$SELECTED_THEME/swaync/style.css"

if [ -f "$SWAYNC_TARGET" ]; then
  ln -snf "$SWAYNC_TARGET" "$SWAYNC_LINK"
  echo " -> SwayNC style link updated."

  # Restart SwayNC to apply the new style.css
  if command -v swaync >/dev/null; then
    pkill swaync && swaync &
    disown
    echo " -> SwayNC restarted to apply new style."
  fi
fi

# ----------------------------------------------------------------------
# 3i. Update qBittorrent Theme (Symlink)
# ----------------------------------------------------------------------
QBITTORRENT_TARGET="$THEMES_DIR/$SELECTED_THEME/qbittorrent.qbt"

if [ -f "$QBITTORRENT_TARGET" ]; then
  # Ensure the parent directory for the symlink exists
  mkdir -p "$(dirname "$QBITTORRENT_LINK")"

  ln -snf "$QBITTORRENT_TARGET" "$QBITTORRENT_LINK"
  echo " -> qBittorrent config link updated."
  echo " -> Note: qBittorrent must be restarted manually to apply changes."
fi

# ----------------------------------------------------------------------
# 3j. Update Btop Theme (Symlink)
# ----------------------------------------------------------------------
BTOP_TARGET="$THEMES_DIR/$SELECTED_THEME/btop.theme"
BTOP_LINK="$BTOP_THEMES_DIR/btop.theme"

if [ -f "$BTOP_TARGET" ]; then
  # Ensure the destination directory exists
  mkdir -p "$BTOP_THEMES_DIR"

  # Create the symlink
  ln -snf "$BTOP_TARGET" "$BTOP_LINK"
  echo " -> Btop theme symlink updated."
  echo " -> Note: Btop must be restarted manually to apply changes."
fi

# ----------------------------------------------------------------------
# 3k. Update VS Code Settings (Symlink)
# ----------------------------------------------------------------------
VSCODE_TARGET="$THEMES_DIR/$SELECTED_THEME/vscode.json"

if [ -f "$VSCODE_TARGET" ]; then
  # Ensure the parent directory for the VS Code settings file exists
  mkdir -p "$(dirname "$VSCODE_SETTINGS_LINK")"

  ln -snf "$VSCODE_TARGET" "$VSCODE_SETTINGS_LINK"
  echo " -> VS Code settings symlink updated."
  echo " -> Note: VS Code will automatically detect changes, but may require focusing/unfocusing the window."
fi

# ----------------------------------------------------------------------
# 3l. Reload Zsh Configuration (Requested Function)
# ----------------------------------------------------------------------
source "$HOME/.zshrc"
echo " -> Zsh configuration reloaded."

# ----------------------------------------------------------------------
# 3m. Final Action: Notify the user (Requested Function)
# ----------------------------------------------------------------------
notify-send "Theme Switched" "The global theme is now $SELECTED_THEME."

exit 0
