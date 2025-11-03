#!/bin/zsh

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"

# Define menu items: label => command
# If the value starts with "terminal:", it runs in Alacritty; otherwise, runs directly
typeset -A menu_items
menu_items=(
    "Pacman Install"    "terminal:pkg-pacman-install"
    "AUR Install"       "terminal:pkg-aur-install"
    "Remove Package"    "terminal:pkg-remove"
    "Change Wallpaper"  "wallpaper.sh"
)

# Show menu
choice=$(printf "%s\n" "${(@k)menu_items}" | fuzzel --dmenu --prompt "Select Action: ")

# Run the chosen command
for label cmd in ${(kv)menu_items}; do
    if [[ "$choice" == "$label" ]]; then
        if [[ "$cmd" == terminal:* ]]; then
            # Strip the 'terminal:' prefix and launch in Alacritty
            alacritty --title "$label" -e zsh -ic "${cmd#terminal:}"
        else
            # Run directly
            zsh -ic "$cmd"
        fi
        break
    fi
done

