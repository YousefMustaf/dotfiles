#!/usr/bin/env bash
#
# ytdl.sh - Interactive YT-DLP downloader
#
# Flow:
#   1. Paste a link
#   2. Choose: Audio only  OR  Video (with audio)
#   3. Choose: Single video  OR  Full playlist (+ folder name)
#   4. If Video was chosen: pick from the FULL list of available
#      qualities for that link (each tagged mp4/mkv)
#      If Audio was chosen: automatically grabs the highest quality
#      audio, no extra prompt needed.
#   5. Downloads (video mode embeds English subtitles too)
#
# Requirements: yt-dlp, ffmpeg
#   pip install -U yt-dlp   (or: sudo apt install yt-dlp)
#   sudo apt install ffmpeg
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
  read -rp "${CYAN}${BOLD}Paste the link: ${RESET}" VIDEO_URL
  if [ -z "${VIDEO_URL// /}" ]; then
    echo "${RED}No link entered. Exiting.${RESET}"
    exit 1
  fi
}

# ---------- prompt: audio only or video+audio ----------
ask_download_type() {
  echo
  echo "${BOLD}What do you want to download?${RESET}"
  echo "  1) Audio "
  echo "  2) Video"
  echo
  read -rp "${CYAN}${BOLD}Enter choice [1-2]: ${RESET}" TYPE_CHOICE

  case "$TYPE_CHOICE" in
  1) DL_TYPE="audio" ;;
  2) DL_TYPE="video" ;;
  *)
    echo "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
    ;;
  esac
}

# ---------- prompt for single video or full playlist ----------
ask_mode() {
  echo
  echo "${BOLD}What are you downloading?${RESET}"
  echo "  1) Single item"
  echo "  2) Full playlist (downloaded in order)"
  echo
  read -rp "${CYAN}${BOLD}Enter choice [1-2]: ${RESET}" MODE_CHOICE

  case "$MODE_CHOICE" in
  1)
    PLAYLIST_FLAG="--no-playlist"
    FORMAT_FETCH_FLAG="--no-playlist"
    OUTPUT_TEMPLATE="${DOWNLOAD_DIR}/%(title)s.%(ext)s"
    ;;
  2)
    PLAYLIST_FLAG="--yes-playlist"
    # only inspect the first item to build the quality menu
    FORMAT_FETCH_FLAG="--playlist-items 1"
    echo
    read -rp "${CYAN}${BOLD}Folder name for this playlist: ${RESET}" PLAYLIST_DIR
    if [ -z "${PLAYLIST_DIR// /}" ]; then
      echo "${RED}No folder name entered. Exiting.${RESET}"
      exit 1
    fi
    OUTPUT_TEMPLATE="${DOWNLOAD_DIR}/${PLAYLIST_DIR}/%(playlist_index)03d - %(title)s.%(ext)s"
    ;;
  *)
    echo "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
    ;;
  esac
}

# ---------- quick shortcuts for the most commonly used qualities ----------
ask_quality() {
  echo
  echo "${BOLD}Quick picks:${RESET}"
  echo "  1) 480p   [mp4]"
  echo "  2) 720p   [mp4]"
  echo "  3) 1080p  [mp4]"
  echo "  4) See full list of all available qualities"
  echo
  read -rp "${CYAN}${BOLD}Enter choice [1-4]: ${RESET}" QUICK_CHOICE

  case "$QUICK_CHOICE" in
  1)
    FORMAT="bestvideo[height<=480]+bestaudio/best[height<=480]"
    MERGE_FORMAT="mp4"
    LABEL="480p (mp4)"
    return
    ;;
  2)
    FORMAT="bestvideo[height<=720]+bestaudio/best[height<=720]"
    MERGE_FORMAT="mp4"
    LABEL="720p (mp4)"
    return
    ;;
  3)
    FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]"
    MERGE_FORMAT="mp4"
    LABEL="1080p (mp4)"
    return
    ;;
  4)
    : # fall through to full list below
    ;;
  *)
    echo "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
    ;;
  esac

  ask_quality_full_list
}

# ---------- list every available video quality for this link ----------
ask_quality_full_list() {
  echo
  echo "${CYAN}Fetching available qualities for this link...${RESET}"

  # grab id / ext / resolution / fps columns for entries that have a real resolution
  # (skips audio-only rows and storyboard rows)
  local raw
  raw=$(yt-dlp -F $FORMAT_FETCH_FLAG "$VIDEO_URL" 2>/dev/null |
    awk '$3 ~ /^[0-9]+x[0-9]+$/ {print $1, $2, $3, $4}')

  if [ -z "$raw" ]; then
    echo "${RED}Could not fetch a quality list, falling back to best available.${RESET}"
    FORMAT="bestvideo+bestaudio/best"
    MERGE_FORMAT="mp4"
    LABEL="best available (mp4)"
    return
  fi

  IDS=()
  EXTS=()
  RESES=()
  FPSS=()
  LABELS=()
  while read -r id ext res fps; do
    IDS+=("$id")
    RESES+=("$res")
    if [[ "$fps" =~ ^[0-9]+$ ]]; then
      FPSS+=("${fps}fps")
    else
      FPSS+=("")
    fi
    # yt-dlp source formats are natively mp4 or webm; anything that
    # isn't mp4 gets merged into an mkv container so audio always fits
    if [ "$ext" = "mp4" ]; then
      LABELS+=("mp4")
    else
      LABELS+=("mkv")
    fi
  done <<<"$raw"

  echo
  echo "${BOLD}Available qualities:${RESET}"
  for i in "${!IDS[@]}"; do
    printf "  %2d) %-14s %-7s [%s]\n" "$((i + 1))" "${RESES[$i]}" "${FPSS[$i]}" "${LABELS[$i]}"
  done
  echo

  read -rp "${CYAN}${BOLD}Enter choice: ${RESET}" QCHOICE
  if ! [[ "$QCHOICE" =~ ^[0-9]+$ ]] || [ "$QCHOICE" -lt 1 ] || [ "$QCHOICE" -gt "${#IDS[@]}" ]; then
    echo "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
  fi

  local idx=$((QCHOICE - 1))
  FORMAT="${IDS[$idx]}+bestaudio/best"
  MERGE_FORMAT="${LABELS[$idx]}"
  LABEL="${RESES[$idx]} (${LABELS[$idx]})"
}

# ---------- run the download ----------
do_download() {
  echo

  if [ "$DL_TYPE" = "audio" ]; then
    echo "${GREEN}${BOLD}Downloading highest quality audio...${RESET}"
    echo "Saving to: ${DOWNLOAD_DIR}"
    echo

    yt-dlp \
      -f "bestaudio/best" \
      --extract-audio \
      --audio-format best \
      --audio-quality 0 \
      --embed-metadata \
      --embed-thumbnail \
      "$PLAYLIST_FLAG" \
      -o "$OUTPUT_TEMPLATE" \
      "$VIDEO_URL"
  else
    echo "${GREEN}${BOLD}Downloading ${LABEL} with English subtitles...${RESET}"
    echo "Saving to: ${DOWNLOAD_DIR}"
    echo

    yt-dlp \
      -f "$FORMAT" \
      --merge-output-format "$MERGE_FORMAT" \
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
  fi

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
ask_download_type
ask_mode

if [ "$DL_TYPE" = "video" ]; then
  ask_quality
fi

do_download
