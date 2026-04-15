#!/usr/bin/env bash
set -euo pipefail

printf '\033[33m%s\033[m\n' "starship install..."

if command -v starship >/dev/null 2>&1; then
  printf '\033[32m%s\033[m\n' "starship is already installed."
else
  curl -sS https://starship.rs/install.sh | sh
fi
