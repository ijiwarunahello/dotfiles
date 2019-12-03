#/bin/bash
echo -e "\e[1;33mstarship install...\e[m"
if [ "`which starship`" = '' ]; then
	wget -q --show-progress https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz -P ~/
	tar xvf ~/starship-x86_64-unknown-linux-gnu.tar.gz
	sudo mv starship /usr/local/bin/starship
	rm ~/starship-x86_64-unknown-linux-gnu.tar.gz
else
	echo "starship is already installed."
fi
