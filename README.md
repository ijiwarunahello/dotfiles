# dotfiles

macOS / Linux 向けの dotfiles。GNU Stow で `$HOME` に symlink を張って管理する。

## ディレクトリ構成

| ディレクトリ | 説明 |
| :-- | :-- |
| `zsh/` | zsh 設定 (homebrew + starship + 最低限の UX) |
| `vim/` | vim 設定 (最小構成) |
| `claude/` | Claude Code 設定 (`~/.claude/`) — global `CLAUDE.md` と skills も含む |
| `codex/` | Codex 設定 (`~/.codex/`) — global `AGENTS.md` と Claude 由来 skills への導線 |
| `setup/` | ライブラリ / starship / git 設定の bootstrap |

## セットアップ

```sh
git clone git@github.com:ijiwarunahello/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` は:

1. `setup/install-libraries.sh` で OS 別に必要パッケージ (stow など) を導入
2. `stow -t ~ zsh vim claude codex` で symlink を展開
3. starship と git config を初期化

## AI エージェント設定

- `codex/.codex/AGENTS.md` を共通ルールの正本として扱う
- `claude/.claude/CLAUDE.md` は `AGENTS.md` への参照だけを持つ
- `codex/.codex/skills/*` は Claude 側 skills を参照する導線で、実体の編集元は `claude/.claude/skills/*/SKILL.md`

## 対応環境

- macOS (Apple Silicon / Intel)
- Linux (Debian / Ubuntu 系)
