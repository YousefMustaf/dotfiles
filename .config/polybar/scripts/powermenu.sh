#!/usr/bin/env bash

choice=$(printf " Shutdown\n Reboot\n Logout\n Lock\n Suspend" |
  rofi -dmenu -i -p "Power")

case "$choice" in
*Shutdown)
  systemctl poweroff
  ;;
*Reboot)
  systemctl reboot
  ;;
*Logout)
  i3-msg exit
  ;;
*Lock)
  i3lock
  ;;
*Suspend)
  systemctl suspend
  ;;
esac
