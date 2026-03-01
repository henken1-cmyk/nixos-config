#!/usr/bin/env bash
# Start waybar visible, hide when cursor moves away, show on top-edge hover

SHOW_THRESHOLD=3  # px from top — cursor must be near edge to show bar
HIDE_THRESHOLD=80 # px from top — moving below this hides bar

# Kill any other running instances to prevent double-toggling
for pid in $(pgrep -f waybar-autohide.sh 2>/dev/null); do
    [[ "$pid" != "$$" ]] && kill "$pid" 2>/dev/null
done

pkill waybar 2>/dev/null
sleep 0.5
waybar &
sleep 2.0  # wait for waybar to fully initialize

visible=true  # waybar starts visible; loop will hide it when cursor moves away

while true; do
    y=$(hyprctl cursorpos -j 2>/dev/null | jq -r '.y' 2>/dev/null)
    # skip iteration if cursor position is unavailable
    [[ -z "$y" || "$y" == "null" ]] && sleep 0.05 && continue
    y=$(echo "$y" | cut -d. -f1)

    if [[ "$y" -le "$SHOW_THRESHOLD" ]] && [[ "$visible" == "false" ]]; then
        pkill -SIGUSR1 waybar
        visible=true
    elif [[ "$y" -gt "$HIDE_THRESHOLD" ]] && [[ "$visible" == "true" ]]; then
        pkill -SIGUSR1 waybar
        visible=false
    fi

    sleep 0.05
done
