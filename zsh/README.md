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

__install zsh and change default shell__

```sh
sudo apt install zsh -y
zsh
chsh -s "$(which zsh)"
```

### Mac OSX

__install coreutils__

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

## Role for each file

| filename | description |
| :--- | :--- |
| .zshrc | zshの設定ファイル |
| install.sh | インストーラー |
| git-completion-setting.sh | git補完設定 |
| git-config-setting.sh | git設定 |
| initial-setting.sh | 初期設定 |
| install-starship.sh | starshipインストーラー |
| zsh-setting.sh | zsh設定スクリプト |
