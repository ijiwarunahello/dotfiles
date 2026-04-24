# UI 制約とハマりどころ

G2 の UI はファームウェア側で強く制約されていて、普通の Web UI のつもりで書くと高確率でハマる。既知の地雷とその対策。

## UI システムの基本制約

- 1 ページあたり最大 **4 コンテナ**
- コンテナはピクセル座標で**絶対配置**（CSS/Flexbox は使用不可）
- コンテナ種別: **Text / List / Image**
- フォント制御不可、固定幅フォントのみ
- 全画像は **4-bit グレースケール**（グリーン 16 階調）に変換される
- 解像度は **576 × 288 px / 眼**

レイアウトはピクセル単位で設計する前提。「ブラウザでいい感じに並べる」発想は捨てる。

## listObject と textObject の文字セット制約

- `listObject.itemContainer.itemName`（リスト項目）に **ASCII 範囲外の文字（日本語など）を含めると G2 ファームウェアが BLE ACK を返さず、SDK の Promise が無限にハングする**
- `textObject.content`（テキストコンテナ）は日本語をそのまま扱える
- 対策: listObject に渡す文字列は事前に非 ASCII 文字を除去する

```typescript
function toAsciiSafe(text: string): string {
  return text.replace(/[^\x00-\x7F]/g, ' ').replace(/\s+/g, ' ').trim();
}
```

症状だけ見ると「SDK が壊れている」ように見えるので、原因特定までに時間を溶かしやすい。ユーザー入力をそのまま listObject に流さない。

## rebuildPageContainer のハング対策

BLE ACK が返らない場合に `rebuildPageContainer` が永遠に await されることがある。
`Promise.race` でタイムアウトを設けて確実にエラーハンドリングできるようにする。

```typescript
const timeout = new Promise<never>((_, reject) =>
  setTimeout(() => reject(new Error('timeout')), 15_000)
);
return await Promise.race([bridge.rebuildPageContainer(config), timeout]);
```

15 秒は実機の ACK 往復の余裕を見た目安。短すぎると正常ケースで誤タイムアウトする。

## シミュレーターと実機の差異

| 項目 | シミュレーター | 実機 |
|------|-------------|------|
| 日本語 listObject | 問題なし（モック処理） | ハング |
| `currentSelectItemIndex` 初回値 | `undefined` になることがある | 正常 |
| CORS | 制限なし | WebView の制約あり（プロキシ必要） |

シミュレーターで「動いた」が実機で即ハマるのがよくあるパターン。特に listObject と CORS は**必ず実機で一度通す**。

## iPhone WebView からの外部 HTTP リクエスト

iPhone の Even App WebView から RSS 等の外部 URL を直接 fetch すると CORS でブロックされる。対処:

- 開発中: Vite の dev server プロキシ
- 本番: 外部 CORS プロキシ（allorigins.win、corsproxy.io など）を経由

アプリから直接外部 API を叩けない前提で設計する。自前サーバー経由のほうがトークン等も扱いやすい。
