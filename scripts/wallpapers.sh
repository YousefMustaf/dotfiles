#!/usr/bin/env bash

set -euo pipefail

WALL_DIR="$HOME/walls"
CACHE_FILE="$HOME/.cache/random-wallpaper-last"

# Ensure the cache directory exists
mkdir -p "$(dirname "$CACHE_FILE")"

# Read all supported wallpapers
mapfile -d '' wallpapers < <(
    find "$WALL_DIR" -type f \
        \( -iname '*.jpg' \
        -o -iname '*.jpeg' \
        -o -iname '*.png' \
        -o -iname '*.webp' \
        -o -iname '*.bmp' \) \
        -print0
)

# Exit if no wallpapers exist
(( ${#wallpapers[@]} > 0 )) || {
    echo "No wallpapers found in $WALL_DIR"
    exit 1
}

last=""
[[ -f "$CACHE_FILE" ]] && last="$(<"$CACHE_FILE")"

# Pick a different wallpaper from the previous one
while :; do
    wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    [[ "$wallpaper" != "$last" || ${#wallpapers[@]} -eq 1 ]] && break
done

printf '%s' "$wallpaper" > "$CACHE_FILE"

# Set the wallpaper
feh --bg-fill "$wallpaper"
