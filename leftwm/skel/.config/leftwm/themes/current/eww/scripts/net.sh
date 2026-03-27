#!/bin/sh

IFACE="$(ip route get 1.1.1.1 2>/dev/null \
  | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}' \
  | head -n1)"

[ -z "$IFACE" ] && { echo "down"; exit 0; }

SSID="$(iwgetid -r 2>/dev/null)"

if [ -n "$SSID" ]; then
  echo "$SSID"
else
  echo "up"
fi
