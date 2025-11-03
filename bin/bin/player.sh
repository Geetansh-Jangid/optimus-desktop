#!/usr/bin/env bash
# player.sh
# Requires: playerctl, awk, notify-send (optional for fallback)
# Make executable: chmod +x ~/.config/waybar/scripts/playerctl-waybar.sh

# Priority list (higher first)
PRIORITY=("spotify" "youtube" "chromium" "chrome" "brave" "vivaldi" "firefox" "vlc")

# Get list of players
mapfile -t PLAYERS < <(playerctl -l 2>/dev/null)

# choose player by priority, fallback to first available
ACTIVE=""
for p in "${PRIORITY[@]}"; do
  for pl in "${PLAYERS[@]}"; do
    # case-insensitive contains test
    if echo "$pl" | tr '[:upper:]' '[:lower:]' | grep -q "$p"; then
      ACTIVE="$pl"
      break 2
    fi
  done
done
# If none matched priority, pick first player if exists
if [ -z "$ACTIVE" ] && [ "${#PLAYERS[@]}" -gt 0 ]; then
  ACTIVE="${PLAYERS[0]}"
fi

# Fallback when no player
if [ -z "$ACTIVE" ]; then
  # prints a single line "No music" and same on tooltip
  echo "♪ No music"
  echo "No active MPRIS player found."
  exit 0
fi

# get metadata
title=$(playerctl --player="$ACTIVE" metadata title 2>/dev/null)
artist=$(playerctl --player="$ACTIVE" metadata artist 2>/dev/null)
status=$(playerctl --player="$ACTIVE" status 2>/dev/null)

# fallback empty fields
[ -z "$title" ] && title="Unknown title"
[ -z "$artist" ] && artist="Unknown artist"

full="${title} — ${artist}"

# Map player name to icon (Nerd Font / Font Awesome glyphs)
player_lower=$(echo "$ACTIVE" | tr '[:upper:]' '[:lower:]')
icon="♪" # default

case "$player_lower" in
*spotify*) icon="" ;;                                   # spotify
*youtube* | *yt*) icon="" ;;                            # youtube
*chromium* | *chrome* | *brave* | *vivaldi*) icon="" ;; # browser (chromium/chrome icon)
*firefox*) icon="" ;;                                   # firefox
*vlc*) icon="嗢" ;;                                       # vlc (may vary by font)
*) icon="♪" ;;
esac

# Play / Pause icons (Nerd Font / Font Awesome)
if [ "$status" = "Playing" ]; then
  pp="" # pause icon
else
  pp="" # play icon
fi

# Smart truncation: prefer not to cut words; max length of visible text (excluding icons)
MAX_LEN=36

# build the visible text: title - artist
visible="${title} - ${artist}"

# if too long, do smart trim
if [ ${#visible} -gt $MAX_LEN ]; then
  # take up to MAX_LEN and then backtrack to last space to avoid mid-word cut, but ensure at least some chars
  take=$((MAX_LEN - 1)) # leave room for ellipsis
  candidate="${visible:0:take}"
  # find last space
  last_space_index=$(echo "$candidate" | awk '{print length}') # default
  # use awk to find last space position
  idx=$(awk -v s="$candidate" 'BEGIN{p=0; for(i=1;i<=length(s);++i) if(substr(s,i,1)==" ") p=i; print p}')
  if [ "$idx" -gt 0 ] && [ "$idx" -gt 10 ]; then
    # trim at last space to avoid breaking a word, but only if that leaves at least 10 chars
    visible="${candidate:0:idx}…"
  else
    # else do a hard cut
    visible="${candidate}…"
  fi
fi

# Compose final one-line output: [player-icon] [play/pause]  visible-text
# Add small spacing to keep layout neat
out="${icon} ${pp}  ${visible}"

# Print short output for Waybar (single-line). Also print full metadata on second line for tooltip/fallback.
echo "$out"
echo "$full"
