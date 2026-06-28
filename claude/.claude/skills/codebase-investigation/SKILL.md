---
name: codebase-investigation
description: Use when investigating, analyzing, or explaining a project's codebase — exploring directory structure, architecture, dependencies, key patterns, and entry points — then publishing findings as an HTML artifact to Artifact Hub. Covers both quick overviews and deep dives. Also triggers on "read and explain this project", "upload a codebase summary", or "investigate this repo". Do NOT use for debugging (use systematic-debugging) or diff review (use code-review).
---

# コードベース調査と Artifact Hub 公開

プロジェクトのコードベースを体系的に調査し、得た知見を HTML アーティファクトとして Artifact Hub に公開するプロセススキル。

## 0. 事前確認

スキル発動時に次の 2 点を確認する。

1. **既存アーティファクトの検索**: `artifact_search` で対象プロジェクト名・リポジトリ名を検索する。過去の調査結果が存在すれば `artifact_get` で取得し、差分更新 (`artifact_update`) か新規作成かを判断する。
2. **調査対象の確認**: cwd が `~/Workspaces/src/github.com/<owner>/<repo>` 配下にあることを確認する。外部の場合はユーザーに確認を求める。

## 1. 調査スコープの判定

ユーザーが明示しない場合、プロジェクト規模から自動判定する。

| スコープ | 条件目安 | アーティファクトの規模 |
|:--|:--|:--|
| **quick** | ファイル数 < 50、またはユーザーが「概要」「ざっくり」と指定 | セクション 3-4 個、図 0-1 枚 |
| **standard** | 既定 | セクション 5-7 個、図 1-2 枚 |
| **deep** | ユーザーが「詳しく」「精読」と指定、または特定サブシステムの精査 | セクション 7+ 個、図 2+ 枚 |

## 2. 調査フェーズ

### Phase 1: 外形把握（並列実行可）

以下を並列で実行する（独立した read-only 操作のため）。

- ディレクトリ構成を把握 (`find . -maxdepth 2 -type f | head -100` 等)
- README（または相当するドキュメント）を読む
- 依存定義を読む (`package.json` / `Cargo.toml` / `go.mod` / `pyproject.toml` 等)
- 最近の開発動向を確認 (`git log --oneline -20`)
- ビルド・CI 設定を確認 (`Makefile` / `Dockerfile` / `.github/workflows/` 等)
- エージェント設定があれば読む (`CLAUDE.md` / `AGENTS.md` / `.cursor/` 等)

**Phase 1 の出力**: 技術スタック（言語・フレームワーク・ビルドツール）、エントリポイント候補、プロジェクトの一行要約。

Phase 1 は `haiku-delegation` スキルの「検索・調査の下請け」カテゴリで委譲可能。

### Phase 2: アーキテクチャ読解（逐次）

Phase 1 で判明した技術スタックに応じて、エントリポイントからコードを辿る。

- エントリポイントの特定 (`main.ts`, `App.tsx`, `cmd/main.go`, `src/lib.rs` 等)
- ディレクトリ構成の意味を解読（レイヤード / モジュラー / モノレポ 等）
- 主要な抽象化（インタフェース・trait・protocol・基底クラス）の洗い出し
- データの流れ: 入力 -> 変換 -> 出力の経路
- 設定ファイルの体系（環境変数・config ファイル・ハードコード値）
- 外部サービス連携（API・DB・メッセージキュー）

**Phase 2 の出力**: アーキテクチャ図のドラフト（mermaid で表現可能な形）。

### Phase 3: 特徴的パターンの深掘り（standard/deep のみ）

プロジェクト固有の特徴を掘り下げる。

- コーディング規約・命名パターン
- エラーハンドリング戦略
- テスト構成と戦略
- セキュリティ対策（認証・認可の仕組み）
- パフォーマンス上の工夫
- 技術的負債の傾向 (`grep -r "TODO\|FIXME\|HACK\|XXX"` 等)

### Phase 4: 統合と洞察

Phase 1-3 の知見を統合し、以下を言語化する。

- このプロジェクトの設計思想は何か（1-2 文）
- 新規参加者が最初に読むべきファイル 3-5 個とその理由
- 拡張・変更する場合の典型的な手順
- 注意すべき落とし穴・ハマりどころ

## 3. アーティファクトのセクション構成

出力 HTML の推奨セクション構成。CSS・HTML テンプレートの詳細は `using-artifact-hub` スキルに従う。

| # | セクション | 内容 | quick | standard | deep |
|:--|:--|:--|:--|:--|:--|
| 01 | プロジェクト概要 | 名前・目的・一行要約、リポジトリ URL | 必須 | 必須 | 必須 |
| 02 | 技術スタック | 言語・フレームワーク・ビルドツール・主要依存（表形式） | 必須 | 必須 | 必須 |
| 03 | ディレクトリ構成 | 主要ディレクトリの役割（ツリー + 説明） | 必須 | 必須 | 必須 |
| 04 | アーキテクチャ | 全体構成図（mermaid）、レイヤ・モジュール間の関係 | -- | 必須 | 必須 |
| 05 | データフロー | 入力から出力までの主要経路（mermaid sequence/flowchart） | -- | 必須 | 必須 |
| 06 | エントリポイントと起動フロー | main から各サブシステムへの起動順序 | -- | 推奨 | 必須 |
| 07 | 特徴的パターン | コーディング規約・設計パターン・独自の工夫 | -- | -- | 必須 |
| 08 | テストと CI | テスト戦略・CI 構成・カバレッジ方針 | -- | -- | 推奨 |
| 09 | オンボーディングガイド | 最初に読むべきファイル、典型的な変更手順 | -- | 推奨 | 必須 |
| 10 | 所見と注意点 | 技術的負債・落とし穴・改善余地 | -- | -- | 推奨 |

「--」はそのスコープでは省略してよいことを示す。

### モノレポの場合

常に 1 アーティファクトにまとめる。パッケージ数が多い場合はセクション分割・折りたたみ (`<details>`)・ナビゲーション付きレイアウトで可読性を確保する。各パッケージの詳細はサブセクション (H3) として収容し、全体のアーキテクチャ図でパッケージ間の関係を示す。

## 4. 公開手順

`using-artifact-hub` スキルに従い、`kind: "html"` で公開する。

- **title**: `{プロジェクト名} -- コードベース調査` のフォーマット。クリックベイト禁止ルールに従う。
- **summary**: 調査で判明した主要な知見を 2-4 個の箇条書きで列挙（技術スタック・アーキテクチャパターン・注目点）。
- **tags**: `["codebase-investigation", "{言語}", "{フレームワーク}", "{プロジェクト名}"]` + プロジェクト固有のキーワード。必ず `codebase-investigation` タグを含める。
- **source**: `source.agent` に `"claude-code"` または `"codex"` を設定。
- 既存アーティファクトの更新の場合は同じ `id` を指定して `artifact_update` で上書きする。

## 5. スコープ別の省略ルール

- **quick**: Phase 1 のみ実行。アーティファクトはセクション 01-03。
- **standard**: Phase 1-2 + Phase 4 を実行。Phase 3 は主要な特徴のみ。
- **deep**: Phase 1-4 をすべて実行。Phase 3 でテスト・セキュリティ・パフォーマンスまで踏み込む。
