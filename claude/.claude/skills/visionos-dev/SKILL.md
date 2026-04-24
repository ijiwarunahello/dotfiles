---
name: visionos-dev
description: Use when developing visionOS apps for Apple Vision Pro (Swift/SwiftUI, ARKit, RealityKit, hand/world/plane/scene tracking, RealityView, Reality Composer Pro, attachments, gestures, HoverEffectComponent, ImmersiveSpace lifecycle, WorldAnchor persistence, Enterprise APIs/entitlements, XcodeGen, xcrun devicectl, Instruments). Covers Swift 6 strict concurrency for ARKit (single ARKitSession.run([providers]) pattern), DeviceAnchor.originFromAnchorTransform, HandSkeleton 27 joints, CollisionComponent+InputTargetComponent pairing for entity taps, RealityView attachments 2-closure form, openImmersiveSpace/dismissImmersiveSpace + scenePhase, WorldTrackingProvider.addAnchor persistence, Enterprise license debugging (XPC sandbox Code 4099 step-by-step recipe, EnterpriseLicenseDetails.shared, EnterpriseEntitlement allCases), Full Space requirement, simulator-vs-device capability matrix, and xcodebuild quirks (DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer).
---

# visionOS 開発ガイド

Apple Vision Pro / visionOS アプリ開発のお作法と踏みやすい罠をまとめたもの。対象: Swift / SwiftUI / ARKit / RealityKit / Vision Pro Enterprise API。

このファイルは索引。詳細は `references/*.md` を参照する。

## 0. Quick lookup — 症状 → 原因候補

| 症状 | 原因候補 | 参照 |
| :-- | :-- | :-- |
| `anchorUpdates` が一切届かない | Full Space でない / 権限文言未記載 / `isSupported` false / `session.run()` 未呼出 | arkit-sensors |
| `session.run()` を 2 回呼んだ後クラッシュ | 全 provider は **1 回の** `run([providers])` にまとめる | arkit-sensors |
| Entity をタップしても反応しない | `CollisionComponent` と `InputTargetComponent` **両方**が必要 | realitykit-ui |
| `.upperLimbVisibility(.hidden)` がビルドエラー | `RealityView { ... }` の**閉じカッコの外**に置く | realitykit-ui |
| Attachment が画面に出ない | `attachments.entity(for: id)` を `content.add()` し忘れ | realitykit-ui |
| バックグラウンドから復帰後にトラッキング止まる | ARKitSession は OS に停止される → scenePhase `.active` で `run()` 再呼出 | immersive-space |
| ImmersiveSpace を閉じても再度開けない | `@State` 同期ミス + `.onChange` で dismiss 反映 | immersive-space |
| `EnterpriseLicenseDetails` が常に `.notFound` | Bundle ID/Team ID 不一致 or `.license` が bundle に入っていない | enterprise |
| `NSCocoaErrorDomain Code 4099` (XPC) | entitlement キー宣言忘れ / `.entitlements` が project に紐付いてない | enterprise |
| シミュレータで ARKit 全部 false | 仕様 — ARKit provider は**実機必須** | build-and-test |
| `xcodebuild` が sudo を要求 | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` を指定 | build-and-test |
| ROS 2 との Python 連携で pytest が ament プラグイン読み込み | `PYTHONPATH=""` で `uv run` (iri-dotfiles の `uv` wrapper が自動で) | (参考) |

## 1. 動作環境

- **visionOS**: 26.0+
- **Swift**: 6.0 (strict concurrency 前提)
- **Xcode**: 26.0 (Command Line Tools だけでは不足)
- **XcodeGen**: `project.yml` から `.xcodeproj` を生成 — 本ガイドの全プロジェクトで前提
- **uv**: Python 連携 (avp-stream など) のパッケージ管理

## 2. シーン構成

| SwiftUI Scene | 用途 | ARKit provider |
| :-- | :-- | :-- |
| `WindowGroup` | 2D ウィンドウ | ✗ anchor 来ない |
| `Volume` (`.windowStyle(.volumetric)`) | 3D ウィンドウ | ✗ anchor 来ない |
| `ImmersiveSpace` | Full Space / 空間没入 | ✓ 動く |

**鉄則**: ARKit のデータプロバイダ (HandTracking / WorldTracking / PlaneDetection / SceneReconstruction) は **ImmersiveSpace (Full Space) でしか動かない**。Shared Space (WindowGroup / Volume) では認可が通っても anchor が 1 つも来ない。

`Info.plist` の `UIApplicationSceneManifest` で複数シーン宣言。詳細は `immersive-space.md`。

## 3. Info.plist プライバシーキー

| キー | 用途 |
| :-- | :-- |
| `NSWorldSensingUsageDescription` | World / Plane / Scene Reconstruction 共通 |
| `NSHandsTrackingUsageDescription` | HandTracking |
| `NSPhotoLibraryUsageDescription` | 写真ライブラリ |
| `NSMainCameraUsageDescription` | Enterprise 限定: メインカメラアクセス |

権限キーを忘れると**エラーは出ずデータも来ない**ので発見が遅れる。Plist と `requestAuthorization` の**両方**が必須。

## 4. 詳細 references

- **`references/arkit-sensors.md`** — `ARKitSession` 設計、4 プロバイダ (World/Hand/Plane/Scene)、Swift 6 strict concurrency、メモリ・Hz 計測、座標変換
- **`references/realitykit-ui.md`** — `RealityView` の make/update パターン、Entity 事前割り当て、システムジェスチャ制御、Input/Gesture、Attachments 2-クロージャ、Reality Composer Pro 連携
- **`references/immersive-space.md`** — `openImmersiveSpace`/`dismissImmersiveSpace`、`scenePhase` による session 停止/再開、`WorldAnchor` 永続化
- **`references/enterprise.md`** — `EnterpriseLicenseDetails`、entitlement 設定、**XPC Code 4099 step-by-step デバッグレシピ**
- **`references/build-and-test.md`** — `xcodegen` / `xcodebuild` / 署名切り分け、**Sim vs 実機 対応表**、`xcrun devicectl`、Instruments (visionOS)、ユニットテスト戦略

## 5. 公式リファレンス

- [Apple Developer Documentation — visionOS](https://developer.apple.com/documentation/visionos)
- WWDC23: Meet ARKit for spatial computing (session 10082)
- WWDC24: Create enhanced spatial computing experiences with ARKit (session 10100)
- WWDC24: Introducing enterprise APIs for visionOS (session 10139)
- 困ったら **`.swiftinterface` 直読**: `<Xcode>/Platforms/XROS.platform/Developer/SDKs/XROS.sdk/.../<Framework>.framework/Modules/<Framework>.swiftmodule/*.swiftinterface`
