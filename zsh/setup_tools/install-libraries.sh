#!/bin/bash
library_list=(finger xsel)
printf '\033[m33%s\033[m\n' "install ${library_list[@]} from now."
read -p "Are you ok? (y/N): " yn
case "$yn" in [yN]*) ;; *) echo "abort." ; exit ;; esac
printf '\033[m33%s\033[m\n' "install..."
sudo apt install -y ${library_list[@]}
