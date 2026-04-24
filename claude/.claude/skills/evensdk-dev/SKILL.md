---
name: evensdk-dev
description: Use when developing Even Realities G2 smart glasses apps (Even Hub plugins via `@evenrealities/even_hub_sdk`, `@evenrealities/evenhub-simulator`, `@evenrealities/evenhub-cli`, Web app in iPhone WebView over BLE). Covers SDK init (`waitForEvenAppBridge` vs `EvenAppBridge.getInstance`), input events (`CLICK_EVENT`=0 / `DOUBLE_CLICK_EVENT`=3 / `FOREGROUND_ENTER_EVENT`=4 with `eventType === undefined` deserialization pitfall), UI constraints (4-container/page limit, 576×288 px, 4-bit grayscale, no CSS/Flexbox), known SDK hangs (`listObject.itemContainer.itemName` non-ASCII → no BLE ACK, `rebuildPageContainer` needs `Promise.race` timeout), simulator-vs-device divergence for listObject/CORS/`currentSelectItemIndex`, iPhone WebView CORS workarounds (Vite proxy / allorigins.win), and low-level BLE protocol (base UUID `00002760-08c2-11e1-9073-0e8ac72e{xxxx}`, service UUIDs `5401`/`5402`/`6402`, CRC-16/CCITT Init=0xFFFF Poly=0x1021, teleprompter service `0x06-20` with Mid-Stream Marker type=255, Protobuf payload).
---

# Even Hub / G2 開発ガイド

Even Realities G2 スマートグラス向け Even Hub プラグイン開発のお作法と踏みやすい罠をまとめたもの。対象: Web アプリ (任意フレームワーク) + iPhone WebView + BLE 経由の G2 グラス。

このファイルは索引。詳細は `references/*.md` を参照する。

## 0. Quick lookup — 症状 → 原因候補

| 症状 | 原因候補 | 参照 |
| :-- | :-- | :-- |
| `rebuildPageContainer` が永遠に await されたまま返らない | BLE ACK が返ってこない → `Promise.race` でタイムアウト必須 | ui-constraints |
| listObject を描画した瞬間にハング | `listObject.itemContainer.itemName` に非 ASCII 文字 (日本語など) → G2 firmware が ACK 返さない | ui-constraints |
| `CLICK_EVENT` ハンドラが発火しない | `eventType === 0` が `undefined` にデシリアライズされている → `=== 0 \|\| === undefined` で判定 | sdk-usage |
| シミュレータでは動くのに実機でだけハング | listObject 日本語 / CORS / `currentSelectItemIndex` の初回値差異 | ui-constraints |
| Web アプリから外部 API 叩くと CORS エラー | iPhone WebView の制約 → Vite dev proxy or CORS proxy 経由 | ui-constraints |
| `bridge` が `undefined` / メソッドが存在しない | `waitForEvenAppBridge` を await せずに `getInstance` 呼んでいる | sdk-usage |
| レイアウトが崩れる / コンテナが 5 個目以降出ない | 1 ページあたり最大 4 コンテナ、ピクセル座標での絶対配置のみ | ui-constraints |
| 画像が意図と違う見た目になる | 全画像は 4-bit グレースケール (グリーン 16 階調) に変換される | ui-constraints |
| 自前 BLE 実装で ACK が来ない | CRC-16/CCITT (Init=0xFFFF, Poly=0x1021) の計算先 / リトルエンディアン | ble-protocol |
| テレプロンプタで Content Pages が欠落 | Mid-Stream Marker (`0x06-20`, type=255) を挟み忘れ | ble-protocol |

## 1. アーキテクチャ

```
[Your server] <--HTTPS--> [iPhone WebView] <--BLE--> [G2 Glasses]
```

- Web アプリ＋プロキシモデル
- iPhone がミドルウェアとして G2 と BLE 通信を中継する
- グラスはディスプレイ＆入力ペリフェラル — 独立した処理能力は持たない

**ハードウェア仕様**:

- ディスプレイ: デュアルマイクロ LED (グリーン)、**576 × 288 px / 眼**
- 色深度: **4-bit グレースケール** (グリーン 16 階調)
- 接続: BLE 5.x (最大 ~28 m)
- 入力: R1 リング、テンプルタッチジェスチャー
- センサー: マイク、装着検出

## 2. NPM パッケージ

```bash
npm install @evenrealities/evenhub-simulator   # シミュレーター
npm install @evenrealities/evenhub-cli         # CLI ツール
npm install @evenrealities/even_hub_sdk        # SDK コア
```

## 3. 詳細 references

- **`references/sdk-usage.md`** — SDK 初期化 (`waitForEvenAppBridge` / `EvenAppBridge.getInstance`)、入力イベント一覧、`CLICK_EVENT === undefined` ワークアラウンド、開発フロー、参考ドキュメント
- **`references/ui-constraints.md`** — UI システム (4 コンテナ / 絶対座標 / 固定幅フォント / 4-bit 画像)、listObject 非 ASCII ハング対策 + `toAsciiSafe`、`rebuildPageContainer` の `Promise.race` タイムアウト、シミュレータ/実機差異、WebView CORS
- **`references/ble-protocol.md`** — BLE サービス UUID、パケット構造、CRC-16/CCITT、サービス ID 一覧、デュアルチャネル、テレプロンプタープロトコル (`0x06-20`)、Protobuf ペイロード、リバース進捗

## 4. 公式・コミュニティ

- **Unofficial "What's Possible" Guide**: https://github.com/nickustinov/even-g2-notes/blob/main/G2.md
- **G2 BLE Protocol (リバースエンジニアリング)**: https://github.com/i-soxi/even-g2-protocol
- **Discord**: https://discord.gg/Y4jHMCU4sv
- **問い合わせ**: david.yu@evenrealities.com
