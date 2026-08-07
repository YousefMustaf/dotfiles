#!/usr/bin/env bash

status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
  playerctl metadata --format "󰎈 {{artist}} - {{title}}"
else
  echo "󰝚 Nothing Playing"
fi
