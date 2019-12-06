# zsh dotfile setup tools

zshをよりよいものにするセットアップツール

This is setup tools for zsh to make it better.

## Support

| OS | status |
| :--- | :--- |
| Ubuntu18.04 for WSL | confirmed |
| Ubuntu16.04 for WSL | not confirmed |

## What to do with this tool

1. zshのインストール、ログインシェルをzshに変更
1. 最低限のライブラリインストール
1. [starship](https://starship.rs/#%F0%9F%8D%AC-features)のインストール、適用
1. gitの設定

## Preparation

### install zsh

手動でzshをインストールし、ログインシェルをzshに変更する

```sh
sudo apt install zsh -y
zsh
chsh -s "$(which zsh)"
```

## Run

```sh
./install.sh
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
