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
| `setup/` | ライブラリ / starship の bootstrap |

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
4. starship を初期化
5. GitHub CLI / Worktrunk の次アクションを表示

GitHub 認証と Git credential helper は GitHub CLI に任せる。

```sh
gh auth login
gh auth setup-git
```

Worktrunk で `wt switch` 後に shell のカレントディレクトリも移動したい場合は、初回だけ shell integration を入れる。

```sh
wt config shell install
```

## CLI ワークフロー

- `ghq.root` は `~/Workspaces/src` に設定し、repository は `~/Workspaces/src/github.com/<owner>/<repo>` に揃える
- `ghq get owner/repo` で repository を揃った場所に clone する
- `g` で `ghq list -p` から `fzf` 選択して repository に移動する
- `z` / `zi` で `zoxide` の履歴からよく使う場所に移動する
- `gw` で Worktrunk の worktree picker / switch を使う
- `gwc <branch>` で Worktrunk の worktree を作って移動する
- `c` / `cx` は `~/Workspaces/src` 配下でのみ Codex を起動する
- `cl` は `~/Workspaces/src` 配下でのみ Claude Code を起動する
- `ai <codex|claude>` は `ghq list -p` から repository を選び、その場所で agent を起動する
- `aip <codex|claude>` は agent inbox repository で新規プロジェクトの企画・調査を始める

## AI エージェント設定

- `codex/.codex/AGENTS.md` を共通ルールの正本として扱う
- `claude/.claude/CLAUDE.md` は `AGENTS.md` への参照だけを持つ
- agent 別の `~/Workspaces/ws_codex` / `ws_claude` は作らず、`~/Workspaces/src` 配下の通常 repository / worktree だけで作業する
- 新規プロジェクトの企画・調査は `~/Workspaces/src/github.com/ijiwarunahello/workspace-inbox` から始める
- trusted workspace root は `WORKSPACES_SRC=/path/to/src` で上書きできる
- agent inbox repository は `AGENT_INBOX_REPO=/path/to/repo` で上書きできるが、agent 起動時は trusted workspace root 配下に置く
- 実装に進む段階では対象 project repository / worktree に移動してから agent を起動する
- `agents/.agents/skills/*` を Codex の user-scope skill 配置として扱う
- `~/.agents` 自体は実ディレクトリにし、その配下の skill ディレクトリだけを symlink で管理する
- Even Hub / G2 開発支援は `agents/.agents/skills/evenhub-*` の user-scope skills を使う
- vendored skill の実体は `agents/.agents/vendor/*/skills/*/SKILL.md` に置き、`agents/.agents/skills/evenhub-*` はそこへの入口 symlink として扱う
- skill 実体の編集元は、単体skillは `claude/.claude/skills/*/SKILL.md`、vendored skillは `agents/.agents/vendor/*/skills/*/SKILL.md`

## 対応環境

- macOS (Apple Silicon / Intel)
- Linux (Debian / Ubuntu 系)
