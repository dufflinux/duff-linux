#!/bin/sh
leftwm-state -q -t '{{ workspaces | map: "tag" | first }}' 2>/dev/null || echo "1"
