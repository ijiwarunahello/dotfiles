# 軽量モデル(haiku)委譲スキル Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** git 定型作業・ブランチ整理・検索下請け・環境検証を haiku サブエージェントに委譲する判断基準とプロンプト雛形をまとめた Claude Code スキルを作成する。

**Architecture:** `claude/.claude/skills/haiku-delegation/SKILL.md` を 1 ファイル作成する。既存の `visionos-dev` スキルと同じ frontmatter(`name` + `description`)形式に従い、stow で `~/.claude/skills/` に展開されて Claude Code が自動認識する。本文に中核原則 4 点と委譲カテゴリ 4 種のプロンプト雛形を記載する。

**Tech Stack:** Markdown(YAML frontmatter)、git stow、Claude Code Skill 機構

**前提:** ブランチ `feat/haiku-delegation-skill` 上で作業する(スペックコミット済み)。

スペック: `docs/superpowers/specs/2026-06-13-haiku-delegation-design.md`

---

### Task 1: SKILL.md の作成

**Files:**
- Create: `claude/.claude/skills/haiku-delegation/SKILL.md`

- [x] **Step 1: ディレクトリとファイルを作成し、以下の内容をそのまま書き込む**

ファイルパス: `claude/.claude/skills/haiku-delegation/SKILL.md`

````markdown
---
name: haiku-delegation
description: Use when performing mechanical, fully-specified routine work that a lightweight model can execute — running git add/commit/push and gh pr create after the message and PR body are already written, syncing branches (fetch / pull --ff-only / pruning [gone] branches with a known target list), running read-only search/investigation (git log, grep, file exploration) that only needs a summary returned, or running fixed verification commands (stow, install.sh, lint/format). Delegate execution to a haiku subagent while the higher model keeps the thinking. Do NOT use for conflict resolution, ambiguous error interpretation, or destructive operations with an undecided target.
---

# 軽量モデル(haiku)への委譲

定型作業を haiku サブエージェントに委譲し、コストとレイテンシを抑える。
**考える仕事は上位モデル、確定済みの機械的実行は haiku** という役割分担を徹底する。

委譲は Claude Code の Agent ツールに `subagent_type` 既定のまま `model: "haiku"` を指定して実行する。

## 中核原則

1. **思考と実行の分離**
   コミットメッセージ・PR 本文・削除対象ブランチの判断・調査方針などの判断は上位モデルが行う。
   確定した内容を**逐語的に**(そのまま実行できる形で)haiku に渡す。haiku に文章を考えさせない。

2. **委譲の条件**
   次の両方を満たす作業のみ委譲する:
   - 手順が完全に specify できる(実行すべきコマンド・対象が確定している)
   - 成功判定が機械的に確認できる(終了コード・想定出力の有無で判断できる)
   コンフリクト解消・曖昧なエラーの解釈・対象が未確定の破壊的操作は委譲しない。

3. **エスカレーションルール**
   haiku への指示には必ず次を含める:
   > 想定外の出力(マージコンフリクト、hook 失敗、non-fast-forward、認証エラー等)が出たら、
   > 即座に停止して出力をそのまま報告すること。自己判断で回復やリトライをしないこと。
   失敗報告を受けたら上位モデルが引き継ぐ。

4. **委譲粒度**
   単発の軽いコマンド 1 つは上位モデルが直接実行してよい。
   複数ステップの定型シーケンス(stage → commit → push → PR 作成など)や、
   出力が長く上位モデルのコンテキストを圧迫する作業を委譲対象とする。

## 委譲カテゴリとプロンプト雛形

上位モデルが `{}` の箇所を確定済みの値で埋めてから haiku に渡す。

### 1. git 定型作業(コミット〜PR)

前提: コミットメッセージ・PR 本文は上位モデルが作成済み。

> 次の git 操作を順に実行し、各コマンドの結果を報告してください。
> 想定外の出力(コンフリクト、hook 失敗、non-fast-forward 等)が出たら即停止して報告し、自己判断で回復しないこと。
>
> 1. `git add {対象パス}`
> 2. 次のメッセージでコミット:
> ```
> {コミットメッセージ本文}
> ```
> 3. `git push -u origin {ブランチ名}`
> 4. 次の本文で PR を作成: `gh pr create --title "{タイトル}" --body "{本文}"`
> 5. 出力された PR の URL を報告。

### 2. ブランチ整理・同期

前提: 削除対象ブランチのリストは上位モデルが確定済み(未確定なら委譲しない)。

> 次のブランチ整理を実行し、結果を報告してください。
> 想定外の出力が出たら即停止して報告し、自己判断で回復しないこと。
>
> 1. `git fetch --prune`
> 2. 現在のブランチで `git pull --ff-only`(fast-forward できなければ停止して報告)
> 3. 次のブランチを削除: {削除対象ブランチのリスト} — 各 `git branch -d {名前}` を実行
> 4. 削除結果と現在のブランチ一覧を報告。

### 3. 検索・調査の下請け(read-only)

> 次の調査を read-only で実行し、結果を構造化して要約してください。ファイルの変更は一切しないこと。
>
> 調査内容: {例: "src 配下で `foo(` を呼んでいる箇所をすべて列挙し、ファイル:行番号と前後 1 行を示す"}
>
> 出力形式: {例: "ファイルパスごとに箇条書き。該当なしのファイルは省略"}

### 4. 環境・検証の定型作業

> 次の検証コマンドを順に実行し、各コマンドの pass/fail と関連する出力を報告してください。
> エラーが出たら即停止して出力をそのまま報告し、自己判断で修正しないこと。
>
> 1. {例: `./install.sh`}
> 2. {例: `npm run lint`}
> 3. 各コマンドの終了コードと、失敗時はエラー出力を報告。

## 委譲しない例

- マージコンフリクトの解消(判断が必要)
- 失敗したテストの原因調査と修正(systematic-debugging の領域)
- どのブランチを消すかの選定(判断が必要 — 選定は上位、削除実行のみ委譲可)
- コミットメッセージ・PR 本文・設計文書の作成(思考そのもの)
````

- [x] **Step 2: ファイルが作成され frontmatter が妥当か確認する**

Run: `head -4 claude/.claude/skills/haiku-delegation/SKILL.md`
Expected: 1 行目 `---`、2 行目 `name: haiku-delegation`、3 行目 `description: Use when...`、4 行目 `---`

- [x] **Step 3: stow symlink 経由で展開されていることを確認する**

Run: `cat ~/.claude/skills/haiku-delegation/SKILL.md | head -2`
Expected: `---` と `name: haiku-delegation` が出力される(stow が既存の symlink を張っていれば即反映される)

備考: もし `~/.claude/skills/haiku-delegation/` が存在しない場合は、新規ディレクトリのため stow の再実行が必要。その場合は `cd ~/Workspaces/src/github.com/ijiwarunahello/dotfiles && stow -d . -t ~ claude` を実行してから再確認する。

- [x] **Step 4: コミット**

```bash
git add claude/.claude/skills/haiku-delegation/SKILL.md
git commit -m "Add haiku-delegation skill for routine work

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 2: プラン更新・push・PR 作成

**Files:**
- Modify: `docs/superpowers/plans/2026-06-13-haiku-delegation-skill.md`(完了チェックを更新してコミット)

- [x] **Step 1: プランの完了ステップにチェックを入れてコミットする**

```bash
git add docs/superpowers/plans/2026-06-13-haiku-delegation-skill.md
git commit -m "Mark haiku-delegation plan steps complete

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

- [x] **Step 2: push する**

```bash
git push -u origin feat/haiku-delegation-skill
```

- [x] **Step 3: PR を作成する**

PR 説明は日本語・5 セクションテンプレート(Summary / Why / Impact / Test / Notes)に従う:

```bash
gh pr create --title "Add haiku-delegation skill for routine work" --body "$(cat <<'EOF'
## Summary
- `claude/.claude/skills/haiku-delegation/SKILL.md` を追加
- git 定型作業 / ブランチ整理 / 検索下請け / 環境検証を haiku サブエージェントに委譲する判断基準とプロンプト雛形を定義

## Why
コミットメッセージや PR 本文などの「考える仕事」は上位モデルが担い、確定済みの機械的実行のみ軽量モデルに任せることで、コストとレイテンシを抑えるため。

## Impact
- 上位モデルは定型作業を haiku サブエージェント(Agent ツール + `model: "haiku"`)に委譲できるようになる
- コンフリクト解消・曖昧なエラー解釈・対象未確定の破壊的操作は委譲対象外として明記

## Test
- `head -4 claude/.claude/skills/haiku-delegation/SKILL.md` で frontmatter を確認
- `cat ~/.claude/skills/haiku-delegation/SKILL.md` で stow symlink 経由の展開を確認

## Notes
- 設計スペック: `docs/superpowers/specs/2026-06-13-haiku-delegation-design.md`
- 実装プラン: `docs/superpowers/plans/2026-06-13-haiku-delegation-skill.md`
- 新規ディレクトリのため、初回は `stow` 再実行が必要な場合がある

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR の URL が出力される

- [x] **Step 4: PR URL をユーザーに報告する**
