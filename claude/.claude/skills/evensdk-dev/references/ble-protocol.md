# G2 BLE プロトコル（リバースエンジニアリング）

SDK の下位レイヤーで動作する BLE プロトコルの仕様。直接 BLE 通信を行う場合や、SDK の挙動を理解するために参照する。出典: https://github.com/i-soxi/even-g2-protocol

## BLE サービス UUID

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

## パケット構造

```
[AA] [Type] [Seq] [Len] [PktTot] [PktSer] [SvcHi] [SvcLo] [Payload...] [CRC_Lo] [CRC_Hi]
 [0]   [1]   [2]   [3]    [4]      [5]      [6]      [7]      [8:N-2]     [N-1]    [N]
```

- **Type**: `0x21` = コマンド（Phone→Glasses）、`0x12` = レスポンス（Glasses→Phone）
- **Len**: ペイロード長 + 2（CRC 含む）
- **CRC**: CRC-16/CCITT (Init=`0xFFFF`, Poly=`0x1021`), ペイロードのみ対象, リトルエンディアン
- **マルチパケット**: MTU 超過時は `PktTot` / `PktSer` で分割（`Seq` ID は全パケット共通）

## サービス ID 一覧

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

## デュアルチャネルアーキテクチャ

- **Content Channel (`0x5401`)**: 表示データの送信（テキスト、構造化データ）
- **Rendering Channel (`0x6402`)**: 表示方法の制御（座標、スタイリング）

## テレプロンプタープロトコル (`0x06-20`)

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

## Protobuf ペイロード

ペイロードは protobuf エンコーディング。主要メッセージ定義:

- `TeleprompterMessage`: type(1), msg_id(2), init/list/content/complete/marker
- `DisplayConfig`: type(1), msg_id(2), settings(4) — リージョン定義含む
- `ConversateTranscript`: text(1), is_final(2)
- `NotificationData`: app_id(1), count(2) — メタデータのみ、テキストなし

詳細な `.proto` 定義: https://github.com/i-soxi/even-g2-protocol/tree/main/proto

## リバースエンジニアリング状況

| 機能 | ステータス |
|------|-----------|
| BLE 接続 | 動作確認済み |
| 認証 | 動作確認済み（7 パケットハンドシェイク） |
| テレプロンプター | 動作確認済み |
| カレンダーウィジェット | 動作確認済み |
| 通知 | 部分的（メタデータのみ） |
| Even AI | 調査中 |
| ナビゲーション | 調査中 |

## コミュニティ・問い合わせ

- **Discord**: https://discord.gg/Y4jHMCU4sv
- **問い合わせ**: david.yu@evenrealities.com
