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

[ -f "$ZDOTDIR/.zshrc_$(uname)" ] && . "$ZDOTDIR/.zshrc_$(uname)"

command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
