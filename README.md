# dotfiles

macOS / Linux 向けの dotfiles。GNU Stow で `$HOME` に symlink を張って管理する。

## ディレクトリ構成

| ディレクトリ | 説明 |
| :-- | :-- |
| `zsh/` | zsh 設定 (homebrew + starship + 最低限の UX) |
| `vim/` | vim 設定 (最小構成) |
| `claude/` | Claude Code 設定 (`~/.claude/`) |
| `setup/` | ライブラリ / starship / git 設定の bootstrap |

Claude Code の global `CLAUDE.md` は `~/Workspaces/ws_claude/CLAUDE.md` を単一ソースとして `install.sh` が symlink を張る (repo には含めない)。

## セットアップ

```sh
git clone git@github.com:ijiwarunahello/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` は:

1. `setup/install-libraries.sh` で OS 別に必要パッケージ (stow など) を導入
2. `stow -t ~ zsh vim claude` で symlink を展開
3. `~/.claude/CLAUDE.md` を `~/Workspaces/ws_claude/CLAUDE.md` に symlink
4. starship と git config を初期化

## 対応環境

- macOS (Apple Silicon / Intel)
- Linux (Debian / Ubuntu 系)
