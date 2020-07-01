# share history other terminal
setopt share_history
# do not show duplicates
setopt histignorealldups
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# git completion
fpath=(~/.zsh/completion $fpath)
autoload -U compinit
compinit -u
