# zsh dotfile setup tools

zshをよりよいものにするセットアップツール

This is setup tools for zsh to make it better.

## Support

- Ubuntu20.04

## Preparation

### Ubuntu 

#### install zsh and change default shell

```sh
sudo apt install zsh -y
zsh
chsh -s "$(which zsh)"
```

## First install

```sh
./install.sh
```

`install.sh`では以下を実行している。

- 以下ライブラリのインストール
  - finger
  - xsel
  - peco
  - curl
  - vim
- [starship](https://starship.rs)のインストール
- gitの初期設定（ユーザ名、メールアドレス）

## Create symlink

`.zsh`ファイルのシンボリックリンクを貼る

```sh
./symlink.sh
```

## Check 'Run command as a login shell'

![setting_display](https://raw.githubusercontent.com/ijiwarunahello/dotfiles/docs/pics/run_command_as_login_shell.png)

because enable `.zprofile`

## Role for each file

| filename | description |
| :--- | :--- |
| install.sh | インストーラー |
| symlink.sh | シンボリックリンク作成 |
| .zshrc | zshの設定ファイル |
| git-config-setting.sh | git設定 |
| initial-setting.sh | 初期設定 |
| install-starship.sh | starshipインストーラー |
