# ビルド / 署名 / テスト / プロファイリング

XcodeGen + `xcodebuild` の回し方、シミュレータと実機の挙動差、`xcrun devicectl`、Instruments、ユニットテストの設計。

## プロジェクト生成 — XcodeGen

```yaml
# project.yml 最小例
name: MyApp
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    visionOS: "26.0"
  xcodeVersion: "26.0"
  createIntermediateGroups: true

targets:
  MyApp:
    type: application
    platform: visionOS
    sources:
      - path: MyApp
      - path: Enterprise.license
        buildPhase: resources        # Enterprise 時のみ
    info:
      path: MyApp/Info.plist
      properties:
        NSWorldSensingUsageDescription: "..."
        NSHandsTrackingUsageDescription: "..."
        UIApplicationSceneManifest:
          UIApplicationPreferredDefaultSceneSessionRole: UIWindowSceneSessionRoleApplication
          UIApplicationSupportsMultipleScenes: true
          UISceneConfigurations: {}
        UILaunchScreen: {}
    entitlements:
      path: MyApp/MyApp.entitlements
    settings:
      base:
        SWIFT_VERSION: "6.0"
        VISIONOS_DEPLOYMENT_TARGET: "26.0"
        ENABLE_PREVIEWS: YES
```

- `project.yml` を変更したら必ず `xcodegen generate` を再実行
- `.xcodeproj` を手で編集しない (上書きされる)

## xcodebuild の罠

### DEVELOPER_DIR を明示する

Command Line Tools だけだと `xcodebuild` が sudo パスワードを要求する/フレームワーク未検出になる:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme MyApp -destination 'generic/platform=visionOS' build
```

alias にしておくと楽:

```bash
alias xcb='DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild'
```

### destination の違い

| destination | 用途 |
| :-- | :-- |
| `generic/platform=visionOS` | 実機汎用 (ipa 生成) |
| `generic/platform=visionOS Simulator` | Sim 汎用 |
| `platform=visionOS Simulator,name=Apple Vision Pro` | 特定 Sim で test |
| `id=<UDID>` | 特定実機 |

### archive → export

```bash
# archive
xcodebuild -scheme MyApp \
  -destination 'generic/platform=visionOS' \
  -archivePath build/MyApp.xcarchive \
  archive

# ipa export
xcodebuild -exportArchive \
  -archivePath build/MyApp.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist
```

### 署名エラーの切り分け

| エラー | 原因 |
| :-- | :-- |
| `No profiles for 'com.example.MyApp' were found` | Bundle ID に対する provisioning profile が Team に無い |
| `requires a provisioning profile with the ... feature` | entitlement に対応する capability が App ID に未登録 |
| `Code Signing Error: entitlements file MyApp.entitlements specifies ... but the profile does not contain them` | profile を再ダウンロード (Xcode > Preferences > Accounts > Download Manual Profiles) |

## Sim vs 実機 対応表

visionOS Simulator はカメラ系・Enterprise 系がすべて動かない。早い段階で実機検証を組み込む。

| 機能 | Sim | 実機 |
| :-- | :-: | :-: |
| WorldTracking | × | ✓ |
| HandTracking | × | ✓ |
| PlaneDetection | × | ✓ |
| SceneReconstruction | × | ✓ |
| MainCameraAccess (Enterprise) | × | ✓ |
| WorldAnchor 永続化 | × | ✓ |
| RealityKit レンダ | ✓ | ✓ |
| RealityView Attachments | ✓ | ✓ |
| SpatialTapGesture / DragGesture | ✓ | ✓ |
| ImmersiveSpace の開閉 | ✓ | ✓ |
| EnterpriseLicenseDetails | × (常に `.notFound`) | ✓ |

Sim では `ARKitProvider.isSupported` が **false** を返す。ガードがないと認可要求すら飛ばず沈黙するので、`isSupported` false 時は UI で「実機必須」を表示するのが親切。

## xcrun devicectl — 実機制御

Vision Pro への install / launch / ログ取得。

```bash
# 接続デバイス一覧
xcrun devicectl list devices

# アプリインストール
xcrun devicectl device install app \
  --device <DEVICE_ID> \
  /path/to/MyApp.app

# 起動
xcrun devicectl device process launch \
  --device <DEVICE_ID> \
  --environment-variables "DEBUG=1" \
  com.example.MyApp

# プロセス一覧
xcrun devicectl device info processes --device <DEVICE_ID>

# ロック状態/バッテリ
xcrun devicectl device info lockState --device <DEVICE_ID>
```

ログは Console.app で該当デバイスを選択して subsystem/process でフィルタするのが最速。

## Instruments (visionOS)

Xcode > Open Developer Tool > Instruments で **"visionOS" テンプレートグループ**を使う。

### FPS / フレーム時間

- "Metal System Trace" でフレーム時間を可視化
- "Points of Interest" に `os_signpost` を仕込むと actor メソッド境界が可視化される:

```swift
import os

private let signposter = OSSignposter(subsystem: "MyApp", category: "sensor")

actor SensorManager {
    func process() async {
        let state = signposter.beginInterval("process")
        defer { signposter.endInterval("process", state) }
        // ...
    }
}
```

### ARKit / RealityKit

- "ARKit" template で anchor イベント頻度、authorization 状態を確認
- "RealityKit Trace" で Entity 更新回数、レンダリングコストを測定
- Hand/World/Plane/Scene の Hz が期待値 (1-90 Hz) 未満なら overload

### CPU Profiler の読み方

- actor は独自スレッドではなく cooperative thread pool で走る
- メソッド名に `[Actor].<func>` が出るので、各 actor のホットスポットを特定できる
- `@MainActor` に重い処理が載っていないかが最優先チェックポイント

## ユニットテスト戦略

ARKitSession は実機必須なので、テスタブルにするには抽象化が必要。

### ARKitSession を protocol で抽象化

```swift
protocol SensorSession: Sendable {
    func requestAuthorization(for: [ARKitSession.AuthorizationType]) async
        -> [ARKitSession.AuthorizationType: ARKitSession.AuthorizationStatus]
    func run(_ providers: [any DataProvider]) async throws
    func stop()
}

extension ARKitSession: SensorSession {}

actor SensorManager {
    private let session: SensorSession
    init(session: SensorSession = ARKitSession()) { self.session = session }
    // ...
}

// テスト用
final class MockSensorSession: SensorSession { /* ... */ }
```

### 計算関数を純粋関数として切り出す

Hand joint → world transform の計算は `ARKitSession` 不要。

```swift
// 純粋関数 — ユニットテスト可能
func worldTransform(
    handOrigin: simd_float4x4,
    jointLocal: simd_float4x4
) -> simd_float4x4 {
    handOrigin * jointLocal
}

// テスト
func testWorldTransform_identity() {
    let result = worldTransform(handOrigin: .identity, jointLocal: .identity)
    XCTAssertEqual(result, matrix_identity_float4x4)
}
```

### Integration test は実機

Full Space に依存するロジック (actual ARKit anchor / Enterprise license / MainCamera) は**実機でしかテストできない**。テスト目標:

- ユニットテスト (Sim で高速): 計算関数、状態機械、SwiftUI view の state 遷移
- Integration テスト (実機手動): 権限フロー、anchor 受信、永続化復元、Enterprise status

### プレビュー (`#Preview`) でできること

- SwiftUI view のレイアウト確認
- RealityView の Entity 初期配置確認
- ARKit 系は動かない — 常に静的モックで値を流す

## 参考コマンド (チートシート)

```bash
# プロジェクト再生成
xcodegen generate

# Debug build
xcb -scheme MyApp -destination 'generic/platform=visionOS' build

# Test (Sim)
xcb -scheme MyApp -destination 'platform=visionOS Simulator,name=Apple Vision Pro' test

# Archive + export
xcb -scheme MyApp -destination 'generic/platform=visionOS' \
    -archivePath build/MyApp.xcarchive archive
xcb -exportArchive -archivePath build/MyApp.xcarchive \
    -exportPath build/ -exportOptionsPlist ExportOptions.plist

# 実機 install + launch
xcrun devicectl device install app --device <ID> build/MyApp.app
xcrun devicectl device process launch --device <ID> com.example.MyApp

# entitlement 埋め込み確認
codesign -d --entitlements :- build/MyApp.app
```
