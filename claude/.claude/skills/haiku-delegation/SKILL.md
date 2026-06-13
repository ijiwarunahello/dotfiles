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
