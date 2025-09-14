# watchOS 実装詳細

Apple Watch 側の実装について詳しく解説します。SwiftUI を使った簡潔な UI と、WatchConnectivity による iPhone 連携を実装しています。

## 📁 ファイル構成

```
ios/FlutterWatch Watch App/
├── FlutterWatchApp.swift          # アプリエントリーポイント
├── ContentView.swift              # メインUI
├── WatchSessionManager.swift      # WatchConnectivity管理
└── Assets.xcassets/              # アセット管理
    ├── AccentColor.colorset/
    ├── AppIcon.appiconset/
    └── Contents.json
```

## 🎯 主要コンポーネント

### 1. アプリエントリーポイント (`FlutterWatchApp.swift`)

```swift
import SwiftUI
import WatchConnectivity
import Combine

@main
struct FlutterWatch_Watch_AppApp: App {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}
```

**ポイント:**

- `@StateObject`で WatchSessionManager のライフサイクル管理
- `@EnvironmentObject`でアプリ全体に状態を共有
- SwiftUI の`App`プロトコルを使用

### 2. メイン UI (`ContentView.swift`)

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    var body: some View {
        VStack(spacing: 15) {
            Text("Watch")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(sessionManager.counter)")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.blue)

            HStack(spacing: 20) {
                Button {
                    sessionManager.decrementCounter()
                } label: {
                    Image(systemName: "minus")
                }
                .foregroundColor(.white)
                .frame(width: 35, height: 35)
                .background(Color.red)
                .cornerRadius(17.5)

                Button {
                    sessionManager.incrementCounter()
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundColor(.white)
                .frame(width: 35, height: 35)
                .background(Color.blue)
                .cornerRadius(17.5)
            }

            HStack {
                Circle()
                    .fill(sessionManager.isConnected ? Color.green : Color.red)
                    .frame(width: 6, height: 6)

                Text(sessionManager.isConnected ? "接続完了" : "未接続")
                    .font(.caption2)
                    .foregroundColor(sessionManager.isConnected ? .green : .red)
            }
        }
        .padding()
        .onAppear {
            sessionManager.startSession()
        }
    }
}
```

**UI 構成:**

1. **タイトル**: "Watch" 表示
2. **カウンター表示**: 大きなフォントで現在値表示
3. **操作ボタン**: +/- ボタンでカウンター操作
4. **接続状態**: リアルタイムの接続ステータス表示

### 3. WatchSessionManager (`WatchSessionManager.swift`)

Apple Watch 側の WatchConnectivity 管理を行うクラスです。

```swift
import Foundation
import SwiftUI
import WatchConnectivity
import Combine

final class WatchSessionManager: NSObject, ObservableObject {
    @Published var counter: Int = 0
    @Published var isConnected: Bool = false

    private var wcSession: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
        }
    }
}
```

**ポイント:**

- `ObservableObject`で SwiftUI との連携
- `@Published`プロパティで自動的な UI 更新
- `final class`でパフォーマンス最適化

## 🔄 セッション管理

### 1. セッション開始

```swift
func startSession() {
    wcSession?.activate()

    // セッション状態を定期的にチェック
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.checkSessionState()
    }
}

private func checkSessionState() {
    guard let session = wcSession else {
        return
    }

    DispatchQueue.main.async {
        self.isConnected = session.isReachable
    }
}
```

**処理フロー:**

1. WCSession のアクティベート
2. 1 秒後に接続状態をチェック
3. UI 状態の更新

### 2. カウンター操作

```swift
func incrementCounter() {
    let newValue = counter + 1
    updateCounter(newValue)
}

func decrementCounter() {
    let newValue = counter - 1
    updateCounter(newValue)
}

private func updateCounter(_ newValue: Int) {
    counter = newValue
    sendCounterToiPhone(newValue)
}
```

**処理の流れ:**

1. ローカルカウンターの更新（即座の UI 反映）
2. iPhone への値送信

### 3. iPhone への送信

```swift
private func sendCounterToiPhone(_ value: Int) {
    guard let session = wcSession else {
        return
    }

    guard session.isReachable else {
        print("⌚️ iPhone not reachable")
        return
    }

    let message = ["counter": value]
    print("⌚️ Watch → iPhone: \(value)")
    session.sendMessage(message, replyHandler: { _ in
        // 成功
    }, errorHandler: { error in
        print("⌚️ Send error: \(error.localizedDescription)")
    })
}
```

**送信プロセス:**

1. セッションの有効性確認
2. iPhone の到達可能性確認
3. メッセージ送信
4. 成功/失敗のハンドリング

## 🎭 WCSessionDelegate 実装

### 1. セッション状態変更

```swift
extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }
}
```

**監視項目:**

- セッション有効化完了
- 到達可能性の変化
- メインスレッドでの UI 更新

### 2. メッセージ受信処理

```swift
func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    DispatchQueue.main.async {
        if let counterValue = message["counter"] as? Int {
            self.counter = counterValue
        }
    }
}

func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    DispatchQueue.main.async {
        if let counterValue = message["counter"] as? Int {
            print("⌚️ iPhone → Watch: \(counterValue)")
            self.counter = counterValue
        }

        // 応答を送信
        let reply = ["status": "received"] as [String : Any]
        replyHandler(reply)
    }
}
```

**受信処理:**

1. iPhone からのカウンター値受信
2. ローカル状態の更新
3. 応答メッセージの送信（必要な場合）

## 🎨 SwiftUI 設計パターン

### 1. Environment Objects

```swift
// App.swift
.environmentObject(sessionManager)

// ContentView.swift
@EnvironmentObject var sessionManager: WatchSessionManager
```

**メリット:**

- アプリ全体での状態共有
- 階層を跨いだデータアクセス
- 自動的な依存性注入

### 2. Published Properties

```swift
@Published var counter: Int = 0
@Published var isConnected: Bool = false
```

**自動更新:**

- プロパティ変更時に View が自動で再描画
- パフォーマンス最適化された更新
- データバインディングの簡素化

### 3. Reactive UI

```swift
Text("\(sessionManager.counter)")
    .font(.system(size: 50, weight: .bold))
    .foregroundColor(.blue)

Circle()
    .fill(sessionManager.isConnected ? Color.green : Color.red)
    .frame(width: 6, height: 6)
```

**リアクティブ更新:**

- 状態変化に応じた自動 UI 更新
- 条件分岐による動的スタイリング
- 宣言的な UI 記述

## ⌚ Apple Watch 特有の考慮点

### 1. 小さな画面サイズ

```swift
VStack(spacing: 15) {
    // コンパクトなレイアウト
    Text("Watch")
        .font(.title2)  // 適切なフォントサイズ

    Text("\(sessionManager.counter)")
        .font(.system(size: 50, weight: .bold))  // 大きく見やすい数字
}
```

### 2. タッチ操作の最適化

```swift
Button {
    sessionManager.incrementCounter()
} label: {
    Image(systemName: "plus")
}
.frame(width: 35, height: 35)  // 十分なタッチエリア
.background(Color.blue)
.cornerRadius(17.5)
```

### 3. バッテリー効率

```swift
// 必要な時のみ通信
guard session.isReachable else {
    print("⌚️ iPhone not reachable")
    return
}

// 最小限のデータ送信
let message = ["counter": value]
```

## 🔋 パフォーマンス最適化

### 1. メモリ効率

```swift
// weak selfでメモリリーク防止
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    [weak self] in
    self?.checkSessionState()
}
```

### 2. UI 更新の最適化

```swift
DispatchQueue.main.async {
    // メインスレッドでUI更新
    self.counter = counterValue
}
```

### 3. 通信効率

```swift
// 到達可能性の事前確認
guard session.isReachable else {
    return
}

// 簡潔なメッセージ形式
let message = ["counter": value]
```

## 🧪 デバッグとログ

### 1. 通信ログ

```swift
print("⌚️ Watch → iPhone: \(value)")
print("⌚️ iPhone → Watch: \(counterValue)")
print("⌚️ Send error: \(error.localizedDescription)")
```

### 2. 状態確認

```swift
private func checkSessionState() {
    guard let session = wcSession else {
        print("⌚️ Session is nil")
        return
    }

    print("⌚️ Session state:")
    print("⌚️ - isReachable: \(session.isReachable)")
    print("⌚️ - activationState: \(session.activationState.rawValue)")
}
```

### 3. エラーハンドリング

```swift
session.sendMessage(message, replyHandler: { response in
    print("⌚️ Message sent successfully")
}, errorHandler: { error in
    print("⌚️ Send error: \(error.localizedDescription)")
})
```

## 🏗️ アーキテクチャパターン

### MVVM with ObservableObject

```
┌─────────────────┐
│      View       │ ← SwiftUI Views
│   (ContentView) │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   ViewModel     │ ← WatchSessionManager
│ (ObservableObject)│
└─────────────────┘
         │
         ▼
┌─────────────────┐
│     Model       │ ← WCSession, Counter Data
│  (WatchConnectivity)│
└─────────────────┘
```

**責任分離:**

- **View**: UI 表示とユーザー操作
- **ViewModel**: ビジネスロジックと状態管理
- **Model**: データ通信と永続化

## ⚠️ 注意点とベストプラクティス

### 1. セッション管理

```swift
// 必ずサポート状況を確認
if WCSession.isSupported() {
    wcSession = WCSession.default
    wcSession?.delegate = self
}
```

### 2. スレッド安全性

```swift
// UI更新は必ずメインスレッド
DispatchQueue.main.async {
    self.counter = counterValue
}
```

### 3. エラー処理

```swift
// 接続状態の事前確認
guard session.isReachable else {
    // 適切なフォールバック処理
    return
}
```

### 4. リソース管理

```swift
// 適切なライフサイクル管理
override init() {
    super.init()
    setupWatchConnectivity()
}
```

## 📱 UI/UX 考慮点

### 1. 視認性の確保

- 大きなフォントサイズの使用
- 高コントラストな色使い
- 十分なスペーシング

### 2. 操作性の向上

- 十分なタッチエリア確保
- 直感的なアイコン使用
- 即座のフィードバック表示

### 3. Apple Watch 体験の最適化

- 素早いアクセス
- 最小限のタップ数
- 明確な状態表示
