#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

"$ROOT/setup/install-libraries.sh"

cd "$ROOT"
mkdir -p "$HOME/.agents/skills"
stow -v -t "$HOME" zsh vim claude codex
stow -R -v -t "$HOME" agents

"$ROOT/setup/install-starship.sh"

printf '\033[33m%s\033[m\n' "all setting done."
printf '\033[33m%s\033[m\n' "next: run 'gh auth login' and then 'gh auth setup-git' when GitHub authentication is needed."
printf '\033[33m%s\033[m\n' "next: run 'wt config shell install' once to enable Worktrunk directory switching."
