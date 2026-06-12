# Perfume モチーフのプロジェクト命名ルール追加 — 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 共有エージェントガイダンス(`codex/.codex/AGENTS.md`)に、新規リポジトリを Perfume の楽曲・歌詞モチーフで命名するルールを追加する。

**Architecture:** `codex/.codex/AGENTS.md` は共有ガイダンスの canonical source で、`~/.claude/CLAUDE.md` から import され、stow で `~/.codex/AGENTS.md` に symlink 済み。このファイル 1 つに新セクションを追加するだけで Claude と Codex の両方に適用される。

**Tech Stack:** Markdown、git、GitHub CLI (`gh`)

**前提:** ブランチ `feat/perfume-project-naming` 上で作業する(スペックコミット済み)。

スペック: `docs/superpowers/specs/2026-06-13-perfume-project-naming-design.md`

---

### Task 1: Project Naming セクションの追加

**Files:**
- Modify: `codex/.codex/AGENTS.md` (「Agent Workspace Operation」セクションの直後、「Artifact Hub」セクションの前)

- [x] **Step 1: 新セクションを追加する**

「Agent Workspace Operation」セクションの最終行(`- If work must start outside ~/Workspaces/src, ask the user before proceeding.`)と「## Artifact Hub」の間に、以下をそのまま挿入する:

```markdown
## Project Naming

- Name new repositories and projects after Perfume (the Japanese band): use song titles, lyrics, or album names as motifs, or wordplay derived from them.
- When naming, propose 2-3 candidates related to the project's purpose, each with a short explanation of its origin, and let the user choose. Do not finalize a name unilaterally.
- Use lowercase kebab-case following GitHub conventions (examples: `polyrhythm`, `edge-of-glitter`, `chocolate-disco`).
- Do not apply this rule to renaming existing repositories, or to branch names and codenames.
```

- [x] **Step 2: 追加結果を目視確認する**

Run: `grep -A 6 "## Project Naming" codex/.codex/AGENTS.md`
Expected: 上記 4 つの箇条書きがそのまま出力される

- [x] **Step 3: symlink 経由で反映されていることを確認する**

Run: `grep "## Project Naming" ~/.codex/AGENTS.md`
Expected: `## Project Naming` が 1 行出力される(stow の symlink が生きていれば編集と同時に反映される)

- [x] **Step 4: コミット**

```bash
git add codex/.codex/AGENTS.md
git commit -m "Add Perfume-motif naming rule for new projects

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 2: プランのチェックボックス更新・push・PR 作成

**Files:**
- Modify: `docs/superpowers/plans/2026-06-13-perfume-project-naming.md` (完了ステップのチェックを更新してコミット)

- [x] **Step 1: push する**

```bash
git push -u origin feat/perfume-project-naming
```

- [x] **Step 2: PR を作成する**

PR 説明は日本語・5 セクションテンプレート(Summary / Why / Impact / Test / Notes)に従う:

```bash
gh pr create --title "Add Perfume-motif naming rule for new projects" --body "$(cat <<'EOF'
## Summary
- 共有エージェントガイダンス(`codex/.codex/AGENTS.md`)に「Project Naming」セクションを追加
- 新規リポジトリ / プロジェクトの命名を Perfume の楽曲・歌詞・アルバム名のモチーフ / もじりとするルールを定義

## Why
新規プロジェクトの命名に一貫したテーマを持たせるため。canonical source 1 箇所の編集で Claude / Codex 両方に適用される。

## Impact
- エージェントは新規リポジトリ命名時に Perfume モチーフ候補を 2〜3 個提示し、ユーザーが選択するフローになる
- 既存リポジトリのリネーム、ブランチ名・コードネームには適用しない

## Test
- `grep -A 6 "## Project Naming" codex/.codex/AGENTS.md` でセクション追加を確認
- `grep "## Project Naming" ~/.codex/AGENTS.md` で stow symlink 経由の反映を確認

## Notes
- 設計スペック: `docs/superpowers/specs/2026-06-13-perfume-project-naming-design.md`
- 実装プラン: `docs/superpowers/plans/2026-06-13-perfume-project-naming.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR の URL が出力される

- [x] **Step 3: PR URL をユーザーに報告する**
