#!/bin/bash
TOOLS="./setup_tools"
$TOOLS/initial-setting.sh
$TOOLS/install-libraries.sh
$TOOLS/install-starship.sh
$TOOLS/setting-git-config.sh
$TOOLS/setting-git-completion.sh
printf '\033[33m%s\033[m' "all setting done."
