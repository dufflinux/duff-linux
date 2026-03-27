#!/bin/sh

if command -v pamixer >/dev/null 2>&1; then
  MUTED=$(pamixer --get-mute)
  VOL=$(pamixer --get-volume)
  [ "$MUTED" = "true" ] && echo "muted" || echo "${VOL}%"
else
  amixer get Master 2>/dev/null \
    | awk -F'[][]' 'END{print $2}'
fi
