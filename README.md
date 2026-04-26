# dotfiles

macOS / Linux 向けの dotfiles。GNU Stow で `$HOME` に symlink を張って管理する。

## ディレクトリ構成

| ディレクトリ | 説明 |
| :-- | :-- |
| `zsh/` | zsh 設定 (homebrew + starship + 最低限の UX) |
| `vim/` | vim 設定 (最小構成) |
| `claude/` | Claude Code 設定 (`~/.claude/`) — global `CLAUDE.md` と skills も含む |
| `codex/` | Codex 設定 (`~/.codex/`) — global `AGENTS.md` と Claude 由来 skills への導線 |
| `agents/` | 共通 agent skills (`~/.agents/skills/`) — Codex の user-scope discovery 用 |
| `setup/` | ライブラリ / starship / git 設定の bootstrap |

## セットアップ

```sh
git clone git@github.com:ijiwarunahello/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` は:

1. `setup/install-libraries.sh` で OS 別に必要パッケージ (stow など) を導入
2. `mkdir -p ~/.agents/skills` で Codex user-scope skill 用ディレクトリを用意
3. `stow -t ~ zsh vim claude codex` と `stow -R -t ~ agents` で symlink を展開し、agent skill の削除済みリンクも掃除
4. starship と git config を初期化

## AI エージェント設定

- `codex/.codex/AGENTS.md` を共通ルールの正本として扱う
- `claude/.claude/CLAUDE.md` は `AGENTS.md` への参照だけを持つ
- `agents/.agents/skills/*` を Codex の user-scope skill 配置として扱う
- `~/.agents` 自体は実ディレクトリにし、その配下の skill ディレクトリだけを symlink で管理する
- Even Hub / G2 開発支援は `agents/.agents/skills/evenhub-*` の user-scope skills を使う
- vendored skill の実体は `agents/.agents/vendor/*/skills/*/SKILL.md` に置き、`agents/.agents/skills/evenhub-*` はそこへの入口 symlink として扱う
- skill 実体の編集元は、単体skillは `claude/.claude/skills/*/SKILL.md`、vendored skillは `agents/.agents/vendor/*/skills/*/SKILL.md`

## 対応環境

- macOS (Apple Silicon / Intel)
- Linux (Debian / Ubuntu 系)
