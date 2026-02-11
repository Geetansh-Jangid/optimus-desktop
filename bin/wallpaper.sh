#!/bin/bash

# --- Configuration ---
DIR="${HOME}/.config/current/wallpapers"
LINK="${HOME}/.config/current/wallpaper.jpg"

# --- 1. Get Wallpapers & Create Unique Memory ---
if [ ! -d "$DIR" ]; then
  echo "Error: $DIR missing"
  exit 1
fi

# Create a unique state file based on the filenames in the current theme
DIR_HASH=$(ls "$DIR" | md5sum | cut -d' ' -f1)
STATE="${HOME}/.wallpaper_index_${DIR_HASH}"

readarray -t WALLS <<<"$(find -H "$DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' \) | sort)"
count=${#WALLS[@]}
[ "$count" -eq 0 ] && exit 1

# --- 2. Determine Mode (Boot vs Cycle) ---
if awww query &>/dev/null; then
  MODE="cycle"
else
  MODE="restore"
  awww-daemon & 
  sleep 0.5
fi

# --- 3. Determine Target Wallpaper ---
[ -f "$STATE" ] && CURRENT=$(cat "$STATE")

# Fallback: If no memory exists OR the remembered file isn't in this folder
if [[ -z "$CURRENT" ]] || [[ ! " ${WALLS[@]} " =~ " ${CURRENT} " ]]; then
  TARGET="${WALLS[0]}"
else
  if [ "$MODE" == "restore" ]; then
    TARGET="$CURRENT"
  else
    # Find current index and move to next
    idx=0
    for i in "${!WALLS[@]}"; do
      if [[ "${WALLS[$i]}" == "$CURRENT" ]]; then
        idx=$i
        break
      fi
    done
    next_idx=$(((idx + 1) % count))
    TARGET="${WALLS[$next_idx]}"
  fi
fi

# --- 4. Apply Changes ---
echo "$TARGET" >"$STATE"
rm -f "$LINK" && ln -s "$TARGET" "$LINK"

awww img "$TARGET" --transition-fps 144 --transition-type grow --transition-duration 0.5