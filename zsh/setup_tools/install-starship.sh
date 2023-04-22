#/bin/bash
printf '\033[33m%s\033[m\n' "starship install..."
if [ "`which starship`" = '' ]; then
	curl -sS https://starship.rs/install.sh | sh

else
	printf '\033[32m%s\033[m\n' "starship is already installed."
fi
