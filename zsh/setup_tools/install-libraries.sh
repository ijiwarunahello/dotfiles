#!/bin/bash

# ドライランモードのフラグ
DRY_RUN=false

# コマンドライン引数の解析
while getopts "d" opt; do
    case $opt in
        d) DRY_RUN=true ;;
        *) echo "Usage: $0 [-d]" >&2
           echo "  -d: ドライランモード（実際のインストールは行いません）" >&2
           exit 1 ;;
    esac
done

# Define package manager and install command based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    PKG_MANAGER="brew"
    INSTALL_CMD="install"
    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
        if ! $DRY_RUN; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo "Would install Homebrew"
        fi
    fi
elif [[ -f /etc/debian_version ]]; then
    # Ubuntu/Debian
    PKG_MANAGER="sudo apt"
    INSTALL_CMD="install -y"
else
    echo "Unsupported operating system"
    exit 1
fi

# Common packages
library_list=(curl vim)

# OS-specific packages
if [[ "$OSTYPE" == "darwin"* ]]; then
    library_list+=(peco)
else
    # Ubuntu-specific packages
    library_list+=(finger xsel peco)
fi

printf '\033[33m%s\033[m\n' "install ${library_list[@]} from now."
if $DRY_RUN; then
    printf '\033[33m%s\033[m\n' "ドライランモード: 実際のインストールは行いません"
fi

read -p "Are you ok? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac

printf '\033[33m%s\033[m\n' "install..."
if ! $DRY_RUN; then
    $PKG_MANAGER $INSTALL_CMD ${library_list[@]}
else
    echo "Would execute: $PKG_MANAGER $INSTALL_CMD ${library_list[@]}"
fi
