# Vision Pro Enterprise API

Apple から事業者向けに発行される `.license` と entitlement を使う API 群。Main Camera Access / Object Tracking Parameter Adjustment などが該当。**実機必須、Sim 不可**。

## EnterpriseLicenseDetails の使い方

```swift
import VisionEntitlementServices

let details = EnterpriseLicenseDetails.shared

// ステータス
switch details.licenseStatus {
case .valid:         /* OK */
case .notFound:      /* Bundle ID / Team ID 不一致 or .license ファイル欠落 */
case .invalidFormat: /* ファイル破損 */
case .expired:       /* 期限切れ */
case .notAuthorized: /* entitlement キー空 or Apple 未承認 */
@unknown default:    /* Swift 6 必須 */
}

// 期限 (non-optional Date — 未初期化時は 1970-01-01 epoch)
let expires: Date = details.expirationTimestamp

// 全 entitlement を列挙
for entitlement in EnterpriseLicenseDetails.EnterpriseEntitlement.allCases {
    let approved: Bool = details.isApproved(for: entitlement)
}
```

### 罠

- **enum は top-level ではなくネスト型**: `EnterpriseLicenseDetails.EnterpriseEntitlement.allCases`
- **API 表記は公式ドキュメントが古いことがある** — SDK の `.swiftinterface` を直読するのが確実
- `expirationTimestamp` は **non-optional** — 未設定時は epoch を返す。期限判定は `details.expirationTimestamp > Date()` と書く

## XPC Code 4099 デバッグレシピ

`NSCocoaErrorDomain Code 4099` (`com.apple.enterprise.licensing` への XPC 接続失敗) の切り分け手順。

### Step 1. entitlement キーが宣言されているか

Xcode > Signing & Capabilities で **Apple 承認済みキー**が最低 1 つ入っているか確認:

```
com.apple.developer.arkit.main-camera-access.allow
com.apple.developer.arkit.object-tracking-parameter-adjustment.allow
com.apple.developer.arkit.world-sensing.allow
(その他 Apple から通知された Team 専用キー)
```

### Step 2. `.entitlements` ファイルがプロジェクトに紐付いているか

```bash
xcodebuild -showBuildSettings -scheme MyApp | grep CODE_SIGN_ENTITLEMENTS
```

空文字なら `project.yml` に以下を追加:

```yaml
targets:
  MyApp:
    entitlements:
      path: MyApp/MyApp.entitlements
      properties:
        com.apple.developer.arkit.main-camera-access.allow: true
```

### Step 3. ビルド後の .app に entitlement が埋め込まれているか

```bash
codesign -d --entitlements :- /path/to/MyApp.app
# → <plist> の中に宣言したキーが並ぶこと
```

空 dict or 該当キー不在なら Step 2 に戻る。

### Step 4. `.license` が Bundle に同梱されているか

```yaml
targets:
  MyApp:
    sources:
      - path: Enterprise.license
        buildPhase: resources    # ← 必須
```

ビルド後:

```bash
ls /path/to/MyApp.app/Enterprise.license   # 存在を確認
```

### Step 5. Bundle ID / Team ID の完全一致

`.license` ファイルの中身 (plist または JSON 互換) を開き:

- `bundle-id` がターゲットの CFBundleIdentifier と**大文字小文字含め完全一致**
- `team-id` が Xcode の Signing > Team と一致

一方でも違うと `.notFound` 返却。

### Step 6. Apple 申請済み entitlement が Team に紐付いているか

App Store Connect > Certificates, Identifiers & Profiles > Identifiers > App ID > 該当キーがチェックされているか。承認前だと空 entitlement 扱い → `.notAuthorized`。

### Step 7. 実機で動いているか

**Enterprise API は Simulator で全無効**。`licenseStatus` が常に `.notFound` を返す。実機にインストールして `EnterpriseLicenseDetails.shared.licenseStatus` を確認。

### Step 8. Console.app で XPC ログ確認

Console.app でデバイスを選択 → フィルタ `subsystem:com.apple.VisionEntitlementServices` で詳細ログ。sandbox 拒否の行があれば Step 1-3 に戻る。

## ステータス別の第一手

| licenseStatus | 最初に疑う場所 |
| :-- | :-- |
| `.valid` | OK |
| `.notFound` | `.license` 同梱 (Step 4) / Bundle ID 一致 (Step 5) |
| `.invalidFormat` | `.license` ファイル破損 — Apple に再発行依頼 |
| `.expired` | `expirationTimestamp` 確認 → Apple 再発行 |
| `.notAuthorized` | entitlement キー宣言 (Step 1-3) / Apple 承認 (Step 6) |

## 代表的な Enterprise entitlement

Apple から通知されるキー。有効化には申請と承認が必要:

- `com.apple.developer.arkit.main-camera-access.allow` — Main Camera への直接アクセス
- `com.apple.developer.arkit.object-tracking-parameter-adjustment.allow` — ObjectTracking のパラメータ調整
- `com.apple.developer.arkit.world-sensing.allow` — Enhanced world sensing
- (その他 Team 専用キー)

承認済みキー一覧は Apple からの連絡メール or App Store Connect で確認。

## `.swiftinterface` 直読

公式ドキュメントが古い場合、SDK の `.swiftinterface` が最も確実:

```
/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS.sdk/System/Library/Frameworks/VisionEntitlementServices.framework/Modules/VisionEntitlementServices.swiftmodule/arm64-apple-xros.swiftinterface
```

grep で API 定義を直接確認できる。

## Info.plist の使用目的文字列

Enterprise API 用途では専用のキーが必要:

| キー | 用途 |
| :-- | :-- |
| `NSMainCameraUsageDescription` | Main Camera Access |
| `NSWorldSensingUsageDescription` | Enhanced World Sensing |

権限文字列忘れは**無言でデータが来ない**ので、Step 1 と並行して必ず確認。
