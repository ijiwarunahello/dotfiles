---
name: visionos-dev
description: Use when developing visionOS apps for Apple Vision Pro (Swift/SwiftUI, ARKit, RealityKit, hand/world/plane/scene tracking, RealityView, Enterprise APIs/entitlements, XcodeGen). Covers Swift 6 strict concurrency for ARKit (single ARKitSession.run([providers]) pattern), DeviceAnchor.originFromAnchorTransform, HandSkeleton 27 joints, system gesture suppression (.upperLimbVisibility/.allowsHitTesting), Enterprise license debugging (XPC sandbox Code 4099, EnterpriseLicenseDetails.shared, EnterpriseEntitlement allCases), Full Space requirement, and xcodebuild quirks (DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer).
---

# visionOS 開発ガイド

Apple Vision Pro / visionOS アプリ開発のお作法と踏みやすい罠をまとめたもの。Swift / SwiftUI / ARKit / RealityKit / Vision Pro Enterprise API を対象とする。

## 1. 動作環境とツール

- **visionOS**: 26.0+
- **Swift**: 6.0 (strict concurrency 前提)
- **Xcode**: 26.0
- **XcodeGen**: `project.yml` からの Xcode プロジェクト生成 (本ガイドの全プロジェクトで採用)
- **uv**: Python 連携 (avp-stream など) の依存解決

## 2. プロジェクトセットアップ (XcodeGen)

```yaml
# project.yml の最小例
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
    settings:
      base:
        SWIFT_VERSION: "6.0"
        VISIONOS_DEPLOYMENT_TARGET: "26.0"
        ENABLE_PREVIEWS: YES
```

### Info.plist プライバシーキー

| キー | 用途 |
| :-- | :-- |
| `NSWorldSensingUsageDescription` | World / Plane / Scene Reconstruction 共通 |
| `NSHandsTrackingUsageDescription` | HandTracking |
| `NSPhotoLibraryUsageDescription` | 写真ライブラリ |
| `NSMainCameraUsageDescription` | Enterprise 限定: メインカメラアクセス |

権限キーを忘れると **エラーは出ずデータも来ない** ので発見が遅れる。Plist と `requestAuthorization` 両方が必須。

## 3. ビルドコマンド

```bash
xcodegen generate                                            # project.yml → .xcodeproj
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme MyApp -destination 'generic/platform=visionOS' build
```

- **Command Line Tools のみでは不足** — `DEVELOPER_DIR` で full Xcode を指定しないと `xcodebuild` が sudo パスワードを要求する/フレームワークが見つからない
- `project.yml` を編集したら必ず `xcodegen generate` を再実行

## 4. シーン構成

- `WindowGroup` — 通常の 2D ウィンドウ
- `ImmersiveSpace` — Full Space (空間没入)
- `UIApplicationSceneManifest` で複数シーン宣言

> **重要**: ARKit のデータプロバイダ (HandTracking / WorldTracking 等) は **Full Space (ImmersiveSpace) でしか動かない**。Shared Space (WindowGroup / Volume) では認可が通っても anchor が一切来ない。

## 5. ARKit ベストプラクティス

公式パターンと実プロジェクト (SensorScope) で実証済み。

```swift
import ARKit

actor SensorManager {
    private let session = ARKitSession()
    private let worldSensor = WorldTrackingSensor()
    private let handSensor  = HandTrackingSensor()

    func start(...) async throws {
        // (1) 一括認可
        let statuses = await session.requestAuthorization(
            for: [.worldSensing, .handTracking]
        )
        for (type, status) in statuses where status != .allowed {
            throw SensorError.authorizationDenied("\(type)")
        }

        // (2) 全プロバイダを 1 回の run() にまとめる
        var providers: [any DataProvider] = []
        if WorldTrackingSensor.isSupported { providers.append(worldSensor.provider) }
        if HandTrackingSensor.isSupported  { providers.append(handSensor.provider) }
        try await session.run(providers)

        // (3) anchorUpdates を並列処理
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.worldSensor.process(...) }
            group.addTask { try await self.handSensor.process(...) }
            try await group.waitForAll()
        }
    }

    func stop() {
        session.stop()   // 明示的に停止 (キャンセル任せにしない)
    }
}
```

### 守るべきルール

- **`ARKitSession` を強参照**で保持 (release されると provider も死ぬ)
- **`session.run()` は 1 回だけ**、配列 `[any DataProvider]` で全 provider をまとめる (2 回呼ぶと壊れる)
- 各 Provider の **static `isSupported`** を必ず確認 (デバイス互換)
- 終了時は **明示的に `session.stop()`**
- センサーごとに `actor` 化、`nonisolated let provider` で provider への並行アクセスを許可

## 6. トラッキングプロバイダ

### WorldTrackingProvider — 頭部姿勢

```swift
let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(
    atTimestamp: CACurrentMediaTime()
)
let transform: simd_float4x4 = deviceAnchor?.originFromAnchorTransform ?? .init()
// → 頭部の 4×4 ワールド変換行列 (位置 + 回転)
```

### HandTrackingProvider — 27 関節

```swift
let (left, right) = handTrackingProvider.latestAnchors

for hand in [left, right] {
    guard let hand,
          let joint = hand.handSkeleton?.joint(.thumbTip) else { continue }
    let world = hand.originFromAnchorTransform * joint.anchorFromJointTransform
    // ↑ 関節のワールド座標
}

// 全関節を網羅したい場合
for jointName in HandSkeleton.JointName.allCases {
    // 27 関節 (wrist, forearmWrist, forearmArm, 5 指 × 5 関節)
}
```

- `handAnchor.chirality` が `.left` / `.right` を返す
- すべての関節は `.wrist` を root とする階層

### PlaneDetectionProvider / SceneReconstructionProvider

- 同じ `ARKitSession` に渡して並走可
- `.isSupported` チェック必須 (Mac/Sim 等で false になる)
- **`MeshAnchor` / `PlaneAnchor` をそのまま蓄積するとメモリ上限なく増え続ける** — 必要なのが count なら count のみ保持

## 7. RealityKit パターン

```swift
RealityView { content in
    // make: 初期エンティティ追加
    let root = Entity()
    for _ in 0..<27 {
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.006), ...)
        root.addChild(sphere)   // 事前割り当て
    }
    content.add(root)
} update: { content in
    // update: 毎フレーム transform のみ更新
    // (子 entity を毎フレーム作り直さない)
}
.upperLimbVisibility(.hidden)         // ← RealityView の閉じカッコの外!
.allowsHitTesting(false)              // 内側に書くとビルドエラー
```

- **Entity は事前割り当て**して毎フレーム `transform` だけ更新するのが基本パターン (生成コスト回避)
- インタラクション entity は `CollisionComponent(shapes:)` + `InputTargetComponent()` の両方が必要

## 8. システムジェスチャ制御

ハンドトラッキング中にシステムの look+pinch 描画と当たり判定を抑制したいとき:

```swift
.upperLimbVisibility(.hidden)     // システムの手描画 (上肢) を非表示
.allowsHitTesting(false)          // look+pinch 入力を無効化
```

`.upperLimbVisibility(_:)` の値: `.visible` / `.hidden` / `.automatic`

## 9. Swift 6 strict concurrency

- `@MainActor` で UI / 共有状態 (`@Observable` モデル)
- `actor` でセンサー / I/O
- `nonisolated let provider` で provider プロパティを並行アクセス可能に
- データ受け渡しは `Sendable` 型で
- 並列タスクは `withThrowingTaskGroup(of:)`

## 10. メモリ・パフォーマンスの罠

- `MeshAnchor` / `PlaneAnchor` 自体を `[Anchor]` に蓄積しない (count や軽量フィールドだけ抽出)
- Hz 計測は **1 秒ローリング窓** (タイムスタンプ配列の先頭から 1 秒以上前を捨てる)

## 11. Vision Pro Enterprise API

```swift
import VisionEntitlementServices

let details = EnterpriseLicenseDetails.shared

// ステータス
switch details.licenseStatus {
case .valid:         ...
case .notFound:      ...   // Bundle ID / Team ID 不一致 / .license 欠落
case .invalidFormat: ...
case .expired:       ...
case .notAuthorized: ...   // entitlement キーが空 / 申請未承認
@unknown default:    ...   // 必須
}

// 期限 (non-optional Date — 未初期化時は 1970-01-01 epoch)
let expires: Date = details.expirationTimestamp

// 全 entitlement を列挙
for entitlement in EnterpriseLicenseDetails.EnterpriseEntitlement.allCases {
    let approved: Bool = details.isApproved(for: entitlement)
}
```

### 設定とハマりどころ

| 項目 | 内容 |
| :-- | :-- |
| `.license` ファイル登録 | XcodeGen `project.yml` の `sources` に `path: Enterprise.license, buildPhase: resources` |
| Enum はネスト型 | `EnterpriseLicenseDetails.EnterpriseEntitlement.allCases` (top-level ではない) |
| 空 `.entitlements` | `com.apple.enterprise.licensing` への XPC 接続が sandbox にブロック → `NSCocoaErrorDomain Code 4099` |
| 必要な entitlement キー | Apple 承認済みキーを最低 1 つ宣言 (例: `com.apple.developer.arkit.main-camera-access.allow`) |
| シミュレータ | **Enterprise API は全無効** — 実機必須 |
| 一致要件 | Bundle ID / Team ID が Apple 申請時と完全一致していないと `.notFound` |
| API 表記の差 | 公式ドキュメントに古い名前 (`Feature` / `expirationDate?` 等) が残っている。SDK の `.swiftinterface` を直読するのが確実 |

## 12. 回転・座標変換

- `simd_quatf` (クォータニオン) → Euler (yaw / pitch / roll) 変換は手動実装が必要 (visionOS 標準には無い)
- `simd_float4x4` の分解:
  - position: `transform.columns.3.xyz`
  - right axis: `transform.columns.0.xyz`
  - up axis: `transform.columns.1.xyz`
  - forward axis: `-transform.columns.2.xyz` (右手系の慣習)

## 13. デバッグ参考リンク

- [Apple Developer Documentation](https://developer.apple.com/documentation/visionos)
- WWDC23: Meet ARKit for spatial computing (session 10082)
- WWDC24: Create enhanced spatial computing experiences with ARKit (session 10100)
- WWDC24: Introducing enterprise APIs for visionOS (session 10139)
- 困ったら **`.swiftinterface` 直読** (`<Xcode>/Platforms/XROS.platform/Developer/SDKs/XROS.sdk/.../<Framework>.framework/Modules/<Framework>.swiftmodule/*.swiftinterface`)
