# SDK 利用

`@evenrealities/even_hub_sdk` を使った Even Hub プラグイン開発の基本。

## SDK 初期化

```js
// 推奨（非同期）— bridge 準備完了まで待つ
const bridge = await waitForEvenAppBridge();

// 同期（初期化後のみ安全）
const bridge = EvenAppBridge.getInstance();
```

開発初期は `waitForEvenAppBridge` を使うのが安全。`getInstance` は一度 bridge が立ち上がっていることが確定している箇所でのみ使う。

## 入力イベント

| イベント | 値 | 内容 |
|---------|---|------|
| `CLICK_EVENT` | 0 | リング/テンプルタップ |
| `DOUBLE_CLICK_EVENT` | 3 | ダブルタップ |
| `FOREGROUND_ENTER_EVENT` | 4 | アプリ前面 |
| `FOREGROUND_EXIT_EVENT` | 5 | アプリ背面 |
| `ABNORMAL_EXIT_EVENT` | 6 | 切断 |

**注意**: `CLICK_EVENT`（値 0）はデシリアライズ時に `undefined` になる場合があるため、`eventType === 0 || eventType === undefined` で判定する。

```js
bridge.on('input', (e) => {
  const t = e.eventType;
  if (t === 0 || t === undefined) {
    handleClick();
  }
});
```

## NPM パッケージ

```bash
npm install @evenrealities/evenhub-simulator   # シミュレーター
npm install @evenrealities/evenhub-cli         # CLI ツール
npm install @evenrealities/even_hub_sdk        # SDK コア
```

- **Simulator**: https://www.npmjs.com/package/@evenrealities/evenhub-simulator
- **CLI**: https://www.npmjs.com/package/@evenrealities/evenhub-cli
- **SDK**: https://www.npmjs.com/package/@evenrealities/even_hub_sdk

## 開発フロー

1. SDK をインポートした Web アプリを構築（任意のフレームワーク可）
2. 開発中: localhost で起動 → Even App が WebView で URL を読み込む
3. 本番: 任意のホストにデプロイ → Even App からその URL を読み込む
4. シミュレーター（`even-dev` 環境）で動作確認

実機での検証は `ui-constraints.md` の「シミュレーターと実機の差異」表を必ず参照すること — 実機でしか出ないハングが存在する。

## 参考ドキュメント

- **Unofficial "What's Possible" Guide**: https://github.com/nickustinov/even-g2-notes/blob/main/G2.md
  — アーキテクチャ、SDK API、UI システム、イベント処理など開発に必要な情報が網羅されている
- **G2 BLE Protocol (リバースエンジニアリング)**: https://github.com/i-soxi/even-g2-protocol
  — BLE パケット構造、サービス ID、認証ハンドシェイク、テレプロンプタープロトコル等の低レベル仕様
