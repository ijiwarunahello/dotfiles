# RealityKit / UI / Input

`RealityView` の扱い、Entity ライフサイクル、ジェスチャ、Attachments、Reality Composer Pro 連携。

## RealityView の基本パターン

```swift
import SwiftUI
import RealityKit

struct HandView: View {
    @State var model = HandModel()

    var body: some View {
        RealityView { content in
            // make: 初期エンティティを「事前割り当て」
            let root = Entity()
            for _ in 0..<27 {
                let sphere = ModelEntity(
                    mesh: .generateSphere(radius: 0.006),
                    materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
                )
                root.addChild(sphere)
            }
            content.add(root)
            model.root = root
        } update: { content in
            // update: 毎フレーム transform だけ更新
            // ↑ 子 entity を毎フレーム作り直さない (GC 圧迫)
            for (i, joint) in model.joints.enumerated() {
                model.root.children[i].transform = Transform(matrix: joint)
            }
        }
        .upperLimbVisibility(.hidden)    // ← RealityView の閉じカッコの外!
        .allowsHitTesting(false)         //   中に書くとビルドエラー
    }
}
```

### Entity 事前割り当ての鉄則

- 毎フレーム `ModelEntity` を作ると GC で落ちる (数千 ops/sec)
- 必要数を `make` クロージャで用意 → `update` で `transform` だけ書き換える
- 動的に数が変わる場合は pool (プリアロケ済みリストから取り出し/戻す)

## システムジェスチャ制御

ハンドトラッキング中に OS の look+pinch UI を抑制したい:

```swift
RealityView { ... }
    .upperLimbVisibility(.hidden)   // システムの上肢描画を非表示
    .allowsHitTesting(false)        // look+pinch 入力自体を無効化
```

- `.upperLimbVisibility(_:)` 値: `.visible` / `.hidden` / `.automatic`
- 両モディファイアとも **`RealityView` 本体の外側**に書かないとビルドエラー

## Input — Gesture

### エンティティをタップ可能にする

**両方**のコンポーネントが必要。片方だけだと silent fail (エラーなしで反応しない)。

```swift
let cube = ModelEntity(mesh: .generateBox(size: 0.1))
cube.components.set(InputTargetComponent())                        // ← 必須 1
cube.components.set(CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])]))   // ← 必須 2
content.add(cube)
```

### SpatialTapGesture

```swift
RealityView { content in ... }
    .gesture(
        SpatialTapGesture()
            .targetedToAnyEntity()       // RealityView 全体にアタッチ
            .onEnded { value in
                let entity = value.entity
                let worldPos = value.convert(value.location3D, from: .local, to: .scene)
                // 何かする
            }
    )
```

- `.targetedToAnyEntity()` で RealityView 内の `InputTargetComponent` 持ちエンティティ全てが対象
- `.targetedToEntity(_:)` で特定エンティティに絞り込み

### DragGesture (3D)

```swift
.gesture(
    DragGesture()
        .targetedToAnyEntity()
        .onChanged { value in
            let start = value.convert(value.startLocation3D, from: .local, to: .scene)
            let now   = value.convert(value.location3D,      from: .local, to: .scene)
            value.entity.position = now - start + initial
        }
)
```

### RotateGesture3D

```swift
.gesture(
    RotateGesture3D()
        .targetedToAnyEntity()
        .onChanged { value in
            value.entity.transform.rotation = .init(value.rotation.quaternion)
        }
)
```

### HoverEffectComponent — 視線ホバー強調

```swift
cube.components.set(HoverEffectComponent(.highlight(.init(color: .systemBlue))))
// 他の Style: .spotlight / .lift
```

視線で見るだけで効果が発動する。**ジェスチャではない** (オプトインの視覚フィードバックのみ)。

## Attachments — SwiftUI を 3D 空間に置く

`RealityView` は 2-クロージャ形に拡張して SwiftUI ビューを attachment として埋め込める。

```swift
RealityView { content, attachments in
    // make
    if let label = attachments.entity(for: "info") {
        label.position = [0, 0.2, 0]
        content.add(label)
    }
} update: { content, attachments in
    // update — SwiftUI の state 変化は attachment が自動再描画
} attachments: {
    Attachment(id: "info") {
        VStack {
            Text("Score: \(score)")
            Button("Reset") { score = 0 }
        }
        .padding()
        .glassBackgroundEffect()
    }
}
```

- `Attachment(id:)` の id は **文字列** (重複しないこと)
- `attachments.entity(for: "info")` で `ViewAttachmentEntity` を取得 → **`content.add()` するのを忘れない** (忘れると表示されない)
- SwiftUI の `@State` は attachments クロージャ内で参照できる。更新は自動反映
- attachment 内のボタン/入力は通常の pinch で操作可能 (衝突コンポ不要)

## Reality Composer Pro 連携

Xcode 統合の 3D コンポーザー。`.usda` シーンを Swift Package bundle 経由で読み込む。

```swift
import RealityKit
import RealityKitContent   // Xcode が自動生成する bundle

let scene = try await Entity(named: "MyScene", in: realityKitContentBundle)
content.add(scene)

// 特定の Entity を取り出す
if let handle = scene.findEntity(named: "Handle") {
    handle.components.set(InputTargetComponent())
}
```

### ShaderGraph マテリアルに値を流す

Reality Composer Pro で作った `ShaderGraphMaterial` は Swift から parameter を書き換えられる。

```swift
var material = try await ShaderGraphMaterial(
    named: "/Root/Materials/MyMat",
    from: "MyScene",
    in: realityKitContentBundle
)
try material.setParameter(name: "hue",       value: .float(0.5))
try material.setParameter(name: "tintColor", value: .color(.red))

entity.components[ModelComponent.self]?.materials = [material]
```

- parameter 名は Reality Composer Pro の Inspector で "Promoted Parameters" として公開したもの
- 型ミスマッチは runtime error — `.swiftinterface` で `MaterialParameters.Value` の enum を確認

## よく使う Component まとめ

| Component | 用途 |
| :-- | :-- |
| `ModelComponent` | メッシュ + マテリアル |
| `CollisionComponent` | 当たり判定 (ジェスチャにも必須) |
| `InputTargetComponent` | タップ/ドラッグ対象マーク |
| `HoverEffectComponent` | 視線ホバー強調 |
| `PhysicsBodyComponent` | 物理シミュレーション |
| `AnchoringComponent` | AR anchor 追従 |
| `AudioLibraryComponent` | 音源アタッチ |
| `Transform` (組み込み) | 位置/回転/スケール |
