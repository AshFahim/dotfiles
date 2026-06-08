#!/usr/bin/env bash

# Check if current window is pinned
PINNED=$(hyprctl activewindow -j | jq -r '.pinned')

if [ "$PINNED" = "true" ]; then
    # Toggle off: unpin and unfloat
    hyprctl dispatch 'hl.dsp.window.pin()'
    hyprctl dispatch 'hl.dsp.window.float({ action = "off" })'
else
    MONITOR_NAME=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' | head -n1)

    if [ -z "$MONITOR_NAME" ]; then
        exit 1
    fi

    # Toggle on: float, move to corner, pin
    hyprctl dispatch 'hl.dsp.window.float({ action = "set" })'
    sleep 0.1
    hyprctl dispatch "hl.dsp.window.move({ monitor = \"$MONITOR_NAME\" })"
    sleep 0.1
    hyprctl dispatch 'hl.dsp.window.resize({ x = 350, y = 250 })'
    sleep 0.05

    read MON_X MON_Y MON_W MON_H MON_SCALE < <(hyprctl monitors -j | \
      jq -r --arg name "$MONITOR_NAME" '.[] | select(.name == $name) | "\(.x) \(.y) \(.width) \(.height) \(.scale)"')

    LOGICAL_W=$(awk "BEGIN {printf \"%d\", $MON_W / $MON_SCALE}")
    LOGICAL_H=$(awk "BEGIN {printf \"%d\", $MON_H / $MON_SCALE}")

    TARGET_X=$(( MON_X + LOGICAL_W - 370 ))
    TARGET_Y=$(( MON_Y + LOGICAL_H - 270 ))

    hyprctl dispatch "hl.dsp.window.move({ x = $TARGET_X, y = $TARGET_Y })"
    sleep 0.05
    hyprctl dispatch 'hl.dsp.window.pin()'
fi
