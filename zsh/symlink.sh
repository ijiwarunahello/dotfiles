#!/bin/sh
basepath=$(cd $(dirname $0);pwd)

# symlink dotfiles into ~
files=.*
for file in $files
do
  if [ ! -d $file -a $file != "." -a $file != ".." -a $file != ".git" ]; then
    ln -sf $basepath/$file ~
  fi
done

# symlink zsh configuration files into ~/.zsh
if [ ! -d ~/.zsh ]; then
  mkdir ~/.zsh
fi
for file in .zsh/.*
do
  if [ $file != ".zsh/." -a $file != ".zsh/.." -a $file != ".git" ]; then
    ln -sf $basepath/$file ~/.zsh/
  fi
done
