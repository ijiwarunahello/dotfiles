# ARKit / センサー

`ARKitSession` と各データプロバイダの扱い方。Swift 6 strict concurrency 前提。

## ARKitSession の基本パターン

公式パターン。実プロジェクト (SensorScope) で実証済み。

```swift
import ARKit

actor SensorManager {
    private let session = ARKitSession()
    private let worldSensor = WorldTrackingSensor()
    private let handSensor  = HandTrackingSensor()

    func start() async throws {
        // (1) 認可を一括要求
        let statuses = await session.requestAuthorization(
            for: [.worldSensing, .handTracking]
        )
        for (type, status) in statuses where status != .allowed {
            throw SensorError.authorizationDenied("\(type)")
        }

        // (2) 全プロバイダを 1 回の run() にまとめる
        var providers: [any DataProvider] = []
        if WorldTrackingProvider.isSupported { providers.append(worldSensor.provider) }
        if HandTrackingProvider.isSupported  { providers.append(handSensor.provider) }
        try await session.run(providers)

        // (3) anchorUpdates を並列処理
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.worldSensor.process() }
            group.addTask { try await self.handSensor.process() }
            try await group.waitForAll()
        }
    }

    func stop() {
        session.stop()   // 明示停止 (cancel 任せにしない)
    }
}
```

## 守るべき 5 つのルール

1. **`ARKitSession` を強参照で保持** — release されると provider も死ぬ
2. **`session.run()` は 1 回だけ** — `[any DataProvider]` に全 provider を入れて渡す (2 回呼ぶと壊れる)
3. 各 provider の **static `isSupported` を必ず確認** — Mac / Sim / 未対応デバイスで false
4. 終了時は **明示的に `session.stop()`** — task cancel 任せにしない
5. センサーごとに `actor` 化、`nonisolated let provider` で provider 自体への並行アクセスを許可

## 4 つのプロバイダ

### WorldTrackingProvider — 頭部姿勢

```swift
let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(
    atTimestamp: CACurrentMediaTime()
)
let transform: simd_float4x4 = deviceAnchor?.originFromAnchorTransform ?? .init()
// → 頭部の 4×4 ワールド変換行列 (位置 + 回転)
```

- `anchorUpdates` ではなく **`queryDeviceAnchor(atTimestamp:)` でポーリング**するのが基本
- `WorldAnchor` の永続化もこの provider で扱う (`immersive-space.md` 参照)

### HandTrackingProvider — 27 関節

```swift
let (left, right) = handTrackingProvider.latestAnchors

for hand in [left, right] {
    guard let hand,
          let joint = hand.handSkeleton?.joint(.thumbTip) else { continue }
    // 関節のワールド座標 = handAnchor × jointLocal
    let world = hand.originFromAnchorTransform * joint.anchorFromJointTransform
}

// 全関節を網羅したい場合
for jointName in HandSkeleton.JointName.allCases {
    // 27 関節: wrist, forearmWrist, forearmArm, 5 指 × 5 関節 (mcp/pip/dip/tip + knuckle)
}
```

- `handAnchor.chirality` が `.left` / `.right`
- すべての関節は `.wrist` を root とする階層
- `HandSkeleton.JointName.allCases` が 27 要素 — enum なので forEach で網羅可

### PlaneDetectionProvider — 平面検出

```swift
let provider = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
for await update in provider.anchorUpdates {
    switch update.event {
    case .added, .updated:   /* update.anchor: PlaneAnchor */
    case .removed:           /* 削除 */
    }
}
```

- `PlaneAnchor.classification` で床/壁/天井/机などを判別
- `PlaneAnchor.geometry.meshVertices` で実際の形状

### SceneReconstructionProvider — 空間メッシュ

```swift
let provider = SceneReconstructionProvider(modes: [.classification])
for await update in provider.anchorUpdates {
    let mesh: MeshAnchor = update.anchor
    // mesh.geometry.meshFaces / .meshVertices / .meshClassifications
}
```

## メモリ・パフォーマンスの罠

- **`MeshAnchor` / `PlaneAnchor` 自体を配列に蓄積しない** — 各 anchor は数 MB、メモリ上限無く増え続けて OOM。必要な情報 (count、軽量フィールド) だけ抽出して離す
- **毎フレーム全 anchor を走査しない** — `.added` / `.updated` / `.removed` の差分で状態を更新し続ける
- **Hz 計測は 1 秒ローリング窓** でやる:

```swift
actor HzCounter {
    private var timestamps: [CFAbsoluteTime] = []
    func tick() -> Double {
        let now = CFAbsoluteTimeGetCurrent()
        timestamps.append(now)
        timestamps.removeAll { $0 < now - 1.0 }
        return Double(timestamps.count)
    }
}
```

## Swift 6 strict concurrency

- `@MainActor`: UI / `@Observable` モデル / SwiftUI View 内の共有状態
- `actor`: センサーマネージャ / I/O / バッファ
- `nonisolated let provider`: `ARKitSession` から参照される provider プロパティ — `actor` の外からも参照されるので isolate しない
- `Sendable`: actor 境界を越えるデータはすべて `Sendable` 準拠
- 並列: `withThrowingTaskGroup(of:)` で provider ごとに `group.addTask`

```swift
actor HandSensor {
    let provider = HandTrackingProvider()   // ❌ var だと Sendable 警告
    // ↓ 正解
    nonisolated let provider = HandTrackingProvider()
}
```

## 座標変換

`visionOS` は右手系。`simd_float4x4` と `simd_quatf` を行き来する。

```swift
// simd_float4x4 の分解
let position = transform.columns.3.xyz                    // 位置
let right    = transform.columns.0.xyz                    // 右軸
let up       = transform.columns.1.xyz                    // 上軸
let forward  = -transform.columns.2.xyz                   // 前方軸 (右手系慣習で反転)

// simd_quatf → Euler (yaw/pitch/roll) は標準 API に無い → 自前実装
extension simd_quatf {
    var eulerYXZ: SIMD3<Float> {
        let q = self.vector
        let yaw   = atan2(2*(q.w*q.y + q.x*q.z), 1 - 2*(q.y*q.y + q.x*q.x))
        let pitch = asin(max(-1, min(1, 2*(q.w*q.x - q.z*q.y))))
        let roll  = atan2(2*(q.w*q.z + q.y*q.x), 1 - 2*(q.x*q.x + q.z*q.z))
        return SIMD3(pitch, yaw, roll)
    }
}

// simd_float4 → SIMD3 のショートカット
extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> { SIMD3(x, y, z) }
}
```
