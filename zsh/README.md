# zsh dotfile setup tools

zshをよりよいものにするセットアップツール

This is setup tools for zsh to make it better.

## Support

- Ubuntu16.04
- Ubuntu18.04
- Mac OSX Catalina 10.15

## What to do with this tool

1. zshのインストール、ログインシェルをzshに変更
1. 最低限のライブラリインストール
1. [starship](https://starship.rs/#%F0%9F%8D%AC-features)のインストール、適用
1. gitの設定
1. dotfilesのシンボリックリンク作成

## Requirements

| OS | content |
| :--- | :--- |
| Mac OSX | `homebrew` |
| Ubuntu 16.04 | - |
| Ubuntu 18.04 | - |

## Preparation

### Ubuntu 16.04

#### install zsh and change default shell

```sh
sudo apt install zsh -y
zsh
chsh -s "$(which zsh)"
```

### Mac OSX

#### install coreutils

```sh
brew install coreutls
```

## First install

```sh
./install.sh
```

## Create symlink

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
| git-completion-setting.sh | git補完設定 |
| git-config-setting.sh | git設定 |
| initial-setting.sh | 初期設定 |
| install-starship.sh | starshipインストーラー |
| zsh-setting.sh | zsh設定スクリプト |
