#!/bin/bash
echo -e "\e[1;33msetting git config...\e[m"
# Get arg
USERNAME=$1
EMAIL=$2

# Get current config
username=`git config --global user.name`
email=`git config --global user.email`

function usage() {
    NAME=`basename $0`
    echo $NAME USERNAME EMAIL
}

# Error
if [ "$username" == '' ]; then
    if [ "$USERNAME" == '' ]; then
        usage
        exit 1
    fi
    git config --global user.name "$USERNAME"
fi
if [ "$email" == '' ]; then
    if [ "$EMAIL" == '' ]; then
        usage
        exit 1
    fi
    git config --global user.email $EMAIL
fi

git config --global core.editor vim
git config --global alias.delete-merged-branch "!f () { git checkout $1; git branch --merged|egrep -v '\*|develop|master'|xargs git branch -d; };f"
