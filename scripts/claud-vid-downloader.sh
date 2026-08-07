#!/usr/bin/env bash
#
# ytdl.sh - Interactive YT-DLP downloader
# Prompts for a link, whether it's a single video or a full playlist,
# and a quality level, then downloads with embedded English subtitles.
# Playlists are downloaded in order into their own numbered folder.
#
# Requirements: yt-dlp, ffmpeg
#   Install on most Linux distros:
#     pip install -U yt-dlp   (or: sudo apt install yt-dlp)
#     sudo apt install ffmpeg
#
# Usage:
#   chmod +x ytdl.sh
#   ./ytdl.sh
#

set -euo pipefail

# ---------- colors (optional, purely cosmetic) ----------
BOLD=$(tput bold 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")

# ---------- dependency checks ----------
check_dependencies() {
  local missing=()
  command -v yt-dlp >/dev/null 2>&1 || missing+=("yt-dlp")
  command -v ffmpeg >/dev/null 2>&1 || missing+=("ffmpeg")

  if [ "${#missing[@]}" -ne 0 ]; then
    echo "${RED}Missing required tool(s): ${missing[*]}${RESET}"
    echo "Install them first, e.g.:"
    echo "  pip install -U yt-dlp"
    echo "  sudo apt install ffmpeg"
    exit 1
  fi
}

# ---------- where downloads go ----------
DOWNLOAD_DIR="${HOME}/Videos/ytdl"
mkdir -p "$DOWNLOAD_DIR"

# ---------- prompt for the link ----------
ask_link() {
  echo
  read -rp "${CYAN}${BOLD}Paste the video link: ${RESET}" VIDEO_URL
  if [ -z "${VIDEO_URL// /}" ]; then
    echo "${RED}No link entered. Exiting.${RESET}"
    exit 1
  fi
}

# ---------- prompt for single video or full playlist ----------
ask_mode() {
  echo
  echo "${BOLD}What are you downloading?${RESET}"
  echo "  1) Single video"
  echo "  2) Full playlist (downloaded in order)"
  echo
  read -rp "${CYAN}${BOLD}Enter choice [1-2]: ${RESET}" MODE_CHOICE

  case "$MODE_CHOICE" in
  1)
    PLAYLIST_FLAG="--no-playlist"
    OUTPUT_TEMPLATE="${DOWNLOAD_DIR}/%(title)s.%(ext)s"
    ;;
  2)
    PLAYLIST_FLAG="--yes-playlist"
    echo
    read -rp "${CYAN}${BOLD}Folder name for this playlist: ${RESET}" PLAYLIST_DIR
    if [ -z "${PLAYLIST_DIR// /}" ]; then
      echo "${RED}No folder name entered. Exiting.${RESET}"
      exit 1
    fi
    # playlist_index keeps files numbered/sorted in playlist order,
    # grouped into the folder name you chose
    OUTPUT_TEMPLATE="${DOWNLOAD_DIR}/${PLAYLIST_DIR}/%(playlist_index)03d - %(title)s.%(ext)s"
    ;;
  *)
    echo "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
    ;;
  esac
}

# ---------- prompt for quality ----------
ask_quality() {
  echo
  echo "${BOLD}Choose quality:${RESET}"
  echo "  1) High    (best available, up to 4K/1080p+)"
  echo "  2) Medium  (up to 720p)"
  echo "  3) Low     (up to 480p)"
  echo
  read -rp "${CYAN}${BOLD}Enter choice [1-3]: ${RESET}" CHOICE

  case "$CHOICE" in
  1)
    FORMAT="bestvideo*+bestaudio/best"
    LABEL="High"
    ;;
  2)
    FORMAT="bestvideo[height<=720]+bestaudio/best[height<=720]"
    LABEL="Medium"
    ;;
  3)
    FORMAT="bestvideo[height<=480]+bestaudio/best[height<=480]"
    LABEL="Low"
    ;;
  *)
    echo "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
    ;;
  esac
}

# ---------- run the download ----------
do_download() {
  echo
  echo "${GREEN}${BOLD}Downloading (${LABEL} quality) with English subtitles...${RESET}"
  echo "Saving to: ${DOWNLOAD_DIR}"
  echo

  yt-dlp \
    -f "$FORMAT" \
    --merge-output-format mp4 \
    --write-subs \
    --write-auto-subs \
    --sub-langs "en.*" \
    --embed-subs \
    --convert-subs srt \
    --embed-metadata \
    --embed-thumbnail \
    "$PLAYLIST_FLAG" \
    -o "$OUTPUT_TEMPLATE" \
    "$VIDEO_URL"

  echo
  echo "${GREEN}${BOLD}Done! Saved in ${DOWNLOAD_DIR}${RESET}"
}

# ---------- main ----------
clear
echo "${BOLD}=========================================${RESET}"
echo "${BOLD}   YT-DLP Interactive Downloader${RESET}"
echo "${BOLD}=========================================${RESET}"

check_dependencies
ask_link
ask_mode
ask_quality
do_download
