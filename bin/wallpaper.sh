#!/bin/sh

# Define the state file to track the last used wallpaper for cycling
STATE_FILE="${HOME}/.wallpaper_index"

# Define the target symlink path
SYMLINK_PATH="${HOME}/.config/current/wallpaper.jpg"

set_wallpaper_niri() {
    # Directory is the symlink we switch
    dir="${HOME}/.config/current/wallpapers"

    if [ ! -d "$dir" ]; then
        echo "Error: Directory $dir does not exist. Skipping swww."
        exit 1
    fi

    # --- 1. Get a sorted, filtered list of all wallpapers ---
    # Sort ensures a consistent, predictable order for cycling (A -> B -> C...)
    ALL_WALLPAPERS=$(find -H "$dir" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' \) | sort)
    
    # Convert the list into a bash array
    readarray -t WALLPAPER_ARRAY <<< "$ALL_WALLPAPERS"
    TOTAL_COUNT=${#WALLPAPER_ARRAY[@]}
    BG="" # Initialize BG

    # Check if any wallpapers were found with the target extensions
    if [ $TOTAL_COUNT -eq 0 ]; then
        # Fallback logic: If no JPG/PNG, try to find *any* file
        echo "Warning: No .jpg or .png files found in $dir. Attempting generic fallback."
        
        # Original fallback logic, but without shuf
        BG_FALLBACK="$(find "$dir" -maxdepth 1 -type f | sort | head -n1)"
        
        if [ -z "$BG_FALLBACK" ]; then
            echo "Error: Directory $dir is empty or find is broken. Skipping swww."
            exit 1
        else
            echo "Warning: Using generic file: $BG_FALLBACK."
            BG="$BG_FALLBACK"
        fi
    else
        # --- 2. Implement the "Next" Cycling Logic ---

        LAST_USED=""
        if [ -f "$STATE_FILE" ]; then
            LAST_USED=$(cat "$STATE_FILE")
        fi

        NEXT_INDEX=0 # Default to the first wallpaper

        # Find the index of the last used wallpaper in the sorted array
        for i in "${!WALLPAPER_ARRAY[@]}"; do
            if [[ "${WALLPAPER_ARRAY[$i]}" == "$LAST_USED" ]]; then
                # Found the last one! Calculate the index for the next one.
                NEXT_INDEX=$((i + 1))
                
                # Check for wrap-around (loop back to 0 if we hit the end)
                if [ "$NEXT_INDEX" -ge "$TOTAL_COUNT" ]; then
                    NEXT_INDEX=0
                fi
                break # Exit the loop once the index is found
            fi
        done

        # The new wallpaper is the one at NEXT_INDEX
        BG="${WALLPAPER_ARRAY[$NEXT_INDEX]}"
        
        # --- 3. Update the state file with the new path ---
        echo "$BG" > "$STATE_FILE"
    fi
    # ----------------------------------------------------
    
    # Final check for BG
    if [ -z "$BG" ]; then
        echo "Error: Could not determine a wallpaper file. Exiting."
        exit 1
    fi

    # --- 4. Create the Symlink Feature ---
    # a. Ensure the target directory exists
    mkdir -p "$(dirname "$SYMLINK_PATH")"
    
    # b. Remove any existing symlink or file at the target path
    rm -f "$SYMLINK_PATH"
    
    # c. Create the new symlink
    ln -s "$BG" "$SYMLINK_PATH"
    echo "Symlinked current wallpaper to: $SYMLINK_PATH"
    # ------------------------------------

    PROGRAM="swww-daemon"
    trans_type="grow"

    # Log which file is being set
    echo "Setting wallpaper: $BG"

    if pgrep "$PROGRAM" >/dev/null; then
        swww img "$BG" --transition-fps 240 --transition-type "$trans_type" --transition-duration 0.5
    else
        swww-daemon && swww img "$BG" --transition-fps 244 --transition-type "$trans_type" --transition-duration 0.5
    fi
}

set_wallpaper_niri
