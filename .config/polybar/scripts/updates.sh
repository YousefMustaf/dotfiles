#!/usr/bin/env bash

if ! command -v checkupdates >/dev/null; then
  echo "N/A"
  exit 0
fi

updates=$(checkupdates 2>/dev/null | wc -l)

if [ "$updates" -eq 0 ]; then
  echo "Up to date"
else
  echo "$updates updates"
fi
