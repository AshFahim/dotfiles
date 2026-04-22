#!/usr/bin/env bash

STATE_FILE="/tmp/waybar-netspeed-state"

iface=$(ip route | awk '/default/ {print $5; exit}')

if [ -z "$iface" ] || [ ! -d "/sys/class/net/$iface/statistics" ]; then
    printf "  0.00↓   0.00↑ MB/s\n"
    exit 0
fi

rx_now=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
tx_now=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
time_now=$(date +%s.%N)

if [ -f "$STATE_FILE" ]; then
    read -r old_iface old_rx old_tx old_time < "$STATE_FILE"

    if [ "$old_iface" = "$iface" ]; then
        down=$(awk -v n="$rx_now" -v o="$old_rx" -v t1="$time_now" -v t0="$old_time" '
            BEGIN {
                dt=t1-t0;
                if (dt <= 0) { print "0.00"; exit }
                printf "%.2f", ((n-o)/1000000)/dt
            }')

        up=$(awk -v n="$tx_now" -v o="$old_tx" -v t1="$time_now" -v t0="$old_time" '
            BEGIN {
                dt=t1-t0;
                if (dt <= 0) { print "0.00"; exit }
                printf "%.2f", ((n-o)/1000000)/dt
            }')

        printf "%6s↓ %6s↑ MB/s\n" "$down" "$up"
    else
        printf "  0.00↓   0.00↑ MB/s\n"
    fi
else
    printf "  0.00↓   0.00↑ MB/s\n"
fi

echo "$iface $rx_now $tx_now $time_now" > "$STATE_FILE"