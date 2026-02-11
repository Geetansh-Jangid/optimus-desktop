#!/bin/bash

# Configuration
LOW_LIMIT=10
CRITICAL_LIMIT=5
MAX_LIMIT=93

while true; do
    # Get battery status and capacity
    # Assumes battery is BAT0 (check /sys/class/power_supply/ for others)
    BATTERY_PATH="/sys/class/power_supply/BAT1"
    CAPACITY=$(cat "$BATTERY_PATH/capacity")
    STATUS=$(cat "$BATTERY_PATH/status")

    # 1. Notify when battery hits 10% and is discharging
    if [ "$CAPACITY" -le "$LOW_LIMIT" ] && [ "$STATUS" = "Discharging" ]; then
        notify-send -u critical "Battery Low" "Battery is at $CAPACITY%. Plug in the charger!"
    
    # 2. Suspend when battery hits 5%
    elif [ "$CAPACITY" -le "$CRITICAL_LIMIT" ] && [ "$STATUS" = "Discharging" ]; then
        notify-send -u critical "System Suspending" "Battery critical ($CAPACITY%). Suspending now."
        sleep 2
        systemctl suspend

    # 3. Notify to remove charger at 93%
    elif [ "$CAPACITY" -ge "$MAX_LIMIT" ] && [ "$STATUS" = "Charging" ]; then
        notify-send -u normal "Battery Charged" "Battery is at $CAPACITY%. You can remove the charger."
    fi

    # Wait 60 seconds before checking again to save resources
    sleep 30
done