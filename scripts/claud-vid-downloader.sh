#!/usr/bin/env bash
#
# claud-vid-downloader.sh - Interactive YT-DLP downloader
#Interactive YT-DLP downloader

# ╔══════════════════════════════════════════════════════════════════╗
# ║  claud-vid-downloader.sh - Interactive YT-DLP downloader           ║
# ║  READ THIS BEFORE FIRST RUN - dependency checklist below           ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# ---------------------------------------------------------------------
# WHAT THIS SCRIPT DOES
# ---------------------------------------------------------------------
#   1. Paste a link
#   2. Choose: Audio only  OR  Video (with audio)
#   3. Choose: Single video  OR  Full playlist (+ folder name)
#   4. If Video: pick a quality (quick picks or a cleaned-up full list)
#      If Audio: automatically grabs the highest quality audio
#
# ---------------------------------------------------------------------
# DEPENDENCIES - install ALL of these before using the script
# ---------------------------------------------------------------------
#
#   [1] yt-dlp  (required - does the actual downloading)
#         pip install -U yt-dlp --break-system-packages
#         # or, if you prefer apt (may lag behind pip in version):
#         sudo apt update && sudo apt install yt-dlp
#
#   [2] ffmpeg  (required - merges video+audio, embeds subs/thumbnail)
#         sudo apt install ffmpeg
#
#   [3] bgutil-pot PO Token provider (REQUIRED as of mid-2026 - fixes
#       "HTTP 403 Forbidden" / "Requested format is not available"
#       errors on basically every video)
#         As of 2026, YouTube requires a Proof-of-Origin (PO) Token to
#         serve real HTTPS video/audio formats. Without one:
#           - the "tv" client's formats come back DRM-protected
#           - the "web"/"mweb" clients only expose SABR streaming URLs
#             (which yt-dlp/ffmpeg cannot download) and get skipped
#         The old workaround of forcing tv/web player clients no
#         longer avoids this - a PO token provider is now mandatory.
#
#         Setup (one-time):
#           mkdir -p ~/.local/bin ~/.config/yt-dlp/plugins
#           wget "https://github.com/jim60105/bgutil-ytdlp-pot-provider-rs/releases/latest/download/bgutil-pot-linux-x86_64" \
#             -O ~/.local/bin/bgutil-pot
#           chmod +x ~/.local/bin/bgutil-pot
#           # Grab the matching plugin zip's version tag from the same
#           # release page, then (do NOT unzip it - drop it in as-is):
#           wget "https://github.com/jim60105/bgutil-ytdlp-pot-provider-rs/releases/download/<version>/bgutil-ytdlp-pot-provider-rs.zip" \
#             -O ~/.config/yt-dlp/plugins/bgutil-ytdlp-pot-provider-rs.zip
#
#         Verify it worked:
#           yt-dlp -v --extractor-args "youtube:player_client=web" \
#             --extractor-args "youtubepot-bgutilcli:cli_path=$HOME/.local/bin/bgutil-pot" \
#             "https://www.youtube.com/watch?v=dQw4w9WgXcQ" 2>&1 | grep -i pot
#         (You should see "PO Token Providers: bgutil:cli-X.X.X (external)"
#         with no "unavailable" tag.)
#
#         This script checks for ~/.local/bin/bgutil-pot at startup and
#         will refuse to run without it, since downloads will otherwise
#         fail on nearly every video.
#
#   [4] A terminal emulator with `tput` support (Alacritty, Kitty,
#       GNOME Terminal, etc.) - only affects the colored/boxed output,
#       the script still works without it, just plain text.
#
#   [5] i3 users only - launch this script THROUGH a terminal command,
#       not i3's raw `exec`. i3's `exec` doesn't attach a tty, which
#       silently breaks the `read` prompts this script relies on.
#       Example keybinding (~/.config/i3/config):
#         bindsym $mod+Shift+d exec i3-sensible-terminal -e bash -c \
#           "/home/dark/scripts/claud-vid-downloader.sh; exec bash"
#       The trailing `; exec bash` keeps the window open after the
#       script's own wait-screen loop is quit, so you can still read
#       output if something closed unexpectedly.
#
# ---------------------------------------------------------------------
# QUICK ONE-LINE SETUP (copy-paste all of it)
# ---------------------------------------------------------------------
#   sudo apt update && sudo apt install -y ffmpeg && \
#   pip install -U "yt-dlp[default,curl-cffi]" --break-system-packages
#
# ---------------------------------------------------------------------
# USAGE
# ---------------------------------------------------------------------
#   chmod +x claud-vid-downloader.sh
#   ./claud-vid-downloader.sh
#
# ---------------------------------------------------------------------
# TROUBLESHOOTING
# ---------------------------------------------------------------------
#   - "command not found: yt-dlp" or "ffmpeg"
#       -> You skipped a dependency above. Install it, restart your
#          terminal, and try again.
#   - "HTTP Error 403: Forbidden" or "Requested format is not
#     available" on a specific video
#       -> Set up the bgutil-pot PO Token provider (dependency [3]
#          above) - this is now required for nearly all videos, not
#          an edge case. If it's already set up and this still happens
#          occasionally, it's usually a transient YouTube throttle -
#          the script auto-retries a few times; if it still fails,
#          just try that same video again in a minute or two.
#   - yt-dlp seems outdated / weird errors on videos that should work
#       -> YouTube changes its site often. Update yt-dlp:
#          pip install -U yt-dlp --break-system-packages
#   - Script window closes immediately with no message
#       -> Make sure you're launching it through a real terminal (see
#          dependency [5] above), not a raw i3 `exec`.
#

# NOTE: deliberately NOT using `set -e`. This script runs interactively
# and must never die silently on a bad exit code - every failure is
# caught, shown to you, and followed by a "press a key" prompt instead
# of closing the terminal.
set -uo pipefail

# ---------- colors (optional, purely cosmetic) ----------
BOLD=$(tput bold 2>/dev/null || echo "")
DIM=$(tput dim 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
BLUE=$(tput setaf 4 2>/dev/null || echo "")

DOWNLOAD_DIR="${HOME}/Videos/ytdl"
mkdir -p "$DOWNLOAD_DIR"

# ---------- PO Token provider setup ----------
# Required as of 2026: the "web" client needs a valid PO Token or its
# formats get skipped (SABR-only). bgutil-pot generates one locally.
# See dependency [3] in the header comment for one-time setup.
BGUTIL_POT_BIN="${HOME}/.local/bin/bgutil-pot"
YTDLP_POT_ARGS=(
  --extractor-args "youtube:player_client=web"
  --extractor-args "youtubepot-bgutilcli:cli_path=${BGUTIL_POT_BIN}"
)

# ---------- visual helpers ----------
hr() { printf "${DIM}%s${RESET}\n" "────────────────────────────────────────────────"; }

banner() {
  clear
  printf "${CYAN}${BOLD}"
  printf "╔════════════════════════════════════════════════╗\n"
  printf "║          YT-DLP  INTERACTIVE  DOWNLOADER        ║\n"
  printf "╚════════════════════════════════════════════════╝\n"
  printf "${RESET}\n"
}

info() { printf "${BLUE}${BOLD}➜${RESET}  %s\n" "$1"; }
ok() { printf "${GREEN}${BOLD}✔${RESET}  %s\n" "$1"; }
warn() { printf "${YELLOW}${BOLD}⚠${RESET}  %s\n" "$1"; }
fail() { printf "${RED}${BOLD}✘${RESET}  %s\n" "$1"; }

press_any_key() {
  echo
  read -n 1 -s -r -p "${DIM}Press any key to continue...${RESET}"
  echo
}

# Shows the "what now" screen at the end of a run (success OR failure).
# Returns via global NEXT_ACTION = "new" or "quit"
wait_screen() {
  echo
  hr
  printf "${BOLD}  [n]${RESET} New download    ${BOLD}[q]${RESET} Quit\n"
  hr
  while true; do
    read -n 1 -s -r -p "${CYAN}${BOLD}Choice: ${RESET}" key
    echo
    case "$key" in
    n | N)
      NEXT_ACTION="new"
      return
      ;;
    q | Q)
      NEXT_ACTION="quit"
      return
      ;;
    *) warn "Press n or q." ;;
    esac
  done
}

# ---------- dependency checks ----------
check_dependencies() {
  local missing=()
  command -v yt-dlp >/dev/null 2>&1 || missing+=("yt-dlp")
  command -v ffmpeg >/dev/null 2>&1 || missing+=("ffmpeg")

  if [ "${#missing[@]}" -ne 0 ]; then
    fail "Missing required tool(s): ${missing[*]}"
    echo "Install them first, e.g.:"
    echo "  pip install -U yt-dlp"
    echo "  sudo apt install ffmpeg"
    press_any_key
    exit 1
  fi

  if [ ! -x "$BGUTIL_POT_BIN" ]; then
    fail "PO Token provider not found at: ${BGUTIL_POT_BIN}"
    echo "${DIM}As of 2026, YouTube requires a PO Token for the 'web' client to${RESET}"
    echo "${DIM}return real formats - without it, almost every download will fail${RESET}"
    echo "${DIM}with a 403 or 'Requested format is not available'.${RESET}"
    echo
    echo "One-time setup:"
    echo "  mkdir -p ~/.local/bin ~/.config/yt-dlp/plugins"
    echo "  wget \"https://github.com/jim60105/bgutil-ytdlp-pot-provider-rs/releases/latest/download/bgutil-pot-linux-x86_64\" -O ~/.local/bin/bgutil-pot"
    echo "  chmod +x ~/.local/bin/bgutil-pot"
    echo "  # then grab bgutil-ytdlp-pot-provider-rs.zip from the same release page and"
    echo "  # drop it (unextracted) into ~/.config/yt-dlp/plugins/"
    echo
    echo "See dependency [3] at the top of this script for the full walkthrough."
    press_any_key
    exit 1
  fi
}

# ---------- prompt for the link ----------
ask_link() {
  while true; do
    echo
    read -rp "${CYAN}${BOLD}Paste the link: ${RESET}" VIDEO_URL
    if [ -n "${VIDEO_URL// /}" ]; then
      return
    fi
    warn "No link entered, try again."
  done
}

# ---------- prompt: audio only or video+audio ----------
ask_download_type() {
  while true; do
    echo
    echo "${BOLD}What do you want to download?${RESET}"
    echo "  1) Audio"
    echo "  2) Video"
    read -rp "${CYAN}${BOLD}Enter choice [1-2]: ${RESET}" TYPE_CHOICE
    case "$TYPE_CHOICE" in
    1)
      DL_TYPE="audio"
      return
      ;;
    2)
      DL_TYPE="video"
      return
      ;;
    *) warn "Invalid choice, try again." ;;
    esac
  done
}

# ---------- prompt for single video or full playlist ----------
ask_mode() {
  while true; do
    echo
    echo "${BOLD}What are you downloading?${RESET}"
    echo "  1) Single item"
    echo "  2) Full playlist (downloaded in order)"
    read -rp "${CYAN}${BOLD}Enter choice [1-2]: ${RESET}" MODE_CHOICE

    case "$MODE_CHOICE" in
    1)
      PLAYLIST_FLAG="--no-playlist"
      FORMAT_FETCH_FLAG="--no-playlist"
      OUTPUT_TEMPLATE="${DOWNLOAD_DIR}/%(title)s.%(ext)s"
      TARGET_DIR="$DOWNLOAD_DIR"
      return
      ;;
    2)
      PLAYLIST_FLAG="--yes-playlist"
      FORMAT_FETCH_FLAG="--playlist-items 1"
      echo
      read -rp "${CYAN}${BOLD}Folder name for this playlist: ${RESET}" PLAYLIST_DIR
      if [ -z "${PLAYLIST_DIR// /}" ]; then
        warn "No folder name entered, try again."
        continue
      fi
      OUTPUT_TEMPLATE="${DOWNLOAD_DIR}/${PLAYLIST_DIR}/%(playlist_index)03d - %(title)s.%(ext)s"
      TARGET_DIR="${DOWNLOAD_DIR}/${PLAYLIST_DIR}"
      return
      ;;
    *)
      warn "Invalid choice, try again."
      ;;
    esac
  done
}

# ---------- quick shortcuts for the most commonly used qualities ----------
# FORMAT is height-based (bestvideo[height<=N]+bestaudio) rather than a raw
# format id. Raw ids can differ per playlist item, which is a common reason
# a script "fails" on some videos while a manual `yt-dlp -f 137+140` works
# on the one video you tested. Height-based selectors are portable across
# every item in a playlist and always fall back gracefully.
ask_quality() {
  while true; do
    echo
    echo "${BOLD}Quick picks:${RESET}"
    echo "  1) 480p"
    echo "  2) 720p"
    echo "  3) 1080p"
    echo "  4) 1440p (2K)"
    echo "  5) 2160p (4K)"
    echo "  6) See full list of available qualities"
    read -rp "${CYAN}${BOLD}Enter choice [1-6]: ${RESET}" QUICK_CHOICE

    case "$QUICK_CHOICE" in
    1)
      set_quality_by_height 480
      return
      ;;
    2)
      set_quality_by_height 720
      return
      ;;
    3)
      set_quality_by_height 1080
      return
      ;;
    4)
      set_quality_by_height 1440
      return
      ;;
    5)
      set_quality_by_height 2160
      return
      ;;
    6)
      ask_quality_full_list
      return
      ;;
    *) warn "Invalid choice, try again." ;;
    esac
  done
}

set_quality_by_height() {
  local h="$1"
  FORMAT="bestvideo[height<=${h}]+bestaudio/best[height<=${h}]"
  LABEL="${h}p"
}

# ---------- list available video qualities for this link (decluttered) ----------
ask_quality_full_list() {
  echo
  info "Fetching available qualities for this link..."

  local raw
  raw=$(yt-dlp "${YTDLP_POT_ARGS[@]}" -F $FORMAT_FETCH_FLAG "$VIDEO_URL" 2>/dev/null |
    awk '$3 ~ /^[0-9]+x[0-9]+$/ {print $3}')

  if [ -z "$raw" ]; then
    warn "Could not fetch a quality list, falling back to best available."
    FORMAT="bestvideo+bestaudio/best"
    LABEL="best available"
    return
  fi

  # extract heights, drop anything below 480p (the 144/240/360p clutter),
  # dedupe, sort descending
  local heights
  heights=$(echo "$raw" | awk -Fx '{print $2}' | awk '$1>=480' | sort -rnu)

  if [ -z "$heights" ]; then
    warn "Only low-resolution formats found; falling back to best available."
    FORMAT="bestvideo+bestaudio/best"
    LABEL="best available"
    return
  fi

  HEIGHTS=()
  while read -r h; do HEIGHTS+=("$h"); done <<<"$heights"

  echo
  echo "${BOLD}Available qualities:${RESET}"
  for i in "${!HEIGHTS[@]}"; do
    printf "  %2d) %sp\n" "$((i + 1))" "${HEIGHTS[$i]}"
  done
  echo

  while true; do
    read -rp "${CYAN}${BOLD}Enter choice: ${RESET}" QCHOICE
    if [[ "$QCHOICE" =~ ^[0-9]+$ ]] && [ "$QCHOICE" -ge 1 ] && [ "$QCHOICE" -le "${#HEIGHTS[@]}" ]; then
      local idx=$((QCHOICE - 1))
      set_quality_by_height "${HEIGHTS[$idx]}"
      return
    fi
    warn "Invalid choice, try again."
  done
}

# ---------- clean up any stray subtitle files left behind ----------
# Even with --embed-subs, some yt-dlp versions/configs leave the source
# .srt/.vtt/.ass file next to the video. We only want it embedded, so
# sweep the target directory for subtitle files touched in this run.
cleanup_stray_subs() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  find "$dir" -maxdepth 1 -type f \
    \( -iname "*.srt" -o -iname "*.vtt" -o -iname "*.ass" \) \
    -newermt "-15 minutes" -delete 2>/dev/null || true
}

# ---------- run the download ----------
do_download() {
  echo
  hr

  local rc=0
  if [ "$DL_TYPE" = "audio" ]; then
    info "Downloading highest quality audio..."
    echo "Saving to: ${TARGET_DIR}"
    echo
    yt-dlp \
      "${YTDLP_POT_ARGS[@]}" \
      -f "bestaudio/best" \
      --extract-audio \
      --audio-format best \
      --audio-quality 0 \
      --embed-metadata \
      --embed-thumbnail \
      --windows-filenames \
      --retries 5 --fragment-retries 5 --extractor-retries 5 \
      --sleep-requests 2 \
      --sleep-interval 1 --max-sleep-interval 3 \
      "$PLAYLIST_FLAG" \
      -o "$OUTPUT_TEMPLATE" \
      "$VIDEO_URL"
    rc=$?
  else
    info "Downloading ${LABEL} with one embedded English subtitle track..."
    echo "Saving to: ${TARGET_DIR}"
    echo
    yt-dlp \
      "${YTDLP_POT_ARGS[@]}" \
      -f "$FORMAT" \
      --merge-output-format mp4 \
      --write-subs \
      --write-auto-subs \
      --sub-langs "en" \
      --embed-subs \
      --embed-metadata \
      --embed-thumbnail \
      --windows-filenames \
      --retries 5 --fragment-retries 5 --extractor-retries 5 \
      --sleep-requests 2 \
      --sleep-interval 1 --max-sleep-interval 3 \
      "$PLAYLIST_FLAG" \
      -o "$OUTPUT_TEMPLATE" \
      "$VIDEO_URL"
    rc=$?
    cleanup_stray_subs "$TARGET_DIR"
  fi

  echo
  hr
  if [ "$rc" -eq 0 ]; then
    ok "Done! Saved in ${TARGET_DIR}"
  else
    fail "yt-dlp exited with an error (code $rc) - see the output above for details."
    echo "${DIM}Common causes: invalid/private link, geo-restriction, an outdated yt-dlp${RESET}"
    echo "${DIM}version (try: pip install -U yt-dlp), or a transient 403 from YouTube${RESET}"
    echo "${DIM}throttling - the script already retries a few times, so if this keeps${RESET}"
    echo "${DIM}happening on the same video, just try again in a minute or two.${RESET}"
  fi
}

# ---------- main ----------
check_dependencies

while true; do
  banner
  ask_link
  ask_download_type
  ask_mode

  if [ "$DL_TYPE" = "video" ]; then
    ask_quality
  fi

  do_download
  wait_screen

  if [ "$NEXT_ACTION" = "quit" ]; then
    echo
    ok "Bye!"
    break
  fi
done
