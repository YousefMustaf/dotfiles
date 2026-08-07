#!/usr/bin/env bash

chosen=$(
  printf "⏻  Shutdown\n  Reboot\n  Suspend\n  Lock\n  Logout" |
    rofi \
      -dmenu \
      -i \
      -p "Power" \
      -theme ~/.config/rofi/menus/powermenu.rasi
)

case "$chosen" in
*Shutdown)
  systemctl poweroff
  ;;
*Reboot)
  systemctl reboot
  ;;
*Suspend)
  systemctl suspend
  ;;
*Lock)
  i3lock
  ;;
*Logout)
  i3-msg exit
  ;;
esac
