# bindkey setting
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# move by entering only dir name
setopt auto_cd
# correct command miss
setopt correct

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

# starship
if [ ! "`which starship`" = "" ]; then
  eval "$(starship init zsh)"
fi

# nodebrew
if [ ! "`which nodebrew`" = "" ]; then
	export PATH=$HOME/.nodebrew/current/bin:$PATH
fi

# pyenv setting
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
if [ -d $HOME/.pyenv/versions/anaconda3-5.3.1 ]; then
  . $HOME/.pyenv/versions/anaconda3-5.3.1/etc/profile.d/conda.sh
fi
if [ -d $HOME/.pyenv/versions/anaconda3-5.1.0 ]; then
  . $HOME/.pyenv/versions/anaconda3-5.1.0/etc/profile.d/conda.sh
fi
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# load .zshrc_*
[ -f $ZDOTDIR/.zshrc_`uname` ] && . $ZDOTDIR/.zshrc_`uname`
[ -f $ZDOTDIR/.zshrc_dircolors ] && . $ZDOTDIR/.zshrc_dircolors
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
	. $ZDOTDIR/.zshrc_wsl
fi
