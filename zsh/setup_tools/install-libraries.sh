#!/bin/bash
library_list=(finger xsel)
printf '\033[33m%s\033[m\n' "install ${library_list[@]} from now."
read -p "Are you ok? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac
printf '\033[33m%s\033[m\n' "install..."
sudo apt install -y ${library_list[@]}
