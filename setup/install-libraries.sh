#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '\033[36m[dry-run]\033[m %s\n' "$*"
  else
    "$@"
  fi
}

OS="$(uname -s)"
printf '\033[33m%s\033[m\n' "install libraries for $OS..."

case "$OS" in
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      printf '\033[33m%s\033[m\n' "homebrew not found; installing..."
      run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    run brew install stow starship gh ghq fzf zoxide worktrunk
    ;;
  Linux)
    run sudo apt update
    run sudo apt install -y stow zsh vim curl git fzf zoxide
    if command -v brew >/dev/null 2>&1; then
      run brew install gh ghq worktrunk
    else
      printf '\033[33m%s\033[m\n' "homebrew not found; skipping gh, ghq, and worktrunk install."
      printf '\033[33m%s\033[m\n' "install Homebrew or install those tools manually."
    fi
    ;;
  *)
    echo "unsupported OS: $OS" >&2
    exit 1
    ;;
esac
