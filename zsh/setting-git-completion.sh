#/bin/sh
echo -e "\e[1;33msetting git completion...\e[m"
if [ -e ~/.zsh/completion ]; then
	echo "git completion setting already done."
else
	mkdir -p ~/.zsh/completion && cd ~/.zsh/completion
	wget https://raw.github.com/git/git/master/contrib/completion/git-completion.bash
	wget https://raw.github.com/git/git/master/contrib/completion/git-completion.zsh
	mv git-completion.zsh _git
	source ~/.zshrc
	rm -f ~/.zcompdump; compinit
fi
