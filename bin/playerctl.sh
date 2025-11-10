#!/usr/bin/env bash
# player.sh - Enhanced Waybar playerctl integration
# Requires: playerctl, awk
# Make executable: chmod +x ~/.config/waybar/scripts/player.sh
# Usage:
#   - No args: Output display info for Waybar
#   - play-pause/next/previous: Control the active player

set -eo pipefail

# Configuration
readonly MAX_LENGTH=36
readonly MIN_TRUNCATE_LENGTH=10
readonly PRIORITY=("spotify" "youtube" "chromium" "chrome" "brave" "vivaldi" "firefox" "vlc")
readonly CACHE_FILE="/tmp/waybar_playerctl_active_player_${USER}"

# Icons (Nerd Fonts / Font Awesome)
readonly ICON_DEFAULT="♪"
readonly ICON_SPOTIFY=""
readonly ICON_YOUTUBE=""
readonly ICON_BROWSER=""
readonly ICON_FIREFOX=""
readonly ICON_VLC="嗢"
readonly ICON_PLAYING=""
readonly ICON_PAUSED=""

# Output when no player is active
no_player_output() {
  echo "${ICON_DEFAULT} No music"
  echo "No active MPRIS player found"
  exit 0
}

# Get all available players
get_players() {
  playerctl -l 2>/dev/null || true
}

# Select player based on status (playing > paused) then priority
select_player() {
  local -a players playing_players paused_players
  mapfile -t players < <(get_players)

  # Return empty if no players found
  [[ ${#players[@]} -eq 0 ]] && return 1

  # Separate players by status
  for player in "${players[@]}"; do
    local status
    status=$(playerctl --player="$player" status 2>/dev/null || echo "Unknown")

    if [[ "$status" == "Playing" ]]; then
      playing_players+=("$player")
    else
      paused_players+=("$player")
    fi
  done

  # First, try to find a playing player by priority
  for priority_player in "${PRIORITY[@]}"; do
    for player in "${playing_players[@]}"; do
      if [[ "${player,,}" == *"${priority_player}"* ]]; then
        echo "$player"
        return 0
      fi
    done
  done

  # If no playing player matched priority, use first playing player
  if [[ ${#playing_players[@]} -gt 0 ]]; then
    echo "${playing_players[0]}"
    return 0
  fi

  # Fall back to paused players by priority
  for priority_player in "${PRIORITY[@]}"; do
    for player in "${paused_players[@]}"; do
      if [[ "${player,,}" == *"${priority_player}"* ]]; then
        echo "$player"
        return 0
      fi
    done
  done

  # Final fallback to first available player
  echo "${players[0]}"
  return 0
}

# Get player icon based on player name
get_player_icon() {
  local player="${1,,}"

  case "$player" in
  *spotify*) echo "$ICON_SPOTIFY" ;;
  *youtube* | *yt*) echo "$ICON_YOUTUBE" ;;
  *chromium* | *chrome* | *brave* | *vivaldi*) echo "$ICON_BROWSER" ;;
  *firefox*) echo "$ICON_FIREFOX" ;;
  *vlc*) echo "$ICON_VLC" ;;
  *) echo "$ICON_DEFAULT" ;;
  esac
}

# Get metadata from player
get_metadata() {
  local player="$1"
  local field="$2"

  playerctl --player="$player" metadata "$field" 2>/dev/null || echo ""
}

# Get player status
get_status() {
  local player="$1"

  playerctl --player="$player" status 2>/dev/null || echo "Unknown"
}

# Smart text truncation at word boundaries
truncate_text() {
  local text="$1"
  local max_len="$2"

  # No truncation needed
  if [[ ${#text} -le $max_len ]]; then
    echo "$text"
    return 0
  fi

  # Calculate truncation point (reserve space for ellipsis)
  local truncate_at=$((max_len - 1))
  local candidate="${text:0:$truncate_at}"

  # Find last space for smart word-boundary truncation
  local last_space_idx=0
  for ((i = ${#candidate} - 1; i >= 0; i--)); do
    if [[ "${candidate:$i:1}" == " " ]]; then
      last_space_idx=$i
      break
    fi
  done

  # Use word boundary if it leaves enough text, otherwise hard cut
  if [[ $last_space_idx -gt $MIN_TRUNCATE_LENGTH ]]; then
    echo "${candidate:0:$last_space_idx}…"
  else
    echo "${candidate}…"
  fi
}

# Format output for Waybar
format_output() {
  local player_icon="$1"
  local status_icon="$2"
  local text="$3"

  echo "${player_icon} ${status_icon}  ${text}"
}

# Main execution
main() {
  # Handle control commands
  if [[ $# -gt 0 ]]; then
    local command="$1"
    local active_player

    if active_player=$(select_player 2>/dev/null); then
      case "$command" in
      play-pause)
        playerctl --player="$active_player" play-pause 2>/dev/null || true
        ;;
      next)
        # Check if player supports next
        if playerctl --player="$active_player" metadata 2>/dev/null | grep -q "mpris:trackid"; then
          playerctl --player="$active_player" next 2>/dev/null || true
        fi
        ;;
      previous)
        # Check if player supports previous
        if playerctl --player="$active_player" metadata 2>/dev/null | grep -q "mpris:trackid"; then
          playerctl --player="$active_player" previous 2>/dev/null || true
        fi
        ;;
      *)
        echo "Unknown command: $command" >&2
        exit 1
        ;;
      esac
    else
      # No player available
      exit 1
    fi
    exit 0
  fi

  # Display mode (no arguments)
  # Select active player
  local active_player
  if ! active_player=$(select_player); then
    no_player_output
  fi

  # Get metadata
  local title artist status
  title=$(get_metadata "$active_player" "title")
  artist=$(get_metadata "$active_player" "artist")
  status=$(get_status "$active_player")

  # Apply fallbacks for empty metadata
  title="${title:-Unknown title}"
  artist="${artist:-Unknown artist}"

  # Determine icons
  local player_icon status_icon
  player_icon=$(get_player_icon "$active_player")

  if [[ "$status" == "Playing" ]]; then
    status_icon="$ICON_PLAYING"
  else
    status_icon="$ICON_PAUSED"
  fi

  # Build display text
  local full_text visible_text
  full_text="${title} — ${artist}"
  visible_text="${title} - ${artist}"

  # Truncate if necessary
  visible_text=$(truncate_text "$visible_text" "$MAX_LENGTH")

  # Output for Waybar (line 1: display, line 2: tooltip)
  format_output "$player_icon" "$status_icon" "$visible_text"
  echo "$full_text"
}

# Run main function
main "$@"
