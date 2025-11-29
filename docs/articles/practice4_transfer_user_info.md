## transferUserInfo とは
`transferUserInfo`は、WatchConnectivity フレームワークが提供するメソッドの一つで、重要データを確実に転送します。このメソッドの最大の特徴は、すべてのメッセージがキューに保持され、送信順序が保証されることです。オフライン時でもキューに追加され、接続が回復したら自動的に配信されます。

## transferUserInfo の特徴
`transferUserInfo`には以下のような特徴があります。
- すべてのメッセージがキューに保持される
  - `updateApplicationContext`と異なり、最新値だけでなく、すべてのメッセージが順番に配信される
- 送信順序が保証される
  - 送信した順番通りに受信側で処理される
- オフライン時も動作
  - オフライン時でもキューに追加され、接続回復後に自動的に配信される
- 到達可能性のチェック不要
  - `sendMessage`とは異なり、`isReachable`のチェックが不要
- キュー状態の管理
  - `outstandingUserInfoTransfers`でキューに残っているメッセージ数を確認できる

`transferUserInfo`は、すべてのメッセージを確実に配信したい場合に適しています。例えば、メッセージアプリで送信したメッセージをすべて確実に配信したい場合に使用します。

一方で、即座の応答が必要な操作には`sendMessage`、最新値だけが重要な設定の同期には`updateApplicationContext`を検討する必要があるかと思います。

## 使ってみる
次は実際に`transferUserInfo`を使って iOS と watchOS のメッセージデータのやり取りを行い、さらにそれを Flutter 側にも反映させる実装を行います。
今回の実装では、メッセージアプリを題材として扱います。

最終的には以下のように、iPhone と Apple Watch でそれぞれのメッセージを送受信し、表示内容が同期するような実装を行います。
実装は以下の手順で進めていきます。
1. iOS と watchOS 間のデータのやり取り
2. iOS と Flutter 間のデータのやり取り

## iOS と watchOS 間のデータのやり取り
### 前提
iOS と watchOS 間の通信の実装に際して、前提を確認しておきます。
iOS と watchOS の通信は全体の中では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/95bc2cfe74d7-20251129.png)

両 OS では、以下の二つを定義することで双方向の通信ができるようになります。
- 相手側にメッセージを送る処理（transferUserInfo）
- 相手側からメッセージが届いた時に実行する処理（didReceiveUserInfo）
![](https://storage.googleapis.com/zenn-user-upload/ca095a65d542-20251129.png)

### watch 側の実装
watchOS で実現したい挙動は以下の通りです。
- watchOS で受け付けたメッセージを送信し、送信済みメッセージとして保存する
- iOS から送信されてきたメッセージを watchOS に反映する

#### iOS との連絡部分
まずは iOS との連絡部分を実装していきます。
コードは以下の通りです。以下で詳しくみていきます。
```swift: ios/FlutterWatch Watch App/WatchSessionManager.swift
import Foundation
import WatchConnectivity
import Combine

struct WatchMessage: Identifiable, Codable {
    let id: String
    let text: String
    let sender: String
    let timestamp: Double
    var isRead: Bool

    var date: Date {
        Date(timeIntervalSince1970: timestamp)
    }
}

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    private let session = WCSession.default
    private let defaults = UserDefaults.standard
    private let sentMessagesKey = "sent_messages"
    private let receivedMessagesKey = "received_messages"
    private let receivedMessageIdsKey = "received_message_ids"

    @Published var sentMessages: [WatchMessage] = []
    @Published var receivedMessages: [WatchMessage] = []
    @Published var isReachable: Bool = false
    @Published var outstandingCount: Int = 0

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        loadMessages()

        session.delegate = self
        session.activate()
    }

    func sendMessage(text: String) {
        let message = WatchMessage(
            id: UUID().uuidString,
            text: text,
            sender: "Watch",
            timestamp: Date().timeIntervalSince1970,
            isRead: false
        )

        sentMessages.append(message)
        saveSentMessages()
        let userInfo: [String: Any] = [
            "type": "message",
            "id": message.id,
            "text": message.text,
            "sender": message.sender,
            "timestamp": message.timestamp,
            "isRead": message.isRead
        ]

        session.transferUserInfo(userInfo)
        updateQueueStatus()
    }

    func markAsRead(messageId: String) {
        if let index = receivedMessages.firstIndex(where: { $0.id == messageId }) {
            receivedMessages[index].isRead = true
            saveReceivedMessages()
        }
    }

    func getUnreadCount() -> Int {
        return receivedMessages.filter { !$0.isRead }.count
    }

    private func saveSentMessages() {
        if let encoded = try? JSONEncoder().encode(sentMessages) {
            defaults.set(encoded, forKey: sentMessagesKey)
        }
    }

    private func saveReceivedMessages() {
        if let encoded = try? JSONEncoder().encode(receivedMessages) {
            defaults.set(encoded, forKey: receivedMessagesKey)
        }
    }

    private func loadMessages() {
        if let data = defaults.data(forKey: sentMessagesKey),
           let messages = try? JSONDecoder().decode([WatchMessage].self, from: data) {
            sentMessages = messages
        }

        if let data = defaults.data(forKey: receivedMessagesKey),
           let messages = try? JSONDecoder().decode([WatchMessage].self, from: data) {
            receivedMessages = messages
        }
    }

    private func updateQueueStatus() {
        DispatchQueue.main.async {
            self.outstandingCount = self.session.outstandingUserInfoTransfers.count
        }
    }

    private func getReceivedMessageIds() -> Set<String> {
        guard let array = defaults.array(forKey: receivedMessageIdsKey) as? [String] else {
            return Set()
        }
        return Set(array)
    }

    private func addReceivedMessageId(_ id: String) {
        var ids = getReceivedMessageIds()
        ids.insert(id)
        defaults.set(Array(ids), forKey: receivedMessageIdsKey)
    }
}
```

以下では、`WatchSessionManager`を`ObservableObject`に準拠させています。これで外部からは`StateObject`や`EnvironmentObject`として扱うことができます。
`sentMessages`では送信済みメッセージのリストを保持しています。
`receivedMessages`では受信済みメッセージのリストを保持しています。
`isReachable`では、iPhone と接続されているかどうかを保持しています。
`outstandingCount`では、キューに残っているメッセージ数を保持しています。
```swift
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    private let session = WCSession.default
    private let defaults = UserDefaults.standard
    private let sentMessagesKey = "sent_messages"
    private let receivedMessagesKey = "received_messages"
    private let receivedMessageIdsKey = "received_message_ids"

    @Published var sentMessages: [WatchMessage] = []
    @Published var receivedMessages: [WatchMessage] = []
    @Published var isReachable: Bool = false
    @Published var outstandingCount: Int = 0
```

以下では、`WatchSessionManager`の初期化処理を記述しています。
初期化処理では、WCSession がサポートされているかどうかを確認しています。
この辺りは他のメソッドと同様かと思います。
また、`loadMessages()`で保存されているメッセージを読み込んでいます。
```swift
private override init() {
    super.init()

    guard WCSession.isSupported() else {
        return
    }

    loadMessages()

    session.delegate = self
    session.activate()
}
```

以下では、メッセージを送信する処理を記述しています。
`transferUserInfo`メソッドでメッセージを iOS へ送信しています。
すべてのメッセージがキューに保持され、順番に配信されます。
送信後、`updateQueueStatus()`でキュー状態を更新しています。
```swift
func sendMessage(text: String) {
    let message = WatchMessage(
        id: UUID().uuidString,
        text: text,
        sender: "Watch",
        timestamp: Date().timeIntervalSince1970,
        isRead: false
    )

    sentMessages.append(message)
    saveSentMessages()
    let userInfo: [String: Any] = [
        "type": "message",
        "id": message.id,
        "text": message.text,
        "sender": message.sender,
        "timestamp": message.timestamp,
        "isRead": message.isRead
    ]

    session.transferUserInfo(userInfo)
    updateQueueStatus()
}
```

以下では、`WatchSessionManager`の extension として`WCSessionDelegate`を定義しています。
このデリゲートで iOS 側との連絡を行います。
`activationDidCompleteWith`では、セッションのアクティベーションが完了した際に`isReachable`を更新する処理を行なっています。
`sessionReachabilityDidChange`では、iOS との通信が可能かどうかのステータスが変化した際に`isReachable`を更新する処理を行なっています。
```swift
extension WatchSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if let error = error {
            print("Activation error: \(error.localizedDescription)")
        }
        updateQueueStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
```

以下では、`didReceiveUserInfo`で iOS からメッセージを受け取った際の処理を記述しています。
`userInfo`からメッセージの値を取得し、`@Published`プロパティを更新することで、UI が更新されます。
`DispatchQueue.main.async`でメインスレッドでの更新を保証しています。
また、重複受信を防ぐために、受信済みメッセージIDをチェックしています。
```swift
func session(
    _ session: WCSession,
    didReceiveUserInfo userInfo: [String : Any]
) {
    guard let type = userInfo["type"] as? String, type == "message" else {
        return
    }

    guard let id = userInfo["id"] as? String,
          let text = userInfo["text"] as? String,
          let sender = userInfo["sender"] as? String,
          let timestamp = userInfo["timestamp"] as? Double,
          let isRead = userInfo["isRead"] as? Bool else {
        print("Invalid message format")
        return
    }

    let receivedIds = getReceivedMessageIds()
    if receivedIds.contains(id) {
        return
    }

    let message = WatchMessage(
        id: id,
        text: text,
        sender: sender,
        timestamp: timestamp,
        isRead: isRead
    )

    DispatchQueue.main.async {
        self.receivedMessages.append(message)
        self.saveReceivedMessages()
        self.addReceivedMessageId(id)
    }
}
```

次に、watchOS のアプリのエントリーポイントで、WCSession の初期化を行います。
コードは以下の通りです。
先ほど定義した`WatchSessionManager`を`StateObject`で`ContentView`に渡しています。
```swift: ios/FlutterWatch Watch App/FlutterWatchApp.swift
import SwiftUI
import WatchConnectivity

@main
struct FlutterWatch_Watch_AppApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}
```

#### watchOS の UI 作成
次に`ContentView`の実装を行います。
コードは以下の通りで、シンプルなメッセージアプリになっています。
メッセージの送信、受信メッセージの表示、送信済みメッセージの表示などができるようになっています。
```swift: ios/FlutterWatch Watch App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    var body: some View {
        NavigationStack {
            List {
                // 接続状態とキュー状態の表示
                HStack {
                    Circle()
                        .fill(sessionManager.isReachable ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(sessionManager.isReachable ? "接続中" : "未接続")
                        .font(.caption)
                    if sessionManager.outstandingCount > 0 {
                        Text("(\(sessionManager.outstandingCount)件送信中)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // メッセージ送信セクション
                Section("メッセージ送信") {
                    // メッセージ送信のUI
                }

                // 受信メッセージセクション
                Section("受信メッセージ") {
                    ForEach(sessionManager.receivedMessages) { message in
                        MessageRow(message: message)
                    }
                }

                // 送信済みメッセージセクション
                Section("送信済みメッセージ") {
                    ForEach(sessionManager.sentMessages) { message in
                        SentMessageRow(message: message)
                    }
                }
            }
            .navigationTitle("Messages")
        }
    }
}
```

これで watchOS 側の実装は完了です。
iOS 側にメッセージを送信することができるようになりました。

### iOS 側の実装
次に iOS 側の実装を行います。
iOS で実現したい挙動は以下の通りです。

- iOS で受け付けたメッセージを送信し、送信済みメッセージとして保存する
- watchOS から送信されてきたメッセージを iOS に反映する

#### watchOS との連絡部分
watchOS 側の実装と同様に、まずは相手のプラットフォームとの連絡部分を実装していきます。
コードは以下の通りです。
```swift: ios/Runner/WCSessionManager.swift
import Foundation
import WatchConnectivity
import Flutter

class WCSessionManager: NSObject {
    static let shared = WCSessionManager()

    private let session = WCSession.default
    private var flutterApi: MessageFlutterApi?

    private let defaults = UserDefaults.standard
    private let sentMessagesKey = "sent_messages"
    private let receivedMessagesKey = "received_messages"
    private let receivedMessageIdsKey = "received_message_ids"

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func setupFlutterApi(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = MessageFlutterApi(binaryMessenger: binaryMessenger)
    }

    func sendMessage(message: MessageData) throws {
        saveSentMessage(message)
        let userInfo: [String: Any] = [
            "type": "message",
            "id": message.id,
            "text": message.text,
            "sender": message.sender,
            "timestamp": message.timestamp,
            "isRead": message.isRead
        ]

        session.transferUserInfo(userInfo)
        notifyQueueStatus()
    }

    func getSentMessages() -> [MessageData] {
        return loadSentMessages()
    }

    func getReceivedMessages() -> [MessageData] {
        return loadReceivedMessages()
    }

    func getQueueStatus() -> QueueStatus {
        let transfers = session.outstandingUserInfoTransfers
        let isTransferring = transfers.contains { $0.isTransferring }

        return QueueStatus(
            outstandingCount: Int64(transfers.count),
            isTransferring: isTransferring
        )
    }

    func cancelMessage(messageId: String) -> Bool {
        for transfer in session.outstandingUserInfoTransfers {
            if let id = transfer.userInfo["id"] as? String, id == messageId {
                transfer.cancel()
                notifyQueueStatus()
                return true
            }
        }

        return false
    }

    func markAsRead(messageId: String) {
        var messages = loadReceivedMessages()
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index] = MessageData(
                id: messages[index].id,
                text: messages[index].text,
                sender: messages[index].sender,
                timestamp: messages[index].timestamp,
                isRead: true
            )
            saveReceivedMessages(messages)
        }
    }

    func isWatchReachable() -> Bool {
        return session.isReachable
    }

    private func saveSentMessage(_ message: MessageData) {
        var messages = loadSentMessages()
        messages.append(message)
        saveSentMessages(messages)
    }

    private func saveSentMessages(_ messages: [MessageData]) {
        let array = messages.map { messageToDict($0) }
        defaults.set(array, forKey: sentMessagesKey)
    }

    private func loadSentMessages() -> [MessageData] {
        guard let array = defaults.array(forKey: sentMessagesKey) as? [[String: Any]] else {
            return []
        }
        return array.compactMap { dictToMessage($0) }
    }

    private func saveReceivedMessages(_ messages: [MessageData]) {
        let array = messages.map { messageToDict($0) }
        defaults.set(array, forKey: receivedMessagesKey)
    }

    private func loadReceivedMessages() -> [MessageData] {
        guard let array = defaults.array(forKey: receivedMessagesKey) as? [[String: Any]] else {
            return []
        }
        return array.compactMap { dictToMessage($0) }
    }

    private func messageToDict(_ message: MessageData) -> [String: Any] {
        return [
            "id": message.id,
            "text": message.text,
            "sender": message.sender,
            "timestamp": message.timestamp,
            "isRead": message.isRead
        ]
    }

    private func dictToMessage(_ dict: [String: Any]) -> MessageData? {
        guard let id = dict["id"] as? String,
              let text = dict["text"] as? String,
              let sender = dict["sender"] as? String,
              let timestamp = dict["timestamp"] as? Double,
              let isRead = dict["isRead"] as? Bool else {
            return nil
        }

        return MessageData(
            id: id,
            text: text,
            sender: sender,
            timestamp: timestamp,
            isRead: isRead
        )
    }

    private func notifyFlutter(message: MessageData) {
        guard let api = flutterApi else {
            print("FlutterApi not set up")
            return
        }

        DispatchQueue.main.async {
            api.onMessageReceived(message: message) { result in
                switch result {
                case .success:
                    print("Message notified to Flutter")
                case .failure(let error):
                    print("Failed to notify message to Flutter: \(error)")
                }
            }
        }
    }

    private func notifyQueueStatus() {
        guard let api = flutterApi else { return }

        let status = getQueueStatus()

        DispatchQueue.main.async {
            api.onQueueStatusChanged(status: status) { result in
                switch result {
                case .success:
                    print("Queue status notified to Flutter: \(status.outstandingCount)")
                case .failure(let error):
                    print("Failed to notify queue status to Flutter: \(error)")
                }
            }
        }
    }

    private func notifyFlutterReachability(isReachable: Bool) {
        guard let api = flutterApi else { return }

        DispatchQueue.main.async {
            api.onReachabilityChanged(isReachable: isReachable) { result in
                switch result {
                case .success:
                    print("Reachability notified to Flutter: \(isReachable)")
                case .failure(let error):
                    print("Failed to notify reachability to Flutter: \(error)")
                }
            }
        }
    }

    private func getReceivedMessageIds() -> Set<String> {
        guard let array = defaults.array(forKey: receivedMessageIdsKey) as? [String] else {
            return Set()
        }
        return Set(array)
    }

    private func addReceivedMessageId(_ id: String) {
        var ids = getReceivedMessageIds()
        ids.insert(id)
        defaults.set(Array(ids), forKey: receivedMessageIdsKey)
    }
}
```

それぞれ詳しくみていきます。

以下では、iOS 側の`WCSessionManager`を`NSObject`として定義しています。
Flutter とのやり取りを行うための`MessageFlutterApi`と、watchOS とのやり取りを行うための`WCSession`をそれぞれ保持しています。
```swift
class WCSessionManager: NSObject {
    static let shared = WCSessionManager()

    private let session = WCSession.default
    private var flutterApi: MessageFlutterApi?

    private let defaults = UserDefaults.standard
    private let sentMessagesKey = "sent_messages"
    private let receivedMessagesKey = "received_messages"
    private let receivedMessageIdsKey = "received_message_ids"
```

以下では、セッションを初期化する処理を記述しています。
`WCSession`のデリゲートを`WCSessionManager`自身に割り当て、セッションをアクティベートしています。この初期化処理によって watchOS との通信ができるようになります。
```swift
private override init() {
    super.init()

    guard WCSession.isSupported() else {
        return
    }

    session.delegate = self
    session.activate()
}
```

以下では、メッセージを watchOS 側に送信する処理を記述しています。
`session.transferUserInfo`の処理は、watchOS 側で定義したものと同じような内容になっています。
watchOS の場合と同様に、`isReachable`のチェックは不要で、すべてのメッセージがキューに保持され、順番に配信されます。
送信後、`notifyQueueStatus()`でキュー状態を Flutter 側に通知しています。
```swift
func sendMessage(message: MessageData) throws {
    saveSentMessage(message)
    let userInfo: [String: Any] = [
        "type": "message",
        "id": message.id,
        "text": message.text,
        "sender": message.sender,
        "timestamp": message.timestamp,
        "isRead": message.isRead
    ]

    session.transferUserInfo(userInfo)
    notifyQueueStatus()
}
```

以下では、キュー状態を取得する処理を実装しています。
`outstandingUserInfoTransfers`でキューに残っているデータの数、つまり送信されていないメッセージの数を確認できます。
```swift
func getQueueStatus() -> QueueStatus {
    let transfers = session.outstandingUserInfoTransfers
    let isTransferring = transfers.contains { $0.isTransferring }

    return QueueStatus(
        outstandingCount: Int64(transfers.count),
        isTransferring: isTransferring
    )
}
```

以下では、特定のメッセージの転送をキャンセルする処理を実装しています。
`outstandingUserInfoTransfers`から該当するメッセージを見つけて、`cancel()`を呼び出します。
```swift
func cancelMessage(messageId: String) -> Bool {
    for transfer in session.outstandingUserInfoTransfers {
        if let id = transfer.userInfo["id"] as? String, id == messageId {
            transfer.cancel()
            notifyQueueStatus()
            return true
        }
    }

    return false
}
```

以下では watchOS 側の実装と同様に`WCSessionManager`を`WCSessionDelegate`に準拠させています。
セッションのアクティベーションが完了した時に Flutter 側に接続状態を通知するようにしています。
```swift
extension WCSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("Activation error: \(error.localizedDescription)")
        }

        notifyFlutterReachability(isReachable: session.isReachable)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        notifyFlutterReachability(isReachable: session.isReachable)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
```

以下では、watchOS からメッセージを受け取った際の挙動を定義しています。
`didReceiveUserInfo`でメッセージを受け取り、Flutter 側に通知しています。
これで、メッセージの値を watchOS から受け取り、Flutter へ送る流れができます。
また、重複受信を防ぐために、受信済みメッセージIDをチェックしています。
```swift
func session(
    _ session: WCSession,
    didReceiveUserInfo userInfo: [String : Any] = [:]
) {
    guard let type = userInfo["type"] as? String, type == "message" else {
        print("Invalid message type")
        return
    }

    guard let id = userInfo["id"] as? String,
          let text = userInfo["text"] as? String,
          let sender = userInfo["sender"] as? String,
          let timestamp = userInfo["timestamp"] as? Double,
          let isRead = userInfo["isRead"] as? Bool else {
        print("Invalid message format")
        return
    }

    let receivedIds = getReceivedMessageIds()
    if receivedIds.contains(id) {
        return
    }

    let message = MessageData(
        id: id,
        text: text,
        sender: sender,
        timestamp: timestamp,
        isRead: isRead
    )
    var messages = loadReceivedMessages()
    messages.append(message)
    saveReceivedMessages(messages)
    addReceivedMessageId(id)
    notifyFlutter(message: message)
}
```

#### AppDelegate の修正
次に AppDelegate の修正を行います。
コードは以下の通りです。
```swift: ios/Runner/AppDelegate.swift
import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    // WCSessionManagerの初期化
    let sessionManager = WCSessionManager.shared
    sessionManager.setupFlutterApi(binaryMessenger: controller.binaryMessenger)

    // Pigeon HostApiの登録
    let messageHostApi = MessageHostApiImpl(sessionManager: sessionManager)
    MessageHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: messageHostApi)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

それぞれ詳しくみていきます。
以下では、`FlutterViewController`を使って Pigeon の API を使用できるようにしています。
`WCSessionManager`のインスタンスを取得し、Flutter API を設定しています。
また、Pigeon の HostApi を登録しています。
```swift
let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

// WCSessionManagerの初期化
let sessionManager = WCSessionManager.shared
sessionManager.setupFlutterApi(binaryMessenger: controller.binaryMessenger)

// Pigeon HostApiの登録
let messageHostApi = MessageHostApiImpl(sessionManager: sessionManager)
MessageHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: messageHostApi)
```
これで iOS と watchOS 間のデータのやり取りの実装は完了です。

## iOS と Flutter 間のデータのやり取り
次に iOS と Flutter 間のデータのやり取りを実装します。
iOS と Flutter 間の通信は全体の中では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/56a8e0a2ded7-20251129.png)

以下の手順で進めていきます。
1. Pigeon API の定義
2. Service 層の定義
3. Provider の定義
4. UI の作成

### 1. Pigeon API の定義
まず、Flutter と iOS 間の通信を行うための Pigeon API を定義します。
コードは以下の通りです。
```dart: lib/pigeon/message_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon/message_api.g.dart',
    swiftOut: 'ios/Runner/Pigeon/MessageApi.g.swift',
  ),
)
class MessageData {
  final String id;
  final String text;
  final String sender;
  final double timestamp;
  final bool isRead;

  MessageData({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.isRead,
  });
}

class QueueStatus {
  final int outstandingCount;
  final bool isTransferring;

  QueueStatus({required this.outstandingCount, required this.isTransferring});
}

@HostApi()
abstract class MessageHostApi {
  @TaskQueue(type: TaskQueueType.serial)
  void sendMessage(MessageData message);

  @TaskQueue(type: TaskQueueType.serial)
  List<MessageData> getSentMessages();

  @TaskQueue(type: TaskQueueType.serial)
  List<MessageData> getReceivedMessages();

  @TaskQueue(type: TaskQueueType.serial)
  QueueStatus getQueueStatus();

  @TaskQueue(type: TaskQueueType.serial)
  bool cancelMessage(String messageId);

  @TaskQueue(type: TaskQueueType.serial)
  void markAsRead(String messageId);

  @TaskQueue(type: TaskQueueType.serial)
  bool isWatchReachable();
}

@FlutterApi()
abstract class MessageFlutterApi {
  @TaskQueue(type: TaskQueueType.serial)
  void onMessageReceived(MessageData message);

  @TaskQueue(type: TaskQueueType.serial)
  void onQueueStatusChanged(QueueStatus status);

  @TaskQueue(type: TaskQueueType.serial)
  void onReachabilityChanged(bool isReachable);
}
```

以下では、メッセージデータを表すクラスを定義しています。
`MessageData`は、メッセージID、テキスト、送信者、タイムスタンプ、既読状態を保持します。
```dart
class MessageData {
  final String id;
  final String text;
  final String sender;
  final double timestamp;
  final bool isRead;

  MessageData({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.isRead,
  });
}
```

以下では、キュー状態を表すクラスを定義しています。
`QueueStatus`は、キューに残っているメッセージ数と転送中かどうかを保持します。
```dart
class QueueStatus {
  final int outstandingCount;
  final bool isTransferring;

  QueueStatus({required this.outstandingCount, required this.isTransferring});
}
```

以下では、Flutter から iOS に対して実行する処理を記述しています。
Flutter から各プラットフォームに対して実行する処理は`@HostApi()`アノテーションをつけて、`abstract`つまり抽象クラスとしてまとめて定義します。
Flutter 側からは以下のメソッドを呼び出したいのでそれぞれ定義しています。
- メッセージの送信
- 送信済みメッセージの取得
- 受信済みメッセージの取得
- キュー状態の取得
- メッセージのキャンセル
- メッセージの既読マーク
- Apple Watch との接続状態の確認

```dart
@HostApi()
abstract class MessageHostApi {
  @TaskQueue(type: TaskQueueType.serial)
  void sendMessage(MessageData message);

  @TaskQueue(type: TaskQueueType.serial)
  List<MessageData> getSentMessages();

  @TaskQueue(type: TaskQueueType.serial)
  List<MessageData> getReceivedMessages();

  @TaskQueue(type: TaskQueueType.serial)
  QueueStatus getQueueStatus();

  @TaskQueue(type: TaskQueueType.serial)
  bool cancelMessage(String messageId);

  @TaskQueue(type: TaskQueueType.serial)
  void markAsRead(String messageId);

  @TaskQueue(type: TaskQueueType.serial)
  bool isWatchReachable();
}
```

以下では iOS から Flutter に対して実行する処理を記述しています。上記の`@HostApi()`の逆です。
iOS から Flutter へは以下のメソッドを呼び出したいのでそれぞれ定義しています。
- メッセージの受信通知
- キュー状態の変更通知
- 接続状態の変更通知

```dart
@FlutterApi()
abstract class MessageFlutterApi {
  @TaskQueue(type: TaskQueueType.serial)
  void onMessageReceived(MessageData message);

  @TaskQueue(type: TaskQueueType.serial)
  void onQueueStatusChanged(QueueStatus status);

  @TaskQueue(type: TaskQueueType.serial)
  void onReachabilityChanged(bool isReachable);
}
```

### 2. Service 層の定義
次に、Flutter 側で iOS とのやり取りを行うサービスの定義をしていきます。
コードは以下の通りです。
```dart: lib/services/message_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../pigeon/message_api.g.dart';
import '../models/message.dart';

part 'message_service.g.dart';

@riverpod
MessageService messageService(Ref ref) {
  return MessageService();
}

class MessageService implements MessageFlutterApi {
  final MessageHostApi _hostApi = MessageHostApi();

  Function(Message)? messageReceivedCallback;
  Function(MessageQueueStatus)? queueStatusChangedCallback;
  Function(bool)? reachabilityChangedCallback;

  MessageService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    MessageFlutterApi.setUp(this);
  }

  @override
  void onMessageReceived(MessageData message) {
    try {
      final msg = Message.fromPigeon(message);
      messageReceivedCallback?.call(msg);
    } catch (e) {
      debugPrint('Flutter: Error handling message: $e');
    }
  }

  @override
  void onQueueStatusChanged(QueueStatus status) {
    try {
      final queueStatus = MessageQueueStatus.fromPigeon(status);
      queueStatusChangedCallback?.call(queueStatus);
    } catch (e) {
      debugPrint('Flutter: Error handling queue status: $e');
    }
  }

  @override
  void onReachabilityChanged(bool isReachable) {
    try {
      reachabilityChangedCallback?.call(isReachable);
    } catch (e) {
      debugPrint('Flutter: Error handling reachability: $e');
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      _hostApi.sendMessage(message.toPigeon());
    } catch (e) {
      debugPrint('Flutter: Error sending message: $e');
      rethrow;
    }
  }

  Future<List<Message>> getSentMessages() async {
    try {
      final messages = await _hostApi.getSentMessages();
      return messages.map((m) => Message.fromPigeon(m)).toList();
    } catch (e) {
      debugPrint('Flutter: Error getting sent messages: $e');
      return [];
    }
  }

  Future<List<Message>> getReceivedMessages() async {
    try {
      final messages = await _hostApi.getReceivedMessages();
      return messages.map((m) => Message.fromPigeon(m)).toList();
    } catch (e) {
      debugPrint('Flutter: Error getting received messages: $e');
      return [];
    }
  }

  Future<MessageQueueStatus> getQueueStatus() async {
    try {
      final status = await _hostApi.getQueueStatus();
      return MessageQueueStatus.fromPigeon(status);
    } catch (e) {
      debugPrint('Flutter: Error getting queue status: $e');
      return const MessageQueueStatus();
    }
  }

  Future<bool> cancelMessage(String messageId) async {
    try {
      final result = await _hostApi.cancelMessage(messageId);
      return result;
    } catch (e) {
      debugPrint('Flutter: Error cancelling message: $e');
      return false;
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _hostApi.markAsRead(messageId);
    } catch (e) {
      debugPrint('Flutter: Error marking as read: $e');
    }
  }

  Future<bool> isWatchReachable() async {
    try {
      final isReachable = await _hostApi.isWatchReachable();
      return isReachable;
    } catch (e) {
      debugPrint('Flutter: Error checking reachability: $e');
      return false;
    }
  }
}
```

以下では、iOS とメッセージに関する通信を行うための Service を定義しています。
また、初期化の段階で`_setupFlutterApi`メソッドを実行しています。
```dart
class MessageService implements MessageFlutterApi {
  final MessageHostApi _hostApi = MessageHostApi();

  Function(Message)? messageReceivedCallback;
  Function(MessageQueueStatus)? queueStatusChangedCallback;
  Function(bool)? reachabilityChangedCallback;

  MessageService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    MessageFlutterApi.setUp(this);
  }
```

以下では、iOS からメッセージが受信された際の処理を記述しています。
`onMessageReceived`でメッセージを受け取り、コールバックを呼び出しています。
```dart
@override
void onMessageReceived(MessageData message) {
  try {
    final msg = Message.fromPigeon(message);
    messageReceivedCallback?.call(msg);
  } catch (e) {
    debugPrint('Flutter: Error handling message: $e');
  }
}
```

以下では、Pigeon の HostApi で`sendMessage`イベントを送信して、iOS 側のメッセージを送信するためのメソッドを実装しています。
```dart
Future<void> sendMessage(Message message) async {
  try {
    _hostApi.sendMessage(message.toPigeon());
  } catch (e) {
    debugPrint('Flutter: Error sending message: $e');
    rethrow;
  }
}
```

### 3. Provider の定義
次に Flutter 側で必要な Provider の定義をしていきます。
コードは以下の通りです。
```dart: lib/providers/message_provider.dart
import 'package:flutter_watch/models/message.dart';
import 'package:flutter_watch/services/message_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_provider.g.dart';

@riverpod
class Messages extends _$Messages {
  @override
  List<Message> build() {
    final service = ref.watch(messageServiceProvider);
    service.messageReceivedCallback = (message) {
      state = [...state, message];
    };

    _loadMessages();

    return [];
  }

  Future<void> _loadMessages() async {
    final service = ref.read(messageServiceProvider);
    final sentMessages = await service.getSentMessages();
    final receivedMessages = await service.getReceivedMessages();
    state = [...sentMessages, ...receivedMessages];
  }

  Future<void> sendMessage(String text) async {
    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        sender: "Flutter",
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
        isRead: false,
      );
      final service = ref.read(messageServiceProvider);
      await service.sendMessage(message);
      state = [...state, message];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      final service = ref.read(messageServiceProvider);
      await service.markAsRead(messageId);
      state = state.map((m) {
        if (m.id == messageId) {
          return m.copyWith(isRead: true);
        }
        return m;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
class MessageQueueStatus extends _$MessageQueueStatus {
  @override
  MessageQueueStatus build() {
    final service = ref.watch(messageServiceProvider);
    service.queueStatusChangedCallback = (status) {
      state = status;
    };

    _loadQueueStatus();

    return const MessageQueueStatus();
  }

  Future<void> _loadQueueStatus() async {
    final service = ref.read(messageServiceProvider);
    final status = await service.getQueueStatus();
    state = status;
  }

  Future<void> refresh() async {
    await _loadQueueStatus();
  }
}

@riverpod
class WatchReachable extends _$WatchReachable {
  @override
  bool build() {
    final service = ref.watch(messageServiceProvider);
    service.reachabilityChangedCallback = (isReachable) {
      state = isReachable;
    };

    _checkReachability();

    return false;
  }

  Future<void> _checkReachability() async {
    final service = ref.read(messageServiceProvider);
    final isReachable = await service.isWatchReachable();
    state = isReachable;
  }

  Future<void> refresh() async {
    await _checkReachability();
  }
}
```

以下では、メッセージの状態を管理する Provider を定義しています。
`build`メソッドで、Service のコールバックを設定し、メッセージが受信された際に状態を更新するようにしています。
```dart
@riverpod
class Messages extends _$Messages {
  @override
  List<Message> build() {
    final service = ref.watch(messageServiceProvider);
    service.messageReceivedCallback = (message) {
      state = [...state, message];
    };

    _loadMessages();

    return [];
  }
```

以下では、メッセージを送信するメソッドを実装しています。
メッセージを作成し、Service を通じて iOS 側に送信しています。
```dart
Future<void> sendMessage(String text) async {
  try {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: "Flutter",
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      isRead: false,
    );
    final service = ref.read(messageServiceProvider);
    await service.sendMessage(message);
    state = [...state, message];
  } catch (e) {
    rethrow;
  }
}
```

### 4. UI の作成
次に UI を作成していきます。
コードは以下の通りです。
```dart: lib/pages/message_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_watch/models/message.dart';
import 'package:flutter_watch/providers/message_provider.dart';
import 'package:intl/intl.dart';

class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final queueStatus = ref.watch(messageQueueStatusProvider);
    final isReachable = ref.watch(watchReachableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          Icon(
            isReachable ? Icons.watch : Icons.watch_off,
            color: isReachable ? Colors.green : Colors.grey,
          ),
          if (queueStatus.outstandingCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 16.0),
              child: Text(
                '${queueStatus.outstandingCount}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // メッセージ送信セクション
          // メッセージリスト
        ],
      ),
    );
  }
}
```

以下では、メッセージ画面の UI を実装しています。
各セクションでメッセージを送受信できるようになっており、メッセージが送信されると自動的に iOS 側に送信され、watchOS 側にも反映されます。
また、キュー状態も表示されるようになっています。
```dart
class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final queueStatus = ref.watch(messageQueueStatusProvider);
    final isReachable = ref.watch(watchReachableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // 接続状態とキュー状態の表示
        ],
      ),
      body: Column(
        children: [
          // メッセージ送信セクション
          // メッセージリスト
        ],
      ),
    );
  }
}
```

これで、watchOS、iOS、Flutter を繋ぐメッセージアプリの実装が完了しました。

## まとめ
この章では、`transferUserInfo`を使ってメッセージデータを同期するアプリを実装しました。
`transferUserInfo`の特徴をまとめると以下のようになります。

- すべてのメッセージがキューに保持される
- 送信順序が保証される
- オフライン時でも動作する
- 到達可能性のチェックが不要
- 重要データの転送に適している

## 参考

