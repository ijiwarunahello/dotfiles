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

_dotfiles_workspace_root() {
  printf '%s\n' "${WORKSPACES_SRC:-$HOME/Workspaces/src}"
}

_dotfiles_agent_inbox_repo() {
  printf '%s\n' "${AGENT_INBOX_REPO:-$(_dotfiles_workspace_root)/github.com/ijiwarunahello/workspace-inbox}"
}

_dotfiles_agent_cwd_allowed() {
  local root cwd
  root="$(_dotfiles_workspace_root)"
  root="${root:A}"
  cwd="${PWD:A}"

  case "$cwd" in
    "$root"|"$root"/*) return 0 ;;
  esac

  printf '%s\n' "agent cwd is outside trusted workspace root: $cwd" >&2
  printf '%s\n' "trusted workspace root: $root" >&2
  return 1
}

_dotfiles_run_agent() {
  if [ "$#" -eq 0 ]; then
    printf '%s\n' "usage: _dotfiles_run_agent <codex|claude|app|codex-app> [args...]" >&2
    return 2
  fi

  local agent
  agent="$1"
  shift

  case "$agent" in
    codex|claude|app|codex-app) ;;
    *)
      printf '%s\n' "usage: _dotfiles_run_agent <codex|claude|app|codex-app> [args...]" >&2
      return 2
      ;;
  esac

  case "$agent" in
    app|codex-app)
      _dotfiles_require codex || return
      ;;
    *)
      _dotfiles_require "$agent" || return
      ;;
  esac
  _dotfiles_agent_cwd_allowed || return

  case "$agent" in
    app|codex-app) command codex app "$@" ;;
    *) command "$agent" "$@" ;;
  esac
}

_dotfiles_pick_repo() {
  _dotfiles_require ghq || return
  _dotfiles_require fzf || return

  local repo
  repo="$(ghq list -p | fzf --prompt='repo> ')" || return
  [ -n "$repo" ] || return 1
  printf '%s\n' "$repo"
}

g() {
  local repo
  repo="$(_dotfiles_pick_repo)" || return
  [ -n "$repo" ] && cd "$repo"
}

c() {
  _dotfiles_run_agent codex "$@"
}

cx() {
  _dotfiles_run_agent codex "$@"
}

ca() {
  _dotfiles_run_agent app "$@"
}

cl() {
  _dotfiles_run_agent claude "$@"
}

ai() {
  if [ "$#" -eq 0 ]; then
    printf '%s\n' "usage: ai <codex|claude|app|codex-app> [args...]" >&2
    return 2
  fi

  local agent repo
  agent="$1"
  shift
  repo="$(_dotfiles_pick_repo)" || return
  cd "$repo" && _dotfiles_run_agent "$agent" "$@"
}

aip() {
  if [ "$#" -eq 0 ]; then
    printf '%s\n' "usage: aip <codex|claude|app|codex-app> [args...]" >&2
    return 2
  fi

  local agent repo
  agent="$1"
  shift
  repo="$(_dotfiles_agent_inbox_repo)"

  if [ ! -d "$repo" ]; then
    printf '%s\n' "agent inbox repo does not exist: $repo" >&2
    printf '%s\n' "create it under ~/Workspaces/src or set AGENT_INBOX_REPO." >&2
    return 1
  fi

  cd "$repo" && _dotfiles_run_agent "$agent" "$@"
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
