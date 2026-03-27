#!/bin/sh

if command -v xtitle >/dev/null 2>&1; then
  xtitle | head -n1
else
  echo ""
fi
