#/bin/bash
printf '\033[33m%s\033[m\n' "starship install..."
if [ "`which starship`" = '' ]; then
	curl -fsSL https://starship.rs/install.sh | bash

else
	printf '\033[32m%s\033[m\n' "starship is already installed."
fi
