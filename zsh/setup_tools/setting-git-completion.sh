#/bin/sh
printf '\033[33m%s\033[m\n' "setting git completion..."
if [ -e ~/.zsh/completion ]; then
	printf '\033[32m%s\033[m\n' "git completion setting already done."
else
	mkdir -p ~/.zsh/completion && cd ~/.zsh/completion
	wget https://raw.github.com/git/git/master/contrib/completion/git-completion.bash
	wget https://raw.github.com/git/git/master/contrib/completion/git-completion.zsh
	mv git-completion.zsh _git
	source ~/.zshrc
	rm -f ~/.zcompdump; compinit
fi
