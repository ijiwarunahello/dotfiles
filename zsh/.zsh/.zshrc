export PATH="$HOME/.local/bin:$PATH"

setopt share_history
setopt histignorealldups
setopt auto_cd
setopt correct
setopt no_flow_control

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

autoload -U compinit && compinit -u
zstyle ":completion:*:default" menu select=2
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

alias l="ls -ltr"
alias ll="ls -l"
alias la="ls -la"
alias v="vim"
alias vi="vim"
alias ..="cd .."

_dotfiles_require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '%s\n' "$1 is required." >&2
    return 1
  fi
}

g() {
  _dotfiles_require ghq || return
  _dotfiles_require fzf || return

  local repo
  repo="$(ghq list -p | fzf --prompt='repo> ')" || return
  [ -n "$repo" ] && cd "$repo"
}

gw() {
  _dotfiles_require wt || return
  wt switch "$@"
}

gwc() {
  _dotfiles_require wt || return
  if [ "$#" -eq 0 ]; then
    printf '%s\n' "usage: gwc <branch>" >&2
    return 2
  fi

  wt switch --create "$@"
}

[ -f "$ZDOTDIR/.zshrc_$(uname)" ] && . "$ZDOTDIR/.zshrc_$(uname)"

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
