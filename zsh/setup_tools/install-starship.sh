#/bin/bash
printf '\033[33m%s\033[m\n' "starship install..."
if [ "`which starship`" = '' ]; then
	wget -q --show-progress https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz -P ~/
	tar xvf ~/starship-x86_64-unknown-linux-gnu.tar.gz
	sudo mv starship /usr/local/bin/starship
	rm ~/starship-x86_64-unknown-linux-gnu.tar.gz
else
	printf '\033[32m%s\033[m\n' "starship is already installed."
fi
