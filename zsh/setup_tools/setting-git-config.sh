#!/bin/bash
printf '\033[33m%s\033[m\n' "setting git config..."
# Get arg

# Get current config
USERNAME=`git config --global user.name`
EMAIL=`git config --global user.email`

printf '\033[33m%s\033[m\n' "username"
if [ "$USERNAME" == '' ]; then
    read -p "username: " username
    git config --global user.name "$username"
fi
printf '\033[33m%s\033[m\n' "email"
if [ "$EMAIL" == '' ]; then
    read -p "email: " email
    git config --global user.email "$email"
fi

git config --global color.ui auto
git config --global core.editor vim
git config --global alias.delete-merged-branch "!f () { git checkout $1; git branch --merged|egrep -v '\*|develop|master'|xargs git branch -d; };f"
