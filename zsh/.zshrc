# bindkey setting
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# share history other terminal
setopt share_history
# do not show duplicates
setopt histignorealldups
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# move by entering only dir name
setopt auto_cd
# correct command miss
setopt correct

# global alias
alias -g L="| less"
alias -g G="| grep"
alias -g GI="| grep -ri"

# alias
alias lst="ls -ltr --color=auto"
alias l="ls -ltr --color=auto"
alias la="ls -la --color=auto"
alias ll="ls -l --color=auto"
alias so="source"
alias sozc="source ~/.zshrc"
alias v="vim"
alias vi="vim"
alias vz="vim ~/.zshrc"
alias c="cdr"
alias h="fc -lt '%F %T' 1"
alias cp="cp -i"
alias rm="rm -i"
alias mkdir="mkdir -p"
alias ..="c ../"
alias open="explorer.exe"

# add cdr command
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ":chpwd:*" recent-dirs-default true

# exeute ls after cd command
chpwd() { ls -ltr --color=auto }

# delimiter setting
autoload -Uz select-word-style
select-word-style default
zstyle ":zle:*" word-chars "_-./;@"
zstyle ":zle:*" word-style unspecified

# disable ctrl+s, ctrl+q
setopt no_flow_control

# after completion, it becomes the menu selection
zstyle ":completion:*:default" menu select=2

# completion matches upper/lower
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# mkdir and cd execute at the same time
function mkcd() {
	if [[ -d $1 ]]; then
		echo "$1 already exists."
		cd $1
	else
		mkdir -p $1 && cd $1
	fi
}

# git completion
fpath=(~/.zsh/completion $fpath)
autoload -U compinit
compinit -u

# ENV
export DISPLAY=:0

eval "$(starship init zsh)"
