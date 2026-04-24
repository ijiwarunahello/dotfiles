#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

"$ROOT/setup/install-libraries.sh"

cd "$ROOT"
stow -v -t "$HOME" zsh vim claude codex

"$ROOT/setup/install-starship.sh"
"$ROOT/setup/setting-git-config.sh"

printf '\033[33m%s\033[m\n' "all setting done."
