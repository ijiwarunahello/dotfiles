#!/usr/bin/env bash
set -euo pipefail

printf '\033[33m%s\033[m\n' "setting git config..."

USERNAME=$(git config --global user.name || true)
EMAIL=$(git config --global user.email || true)
COLOR_UI=$(git config --global color.ui || true)
CORE_EDITOR=$(git config --global core.editor || true)
DELETE_MERGED_BRANCH=$(git config --global alias.delete-merged-branch || true)
GIT_VERSION=$(git --version | sed -e 's/[^0-9]//g')

if [ -z "$USERNAME" ]; then
  read -p "username: " username
  git config --global user.name "$username"
fi

if [ -z "$EMAIL" ]; then
  read -p "email: " email
  git config --global user.email "$email"
fi

if [ -z "$COLOR_UI" ]; then
  git config --global color.ui auto
fi

if [ -z "$CORE_EDITOR" ]; then
  git config --global core.editor vim
fi

if [ -z "$DELETE_MERGED_BRANCH" ]; then
  git config --global alias.delete-merged-branch "!f () { git checkout \$1; git branch --merged|egrep -v '\\*|develop|master|main'|xargs git branch -d; };f"
fi

if [ "$GIT_VERSION" -ge 2270 ]; then
  PULL_REBASE=$(git config --global pull.rebase || true)
  if [ -z "$PULL_REBASE" ]; then
    git config --global pull.rebase false
  fi
fi
