# ImmersiveSpace ライフサイクル / WorldAnchor 永続化

Full Space の開閉、`scenePhase` での ARKitSession 停止/再開、WorldAnchor の永続化。

## Scene ライフサイクル

### 開く / 閉じる

```swift
@main
struct MyApp: App {
    @State var immersionStyle: ImmersionStyle = .mixed

    var body: some Scene {
        WindowGroup {
            ContentView()   // ← 開閉ボタン
        }

        ImmersiveSpace(id: "MainSpace") {
            ImmersiveView()
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed, .progressive, .full)
    }
}

struct ContentView: View {
    @Environment(\.openImmersiveSpace)    private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isImmersive = false

    var body: some View {
        Toggle("Immersive", isOn: $isImmersive)
            .onChange(of: isImmersive) { _, newValue in
                Task {
                    if newValue {
                        let result = await openImmersiveSpace(id: "MainSpace")
                        switch result {
                        case .opened:         break
                        case .userCancelled:  isImmersive = false
                        case .error:          isImmersive = false
                        @unknown default:     isImmersive = false
                        }
                    } else {
                        await dismissImmersiveSpace()
                    }
                }
            }
    }
}
```

### immersionStyle の差

| Style | 視界 | ユーザーがダイヤルで戻せるか |
| :-- | :-- | :-- |
| `.mixed` | 現実に 3D を重ねる (AR 風) | — |
| `.progressive` | 現実とアプリが混ざる。ユーザーがダイヤルで調整可 | ✓ ダイヤル |
| `.full` | 完全没入 (現実遮断) | — |

`selection: $immersionStyle` で動的に切り替え可能。

### OpenImmersiveSpaceAction.Result の分岐忘れ

- `.opened`: 成功
- `.userCancelled`: ユーザーが同意シートでキャンセル
- `.error`: 失敗 (他のアプリが Full Space を占有中など)
- `@unknown default:` — **Swift 6 で必須**

## scenePhase 対応 — ARKitSession は OS が止める

```swift
struct ImmersiveView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var sensorManager = SensorManager()

    var body: some View {
        RealityView { content in ... }
            .task {
                try? await sensorManager.start()
            }
            .onChange(of: scenePhase) { _, newPhase in
                Task {
                    switch newPhase {
                    case .background, .inactive:
                        await sensorManager.stop()     // OS 側が止める前に明示停止
                    case .active:
                        try? await sensorManager.start()   // 再入時は再度 run()
                    @unknown default:
                        break
                    }
                }
            }
    }
}
```

### 罠

- **ARKitSession はバックグラウンドで OS から強制停止される**。復帰時に自動再開しない → `.active` で明示的に `run()` を再呼出
- **`session.run()` は再起動扱い** — provider リストを再構築してから渡す
- **ImmersiveSpace が閉じられた状態で `.active` トランジションが来る場合がある** — ImmersiveSpace の生存判定と scenePhase の判定を混ぜないこと (ImmersiveView 内の `.task` は ImmersiveSpace がアクティブな時だけ動く)
- WindowGroup の View から ARKit を制御しようとしないこと — provider が Full Space で無いと anchor 来ない

## WorldAnchor 永続化

`WorldTrackingProvider` は anchor を OS 側に永続化する機能を持つ。ARKitSession を再起動しても位置が蘇る。

### 追加

```swift
// ユーザーが置いた場所を永続化 (例: HandTracking で tap した位置)
let anchor = WorldAnchor(originFromAnchorTransform: tapWorldTransform)
try await worldTrackingProvider.addAnchor(anchor)
```

### 復元

ARKitSession 再起動時、すでに永続化された anchor は `anchorUpdates` の `.added` イベントで流れてくる:

```swift
for await update in worldTrackingProvider.anchorUpdates {
    switch update.event {
    case .added:
        // 再起動後、過去セッションで保存した anchor はここに来る
        let anchor = update.anchor   // WorldAnchor
        let id: UUID = anchor.id
        let transform = anchor.originFromAnchorTransform
        restoreVisualization(for: id, at: transform)
    case .updated: /* 位置補正 */
    case .removed: /* 削除通知 */
    }
}
```

### 削除

```swift
try await worldTrackingProvider.removeAnchor(anchor)
// または id で
try await worldTrackingProvider.removeAnchor(forID: uuid)
```

### ポイント

- **UUID を自前で保存する必要はない** — WorldAnchor 自身が `id: UUID` を持ち、OS が永続化
- 永続化の上限や TTL は非公開。実用上は 数百個 程度なら安定
- Bundle ID / ユーザー単位で分離されている — 他アプリのアンカーは見えない
- シミュレータでは永続化されない (そもそも WorldTracking 未対応)
