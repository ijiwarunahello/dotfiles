#!/bin/bash
printf '\033[33m%s\033[m\n' "setting git config..."

# Get current config
USERNAME=`git config --global user.name`
EMAIL=`git config --global user.email`
COLOR_UI=`git config --global color.ui`
CORE_EDITOR=`git config --global core.editor`
DELETE_MERGED_BRANCH=`git config --global alias.delete-merged-branch`
GIT_VERSION=`git --version | sed -e 's/[^0-9]//g'`

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

printf '\033[33m%s\033[m\n' "core.ui"
if [ "$COLOR_UI" == '' ]; then
	git config --global color.ui auto
fi
printf '\033[33m%s\033[m\n' "core.editor"
if [ "$CORE_EDITOR" == '' ]; then
	git config --global core.editor vim
fi
printf '\033[33m%s\033[m\n' "alias"
if [ "$DELETE_MERGED_BRANCH" == '' ]; then
	git config --global alias.delete-merged-branch "!f () { git checkout $1; git branch --merged|egrep -v '\*|develop|master'|xargs git branch -d; };f"
fi

printf '\033[33m%s\033[m\n' "git pull config"
if [ $GIT_VERSION -ge 2270 ]; then
	PULL_REBASE=`git config --global pull.rebase`
	if [ "$PULL_REBASE" == '' ]; then
		git config --global pull.rebase false
	fi
else
	printf '\033[33m%s\033[m\n' "git version lower 2.27.0"
fi
