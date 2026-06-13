# 軽量モデル(haiku)委譲スキル — 設計

日付: 2026-06-13
ステータス: 承認済み

## 目的

git 関連を中心とした定型作業を haiku などの軽量モデルに委譲し、コストとレイテンシを抑える。コミットメッセージ・PR 本文・判断を伴う部分は上位モデルが担い、確定した内容の機械的な実行のみを軽量モデルに任せる「思考と実行の分離」を実現する。

## 配置

- `claude/.claude/skills/haiku-delegation/SKILL.md`
  - 既存の `claude/.claude/skills/visionos-dev/SKILL.md` と同じパターン。
  - stow により `~/.claude/skills/haiku-delegation/` に展開され、Claude Code が自動認識する。
- 委譲は Claude Code の Agent ツールに `model: "haiku"` を指定して実行する。

## 中核原則

1. **思考と実行の分離**: コミットメッセージ・PR 本文・削除対象ブランチの判断・調査方針などの「考える仕事」は上位モデルが行う。確定した内容を逐語的に haiku サブエージェントへ渡し、実行させる。
2. **委譲の条件**: 手順が完全に specify でき、成功判定が機械的に確認できる作業のみ委譲する。コンフリクト解消・曖昧なエラーの解釈・対象が未確定の破壊的操作は委譲しない。
3. **エスカレーションルール**: haiku への指示には「想定外の出力(コンフリクト、hook 失敗、non-fast-forward 等)が出たら即停止して報告し、自己判断で回復しない」を必ず含める。失敗報告を受けたら上位モデルが引き継ぐ。
4. **委譲粒度**: 単発の軽いコマンド 1 つは上位モデルが直接実行してよい。複数ステップの定型シーケンス(stage → commit → push → PR 作成など)や、出力が長い作業を委譲対象とする。

## 委譲カテゴリ(4 種)

各カテゴリについて、SKILL.md にプロンプト雛形を記載する。

1. **git 定型作業**: 上位モデルがコミットメッセージ・PR 本文を作成済みの状態で、`git add` / `commit` / `push` / `gh pr create` の実行と結果確認を委譲する。
2. **ブランチ整理・同期**: `git fetch` / `pull --ff-only` / [gone] ブランチ掃除 / マージ後の master 更新。削除対象リストは上位モデルが確定してから渡す。
3. **検索・調査の下請け**: `git log` 調査・grep・ファイル探索を read-only で実行し、構造化された要約のみ返す。
4. **環境・検証の定型作業**: stow 再実行・`install.sh`・lint / format の実行と pass/fail 報告。

## 発動方式

- 自動適用。frontmatter の `description` に「git commit / push / PR 作成 / ブランチ掃除 / 一括検索 / stow・lint 実行などの定型作業を行うとき」というトリガー条件を記述する。

## 検討した代替案

- カテゴリごとに 4 スキルへ分割: トリガー精度は上がるが共通原則が重複し管理コストが増えるため不採用(YAGNI)。
- AGENTS.md への指針追記: 毎セッションのコンテキストを圧迫し、「スキル化したい」という要望にも反するため不採用。

## 検証方法

- `~/.claude/skills/haiku-delegation/SKILL.md` が stow symlink 経由で展開されていることを確認。
- SKILL.md の frontmatter(name / description)が Claude Code のスキル形式に適合していることを確認。
- 既存スキル(visionos-dev)と同じディレクトリ構成・frontmatter 形式に揃っていることを確認。
