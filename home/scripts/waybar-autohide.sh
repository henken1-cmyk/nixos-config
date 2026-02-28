#!/usr/bin/env bash
# Start waybar hidden, show on top-edge hover, hide when cursor moves away

SHOW_THRESHOLD=2  # px from top to show bar
HIDE_THRESHOLD=50 # px from top — moving below this hides bar

waybar &
sleep 0.8
pkill -SIGUSR1 waybar  # start hidden
visible=false

while true; do
    y=$(hyprctl cursorpos -j 2>/dev/null | jq -r '.y' 2>/dev/null | cut -d. -f1)
    y=${y:-9999}

    if [[ "$y" -le "$SHOW_THRESHOLD" ]] && [[ "$visible" == "false" ]]; then
        pkill -SIGUSR1 waybar
        visible=true
    elif [[ "$y" -gt "$HIDE_THRESHOLD" ]] && [[ "$visible" == "true" ]]; then
        pkill -SIGUSR1 waybar
        visible=false
    fi

    sleep 0.05
done
