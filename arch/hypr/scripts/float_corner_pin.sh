#!/bin/bash

# Check if current window is pinned
PINNED=$(hyprctl activewindow -j | jq -r '.pinned')

if [ "$PINNED" = "true" ]; then
    # Toggle off: unpin and unfloat
    hyprctl dispatch pin
    hyprctl dispatch settiled
else
    # Toggle on: float, move to corner, pin
    hyprctl dispatch setfloating
    sleep 0.1
    hyprctl dispatch movewindow mon:eDP-1
    sleep 0.1
    hyprctl dispatch resizeactive exact 350 250
    sleep 0.05

    read MON_X MON_Y MON_W MON_H MON_SCALE < <(hyprctl monitors -j | \
      jq -r '.[] | select(.name == "eDP-1") | "\(.x) \(.y) \(.width) \(.height) \(.scale)"')

    LOGICAL_W=$(awk "BEGIN {printf \"%d\", $MON_W / $MON_SCALE}")
    LOGICAL_H=$(awk "BEGIN {printf \"%d\", $MON_H / $MON_SCALE}")

    TARGET_X=$(( MON_X + LOGICAL_W - 370 ))
    TARGET_Y=$(( MON_Y + LOGICAL_H - 270 ))

    hyprctl dispatch moveactive exact $TARGET_X $TARGET_Y
    sleep 0.05
    hyprctl dispatch pin
fi