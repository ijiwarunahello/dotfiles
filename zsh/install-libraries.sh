#!/bin/bash
library_list=(finger xsel)
echo -e "\e[1;33minstall ${library_list[@]} from now.\e[m"
read -p "Are you ok? (y/N): " yn
case "$yn" in [yN]*) ;; *) echo "abort." ; exit ;; esac
echo "install..."
sudo apt install -y ${library_list[@]}

