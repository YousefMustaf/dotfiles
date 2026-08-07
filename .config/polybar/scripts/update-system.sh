#!/usr/bin/env bash

kitty --hold sh -c "
echo 'Updating system...'
sudo pacman -Syu
echo
echo 'Done.'
read -n1 -rsp 'Press any key to close...'
"
