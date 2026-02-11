#!/bin/bash

# --- Configuration ---
THEMES_DIR="$HOME/.config/themes"

# Define symlink targets in the ~/.config/current/ folder
ALACRITTY_LINK="$HOME/.config/current/alacritty-theme.toml"
NIRI_WALLPAPER_DIR_LINK="$HOME/.config/current/wallpapers"
SWAYNC_LINK="$HOME/.config/current/swaync-style.css"

# NEW WAYBAR SYMLINK TARGET
WAYBAR_STYLE_LINK="$HOME/.config/current/waybar-style.css"

# Define the explicit VS Code settings symlink path
VSCODE_SETTINGS_LINK="/home/geetansh/.config/Code/User/settings.json"
VICINAE_CONFIG="$HOME/.config/vicinae/settings.json"

# Define the fixed, physical files/directories for Direct Copy/Replacement/Sync
NIRI_LAYOUT_TARGET_FILE="$HOME/.config/niri/config/layout.kdl"
NWG_LOOK_TARGET_DIR="$HOME/.local/share/nwg-look"

# Define the path to scripts
WALLPAPER_SETTER_SCRIPT="$HOME/.local/bin/wallpaper.sh"

# --- NWG-LOOK GTK CONFIGURATION ---
# *** REPLACE 'gsettings.conf' with the actual filename nwg-look uses! ***
NWG_LOOK_CONFIG_FILENAME="gsettings"
NWG_LOOK_LINK="$NWG_LOOK_TARGET_DIR/$NWG_LOOK_CONFIG_FILENAME"

# BTOP THEME FILE
BTOP_CONFIG="$HOME/.config/btop/themes/btop.theme"

# ----------------------------------------------------------------------
# 1. Generate the list of available themes from directory names (FIXED PREDICATE)
# ----------------------------------------------------------------------
THEME_LIST=$(find "$THEMES_DIR" -maxdepth 1 -mindepth 1 -type d -print | sed "s|^$THEMES_DIR/||" | sort)

# --- 2. Use Rofi (in dmenu mode) to get the user's selection ---
#SELECTED_THEME=$(
#  echo -e "$THEME_LIST" | rofi \
#    -dmenu \
#    -i \
#    -p "Select Global Theme" \
#    -lines 8 \
#    -theme-str 'configuration {show-icons: false;}'
#)

# --- 2. Use Vicinae (in dmenu mode) to get the user's selection ---
SELECTED_THEME=$(
  echo -e "$THEME_LIST" | vicinae dmenu \
    --placeholder "Select Global Theme" \
    --no-quick-look
)

# --- 3. Check selection and execute theme switching logic ---

if [ -z "$SELECTED_THEME" ]; then
  echo "Theme selection cancelled."
  exit 0
fi

echo "Switching theme to: $SELECTED_THEME"

# ----------------------------------------------------------------------
# 3b. Update Alacritty Theme (Symlink)
# ----------------------------------------------------------------------
ALACRITTY_TARGET="$THEMES_DIR/$SELECTED_THEME/alacritty-theme.toml"
if [ -f "$ALACRITTY_TARGET" ]; then
  ln -snf "$ALACRITTY_TARGET" "$ALACRITTY_LINK"
  echo " -> Alacritty theme link updated."
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
# 3i. Update btop Theme (Symlink)
# ----------------------------------------------------------------------
BTOP_TARGET="$THEMES_DIR/$SELECTED_THEME/btop.theme"

if [ -f "$BTOP_TARGET" ]; then
    # Ensure the destination directory exists before symlinking
    mkdir -p "$(dirname "$BTOP_CONFIG")"
    
    ln -snf "$BTOP_TARGET" "$BTOP_CONFIG"
    echo " -> btop theme link updated."
    
    # Note: btop usually detects theme changes on its next launch, 
    # so a restart command is typically not required here.
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
# 3n. Update Vicinae Launcher Theme (Read from theme text file)
# ----------------------------------------------------------------------
VICINAE_THEME_FILE="$THEMES_DIR/$SELECTED_THEME/vicinae"

if [ -f "$VICINAE_THEME_FILE" ] && [ -f "$VICINAE_CONFIG" ]; then
  # 1. Read the theme name from the text file
  VICINAE_NAME=$(cat "$VICINAE_THEME_FILE" | tr -d '[:space:]')

  echo " -> Read Vicinae theme name: $VICINAE_NAME"

  # 2. Update the JSON config using sed
  # This finds "name": "anything" and replaces it with the name from the file
  sed -i "s/\"name\": \".*\"/\"name\": \"$VICINAE_NAME\"/" "$VICINAE_CONFIG"

  echo " -> Vicinae config.json updated."
else
  echo " -> Warning: Missing Vicinae theme file at $VICINAE_THEME_FILE or config at $VICINAE_CONFIG"
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
