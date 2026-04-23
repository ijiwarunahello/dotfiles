---
name: evensdk-dev
description: Use when developing Even Realities G2 smart glasses apps (Even Hub plugins, BLE protocol, SDK, simulator/CLI). Covers SDK init, UI constraints (4-container limit, ASCII restrictions for listObject), known SDK hangs and timeout patterns, BLE packet structure, teleprompter protocol, and CORS/WebView constraints from iPhone.
---

# Even Hub Pilot 開発ガイド

## 概要

このプロジェクトは Even Realities G2 スマートグラスのアプリ（Even Hub プラグイン）を開発するためのワークスペースです。

## 開発ドキュメント

開発は以下の公式・非公式ドキュメントを参照して行います。

- **Unofficial "What's Possible" Guide**: https://github.com/nickustinov/even-g2-notes/blob/main/G2.md
  - アーキテクチャ、SDK API、UI システム、イベント処理など、開発に必要な技術情報が網羅されている
- **G2 BLE Protocol（リバースエンジニアリング）**: https://github.com/i-soxi/even-g2-protocol
  - BLE パケット構造、サービス ID、認証ハンドシェイク、テレプロンプタープロトコル等の低レベル仕様

## NPM パッケージ

```bash
npm install @evenrealities/evenhub-simulator   # シミュレーター
npm install @evenrealities/evenhub-cli         # CLI ツール
npm install @evenrealities/even_hub_sdk        # SDK コア
```

- **Simulator**: https://www.npmjs.com/package/@evenrealities/evenhub-simulator
- **CLI**: https://www.npmjs.com/package/@evenrealities/evenhub-cli
- **SDK**: https://www.npmjs.com/package/@evenrealities/even_hub_sdk

## アーキテクチャ

```
[Your server] <--HTTPS--> [iPhone WebView] <--BLE--> [G2 Glasses]
```

- Web アプリ＋プロキシモデル
- iPhone がミドルウェアとして G2 グラスと BLE 通信を中継する
- グラスはディスプレイ＆入力ペリフェラルとして機能し、独立した処理能力は持たない

## ハードウェア仕様

- **ディスプレイ**: デュアルマイクロ LED（グリーン）、576×288 px / 眼
- **色深度**: 4-bit グレースケール（グリーン 16 階調）
- **接続**: BLE 5.x（最大約 28m）
- **入力**: R1 リング、テンプルタッチジェスチャー
- **センサー**: マイク、装着検出

## UI システム

- 1 ページあたり最大 **4 コンテナ**
- コンテナはピクセル座標で絶対配置（CSS/Flexbox は使用不可）
- コンテナ種別: **Text / List / Image**
- フォント制御不可、固定幅フォントのみ
- 全画像は 4-bit グレースケールに変換される

## SDK 初期化

```js
// 推奨（非同期）
const bridge = await waitForEvenAppBridge();

// 同期（初期化後のみ）
const bridge = EvenAppBridge.getInstance();
```

## 入力イベント

| イベント | 値 | 内容 |
|---------|---|------|
| `CLICK_EVENT` | 0 | リング/テンプルタップ |
| `DOUBLE_CLICK_EVENT` | 3 | ダブルタップ |
| `FOREGROUND_ENTER_EVENT` | 4 | アプリ前面 |
| `FOREGROUND_EXIT_EVENT` | 5 | アプリ背面 |
| `ABNORMAL_EXIT_EVENT` | 6 | 切断 |

**注意**: `CLICK_EVENT`（値 0）はデシリアライズ時に `undefined` になる場合があるため、`eventType === 0 || eventType === undefined` で判定する。

## 開発フロー

1. SDK をインポートした Web アプリを構築（任意のフレームワーク可）
2. 開発中: localhost で起動 → Even App が WebView で URL を読み込む
3. 本番: 任意のホストにデプロイ → Even App からそのURLを読み込む
4. シミュレーターで動作確認（`even-dev` 環境）

## 既知の挙動・注意事項

### listObject と textObject の文字セット制約

- `listObject.itemContainer.itemName`（リスト項目）に **ASCII 範囲外の文字（日本語など）を含めると G2 ファームウェアが BLE ACK を返さず、SDK の Promise が無限にハングする**
- `textObject.content`（テキストコンテナ）は日本語をそのまま扱える
- 対策: listObject に渡す文字列は事前に非 ASCII 文字を除去する

```typescript
function toAsciiSafe(text: string): string {
  return text.replace(/[^\x00-\x7F]/g, ' ').replace(/\s+/g, ' ').trim();
}
```

### rebuildPageContainer のハング対策

BLE ACK が返らない場合に `rebuildPageContainer` が永遠に await されることがある。
`Promise.race` でタイムアウトを設けて確実にエラーハンドリングできるようにする。

```typescript
const timeout = new Promise<never>((_, reject) =>
  setTimeout(() => reject(new Error('timeout')), 15_000)
);
return await Promise.race([bridge.rebuildPageContainer(config), timeout]);
```

### シミュレーターと実機の差異

| 項目 | シミュレーター | 実機 |
|------|-------------|------|
| 日本語 listObject | 問題なし（モック処理） | ハング |
| `currentSelectItemIndex` 初回値 | `undefined` になることがある | 正常 |
| CORS | 制限なし | WebView の制約あり（プロキシ必要） |

### iPhone WebView からの外部 HTTP リクエスト

iPhone の Even App WebView から RSS 等の外部 URL を直接 fetch すると CORS でブロックされる。
Vite の dev server プロキシか、外部 CORS プロキシ（allorigins.win、corsproxy.io 等）を経由する。

## G2 BLE プロトコル（リバースエンジニアリング）

SDK の下位レイヤーで動作する BLE プロトコルの仕様。直接 BLE 通信を行う場合や、SDK の挙動を理解するために参照する。

### BLE サービス UUID

```
ベース UUID: 00002760-08c2-11e1-9073-0e8ac72e{xxxx}
```

| UUID サフィックス | 用途 |
|------------------|------|
| `0000` | メインサービス |
| `5401` | Write（コマンド送信: Phone → Glasses） |
| `5402` | Notify（レスポンス: Glasses → Phone） |
| `6402` | ディスプレイレンダリング |

- **MTU**: 512 bytes
- **接続パラメータ**: Interval 7.5-30ms, Supervision Timeout 2000ms
- **ペアリング**: 標準 BLE ペアリング不要、アプリレベルの 7 パケットハンドシェイクで認証

### パケット構造

```
[AA] [Type] [Seq] [Len] [PktTot] [PktSer] [SvcHi] [SvcLo] [Payload...] [CRC_Lo] [CRC_Hi]
 [0]   [1]   [2]   [3]    [4]      [5]      [6]      [7]      [8:N-2]     [N-1]    [N]
```

- **Type**: `0x21` = コマンド（Phone→Glasses）、`0x12` = レスポンス（Glasses→Phone）
- **Len**: ペイロード長 + 2（CRC 含む）
- **CRC**: CRC-16/CCITT (Init=0xFFFF, Poly=0x1021), ペイロードのみ対象, リトルエンディアン
- **マルチパケット**: MTU 超過時は PktTot/PktSer で分割（Seq ID は全パケット共通）

### サービス ID 一覧

| サービス ID | 名前 | 説明 |
|------------|------|------|
| `0x80-00` | Auth Control | セッション管理・同期 |
| `0x80-20` | Auth Data | 認証（ペイロード付き） |
| `0x04-20` | Display Wake | ディスプレイ起動 |
| `0x06-20` | Teleprompter | テキスト表示・スクリプト |
| `0x07-20` | Dashboard | ウィジェット（カレンダー等） |
| `0x09-00` | Device Info | バージョン・ファームウェア |
| `0x0B-20` | Conversate | 音声トランスクリプション |
| `0x0C-20` | Tasks | ToDo リスト |
| `0x0D-00` | Configuration | デバイス設定 |
| `0x0E-20` | Display Config | ディスプレイパラメータ |
| `0x20-20` | Commit | 変更確定 |

### デュアルチャネルアーキテクチャ

- **Content Channel (0x5401)**: 表示データの送信（テキスト、構造化データ）
- **Rendering Channel (0x6402)**: 表示方法の制御（座標、スタイリング）

### テレプロンプタープロトコル (0x06-20)

スクロール可能なテキスト表示。メッセージシーケンス:

1. 認証パケット（7 パケット）
2. Display Config (`0x0E-20`, type=2)
3. Teleprompter Init (`0x06-20`, type=1) — スクリプト選択・モード設定
4. Content Pages 0-9 (`0x06-20`, type=3)
5. Mid-Stream Marker (`0x06-20`, type=255) — 必須マーカー
6. Content Pages 10-11 (`0x06-20`, type=3)
7. Sync Trigger (`0x80-00`, type=14)
8. 残りの Content Pages (`0x06-20`, type=3)

**メッセージタイプ**:

| Type | 用途 |
|------|------|
| 1 | Init（スクリプト選択・表示モード設定） |
| 2 | Script List（デバイス上のスクリプト一覧） |
| 3 | Content Page（テキストコンテンツ送信） |
| 4 | Content Complete（送信完了通知） |
| 255 | Mid-Stream Marker（ストリーミング中の必須マーカー） |

**表示仕様**: 1 行 ~25 文字、1 ページ 10 行、可視領域 ~7 行

**スクロールモード**: `0x00` = 手動（"M" インジケータ）、`0x01` = AI モード（アニメーション）

### Protobuf ペイロード

ペイロードは protobuf エンコーディング。主要メッセージ定義:

- `TeleprompterMessage`: type(1), msg_id(2), init/list/content/complete/marker
- `DisplayConfig`: type(1), msg_id(2), settings(4) — リージョン定義含む
- `ConversateTranscript`: text(1), is_final(2)
- `NotificationData`: app_id(1), count(2) — メタデータのみ、テキストなし

詳細な .proto 定義: https://github.com/i-soxi/even-g2-protocol/tree/main/proto

### リバースエンジニアリング状況

| 機能 | ステータス |
|------|-----------|
| BLE 接続 | 動作確認済み |
| 認証 | 動作確認済み（7 パケットハンドシェイク） |
| テレプロンプター | 動作確認済み |
| カレンダーウィジェット | 動作確認済み |
| 通知 | 部分的（メタデータのみ） |
| Even AI | 調査中 |
| ナビゲーション | 調査中 |

## コミュニティ

- **Discord**: https://discord.gg/Y4jHMCU4sv
- **問い合わせ**: david.yu@evenrealities.com
