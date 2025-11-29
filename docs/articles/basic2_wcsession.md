## 初めに
この章では、WCSession を使って iOS と watchOS 間でデータのやり取りを行う方法を学びます。

### この章でできるようになること
- WCSession を使って iOS と watchOS 間で通信する方法を理解する
- sendMessage メソッドを使った実装方法を学ぶ
- Flutter と iOS、watchOS を連携させる方法を理解する

## WCSessionとは
[WCSession](https://developer.apple.com/documentation/watchconnectivity/wcsession)とは、Apple WatchアプリとiOSアプリ間の通信を行うためのオブジェクトです。
iOSアプリとwatchOSアプリは、実行中にこのクラスのインスタンスを作成し、設定する必要があります。両方のセッションがアクティブな場合にメッセージを送受信することで即座に通信できます。

初めの章の図では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/dd4572e4d2af-20250913.png)

## WCSessionの仕組み
WCSessionを利用した通信には、いくつかの前提条件があります。
- 通信を行う iPhone と Apple Watch がペアリングされていること
- 両方のデバイスに同じアプリケーションがインストールされていること

さらに、[WWDC のセッション](https://developer.apple.com/jp/videos/play/wwdc2021/10003/?t=817) によると、WCSession は Bluetooth または Wi-Fi を用いて通信します。そのため、両デバイスは以下のいずれかの条件を満たす必要があります。
- Bluetooth の通信が可能な範囲にある
- 同じ Wi-Fi ネットワークに接続されている

また、WCSession は単にデータをやり取りするだけでなく、通信が可能かどうかを判定するための状態情報を提供します。
これによりアプリは状況に応じて振る舞いを切り替えることができます。
- デバイス同士がペアリングされているか
- 相手側にアプリがインストールされているか
- 今すぐ通信可能か（アクティブ状態か）

このように WCSession は、iPhone と Apple Watch 間の通信経路を抽象化し、開発者が明示的に制御しなくても「即時に送信できる場合」と「後で配送される場合」を自動的に切り替えて処理してくれます。

## 通信の方法
WCSessionに用意されている通信方法の種類について軽く触れておきます。
WCSessionには送信するデータや即時反映の必要性等に応じて使い分けができます。
以下のようなメソッドが用意されています。
この章ではまず `sendMessage` を使って通信を行います。
他のメソッドに関しては別の章で詳しく紹介します。

- `sendMessage`
  - 相手デバイスがアクティブで通信可能なときに、即時にメッセージを送る
  - 応答を受け取ることも可能
- `updateApplicationContext`
  - アプリ全体の状態（設定や画面表示に必要な情報など）を共有する
  - 常に最新の内容だけが保持される
- `transferUserInfo`
  - 即時性はないが、必ず配送されるデータを送る
  - 履歴が順番に処理される
- `transferFile`
  - ファイルデータを転送する
  - バックグラウンドでも配送される

## 使ってみる
次は実際にWCSessionを使ってiOSとwatchOSのデータのやり取り行い、さらにそれをFlutter側にも反映させる実装を行います。
今回の実装では、簡単なカウンターアプリを題材として扱います。

最終的には以下の動画のように、iPhoneとApple Watchでそれぞれの操作を受け取り、表示内容が同期するような実装を行います。

実装は以下の手順で進めていきます。
1. iOSとwatchOS間のデータのやり取り
2. iOSとFlutter間のデータのやり取り

## iOSとwatchOS間のデータのやり取り
### 前提
iOSとwatchOS間の通信の実装に際して、前提を確認しておきます。
iOSとwatchOSの通信は全体の中では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/05d07bcc9188-20250914.png)

両OSでは、以下の二つを定義することで双方向の通信ができるようになります。
- 相手側にメッセージを送る処理（sendMessage）
- 相手側からメッセージが届いた時に実行する処理（didReceiveMessage）
![](https://storage.googleapis.com/zenn-user-upload/7e48fb95839f-20250914.png)

### watch側の実装
前提が確認できたところで、watch側の実装から進めていきます。
watchOSで実現したい挙動は以下の通りです。
- watchOSで受け付けた操作を反映しつつiOS側に送信する
- iOSから送信されてきた操作をwatchOSに反映する

今回実装するアプリに置き換えると以下のようになります。
- watchOSでカウンターの加算、減算を反映しつつ、更新された値をiOS側に送信する
- iOSから送られてきたカウンターの値をwatchOSのカウンターの値に反映する

#### iOSとの連絡部分
まずはiOSとの連絡部分を実装していきます。
コードは以下の通りです。以下で詳しくみていきます。
```swift: ios/FlutterWatch Watch App/WCSessionManager.swift
import SwiftUI
import WatchConnectivity
import Combine

final class WCSessionManager: NSObject, ObservableObject {
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

    func startSession() {
        wcSession?.activate()
        self.checkSessionState()
    }

    private func checkSessionState() {
        guard let session = wcSession else {
            return
        }

        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }

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
        sendCounterValue(newValue)
    }

    private func sendCounterValue(_ value: Int) {
        guard let session = wcSession else {
            return
        }

        guard session.isReachable else {
            return
        }

        let message = ["counter": value]
        session.sendMessage(message, replyHandler: { _ in
        }, errorHandler: { error in
            debugPrint("⌚️ Send error: \(error.localizedDescription)")
        })
    }
}

extension WCSessionManager: WCSessionDelegate {
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
                self.counter = counterValue
            }

            let reply = ["status": "received"] as [String : Any]
            replyHandler(reply)
        }
    }
}
```

以下では、`WCSessionManager`を`ObservableObject`に準拠させています。これで外部からは`StateObject`や`EnvironmentObject`として扱うことができます。
`counter`ではApple Watch側の現在のカウンターの値を保持しています。
`isConnected`では、iPhoneと接続されているかどうかを保持しています。
`wcSession`はiOSとの連絡を行うためのセッションであり、外部から参照できないようにプライベート変数としています。
```swift
final class WCSessionManager: NSObject, ObservableObject {
    @Published var counter: Int = 0
    @Published var isConnected: Bool = false

    private var wcSession: WCSession?
```

以下では、`WCSessionManager`の初期化処理を記述しています。
初期化処理では、WCSessionがサポートされているかどうかを確認しています。
`WCSession.default`は現在のデバイスのセッションのシングルトンオブジェクトであり、これを使ってiOSとの通信を行います。
```swift
override init() {
    super.init()
    if WCSession.isSupported() {
        wcSession = WCSession.default
        wcSession?.delegate = self
    }
}
```

以下では、セッション開始時に行う処理を記述しています。
通信を行うためにはセッションを`activate`する必要があります。
```swift
func startSession() {
    wcSession?.activate()
    self.checkSessionState()
}
```

以下では、セッションの状態を確認しています。
`WCSession.default`が割り当てられており、かつ通信可能な状態かどうかを確かめています。
```swift
private func checkSessionState() {
    guard let session = wcSession else {
        return
    }

    DispatchQueue.main.async {
        self.isConnected = session.isReachable
    }
}
```

以下では、カウンターの値を更新するメソッドを用意しています。
`updateCounter`メソッドで値を更新しており、`sendCounterValue`メソッドでカウンターの値をiOS側に送信しています。
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
    sendCounterValue(newValue)
}
```

以下では、watchOSのカウンターの値をiOSへ送信するためのメソッドを実装しています。
`session.sendMessage`メソッドでカウンターの値をiOSへ送信しています。
第一引数には`message`としてカウンターの値を指定しています。
第二引数は`replyHandler`で、iOS側にメッセージが届いた際に実行する処理を記述しています。この場合は特に必要ないので内容のないメソッドを指定しています。
第三引数は`errorHandler`で、通信でエラーが発生した際の処理を記述しています。この場合はエラーを出力するようにしています。
```swift
private func sendCounterValue(_ value: Int) {
    guard let session = wcSession else {
        return
    }

    guard session.isReachable else {
        return
    }

    let message = ["counter": value]
    session.sendMessage(message, replyHandler: { _ in
    }, errorHandler: { error in
        debugPrint("⌚️ Send error: \(error.localizedDescription)")
    })
}
```

以下では、`WCSessionManager`のextensionとして`WCSessionDelegate`を定義しています。
このデリゲートでiOS側との連絡を行います。
`activationDidCompleteWith`では、セッションのアクティベーションが完了した際に`isConnected`を更新する処理を行なっています。
`sessionReachabilityDidChange`では、iOSとの通信が可能かどうかのステータスが変化した際に`isConnected`を更新する処理を行なっています。
```swift
extension WCSessionManager: WCSessionDelegate {
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
```

以下では、`didReceiveMessage`でiOSからデータを受け取った際の処理を記述しています。
`message`を受け取り、その値を`counter`の値にセットしています。
これで、iOSでカウンターの値が更新されてwatchOSに送られた時に`counter`の値が変更されるようになっています。
```swift
func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    DispatchQueue.main.async {
        if let counterValue = message["counter"] as? Int {
            self.counter = counterValue
        }
    }
}
```

以下では、先ほどの処理とほぼ同様ですが、`replyHandler`で`received`というステータスを返すようにしています。これで、カウンターの値が更新された際にwatchOSからiOS側に`received`のステータスが返却されるようになります。
```swift
func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    DispatchQueue.main.async {
        if let counterValue = message["counter"] as? Int {
            self.counter = counterValue
        }

        let reply = ["status": "received"] as [String : Any]
        replyHandler(reply)
    }
}
```

次に、watchOSのアプリのエントリーポイントで、WCSessionの初期化を行います。
コードは以下の通りです。
先ほど定義した`WCSessionManager`を`environmentObject`で`ContentView`に渡しています。
```swift: ios/FlutterWatch Watch App/FlutterWatchApp.swift
import SwiftUI
import WatchConnectivity
import Combine

@main
struct FlutterWatch_Watch_AppApp: App {
    @StateObject private var sessionManager = WCSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}
```

#### watchOSのUI作成
次に`ContentView`の実装を行います。
コードは以下の通りで、シンプルなカウンターになっています。
それぞれカウンターの値を加算、減算するボタンを配置しています。
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WCSessionManager

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

これでwatchOS側の実装は完了です。
iOS側にカウンターの値や加算、減算のイベントを送信することができるようになりました。

### iOS側の実装
次にiOS側の実装を行います。
iOSで実現したい挙動は以下の通りです。
- iOSで受け付けた操作を反映しつつwatchOS側に送信する
- watchOSから送信されてきた操作をiOSに反映する

#### watchOSとの連絡部分
watchOS側の実装と同様に、まずは相手のプラットフォームとの連絡部分を実装していきます。
コードは以下の通りです。
```swift
import WatchConnectivity

class WCSessionManager: NSObject {
    private let methodChannel: FlutterMethodChannel
    private var wcSession: WCSession?

    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init()
    }

    func initializeSession(completion: @escaping (Bool, String) -> Void) {
        guard WCSession.isSupported() else {
            completion(false, "WCSession is not supported")
            return
        }

        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let session = self?.wcSession else {
                completion(false, "Session is nil after activation")
                return
            }

            let status = self?.getSessionStatus(session) ?? "Error"
            completion(session.isReachable, status)
        }
    }

    func sendCounterValue(_ counter: Int, completion: @escaping (Bool) -> Void) {
        guard let session = wcSession else {
            completion(false)
            return
        }

        guard session.isReachable else {
            completion(false)
            return
        }

        let message = ["counter": counter]
        session.sendMessage(message, replyHandler: { response in
            completion(true)
        }, errorHandler: { error in
            completion(false)
        })
    }

    private func getSessionStatus(_ session: WCSession) -> String {
        if !session.isPaired {
            return "not_paired"
        } else if !session.isWatchAppInstalled {
            return "not_installed"
        } else if !session.isReachable {
            return "not_reachable"
        } else {
            return "connected"
        }
    }
}

extension WCSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            var status: String

            if let error = error {
                status = "error"
            } else {
                switch activationState {
                case .activated:
                    status = self?.getSessionStatus(session) ?? "error"
                case .inactive:
                    status = "not_reachable"
                case .notActivated:
                    status = "connecting"
                @unknown default:
                    status = "error"
                }
            }

            self?.methodChannel.invokeMethod("sessionStateChanged",
                                           arguments: ["status_key": status])
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel.invokeMethod("sessionStateChanged",
                                           arguments: ["status_key": "not_reachable"])
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel.invokeMethod("sessionStateChanged",
                                           arguments: ["status_key": "error"])
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.methodChannel.invokeMethod("counterUpdated",
                                               arguments: ["counter": counter])
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {

        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.methodChannel.invokeMethod("counterUpdated",
                                               arguments: ["counter": counter])
            }

            let reply = ["status": "received"] as [String : Any]
            replyHandler(reply)
        }
    }
}
```

それぞれ詳しくみていきます。

以下では、iOS側の`WCSessionManager`を`NSObject`として定義しています。
Flutterとのやり取りを行うための`FlutterMethodChannel`と、watchOSとのやり取りを行うための`WCSession`をそれぞれ受け取っています。
```swift
class WCSessionManager: NSObject {
    private let methodChannel: FlutterMethodChannel
    private var wcSession: WCSession?

    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init()
    }
```

以下では、セッションを初期化する処理を記述しています。
`WCSession`のデリゲートを`WCSessionManager`自身に割り当て、セッションをアクティベートしています。この初期化処理によってwatchOSとの通信ができるようになります。
```swift
func initializeSession(completion: @escaping (Bool, String) -> Void) {
    guard WCSession.isSupported() else {
        completion(false, "WCSession is not supported")
        return
    }

    wcSession = WCSession.default
    wcSession?.delegate = self
    wcSession?.activate()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        guard let session = self?.wcSession else {
            completion(false, "Session is nil after activation")
            return
        }

        let status = self?.getSessionStatus(session) ?? "Error"
        completion(session.isReachable, status)
    }
}
```

以下では、カウンターの値をwatchOS側に送信する処理を記述しています。
`session.sendMessage`の処理は、watchOS側で定義した内容と同じになっています。
iOSからwatchOSに送信する場合も`sendMessage`を用います。
`replyHandler`ではwatchOSがメッセージを受け取った際の処理を、`errorHandler`ではエラー時の処理を指定できます。
```swift
func sendCounterValue(_ counter: Int, completion: @escaping (Bool) -> Void) {
    guard let session = wcSession else {
        completion(false)
        return
    }

    guard session.isReachable else {
        completion(false)
        return
    }

    let message = ["counter": counter]
    session.sendMessage(message, replyHandler: { response in
        completion(true)
    }, errorHandler: { error in
        completion(false)
    })
}
```

以下では、セッションの状態を確認するメソッドを追加しています。
カウンターの実装自体には不要ですが、セッションを確立できなかった際の原因特定に使用できます。
```swift
private func getSessionStatus(_ session: WCSession) -> String {
    if !session.isPaired {
        return "not_paired"
    } else if !session.isWatchAppInstalled {
        return "not_installed"
    } else if !session.isReachable {
        return "not_reachable"
    } else {
        return "connected"
    }
}
```

以下ではwatchOS側の実装と同様に`WCSessionManager`を`WCSessionDelegate`に準拠させています。
セッションのアクティベーションが完了した時のステートを`invokeMethod`でFlutter側に送信するようにしています。Flutter側のMethodChannelで`sessionStateChanged`という名前のチャンネルを監視することで、セッションの状態を監視することができるようになります。
```swift
extension WCSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            var status: String

            if let error = error {
                status = "error"
            } else {
                switch activationState {
                case .activated:
                    status = self?.getSessionStatus(session) ?? "error"
                case .inactive:
                    status = "not_reachable"
                case .notActivated:
                    status = "connecting"
                @unknown default:
                    status = "error"
                }
            }

            self?.methodChannel.invokeMethod("sessionStateChanged",
                                           arguments: ["status_key": status])
        }
    }
```

`sessionDidBecomeInactive`はセッションが現在の Apple Watch との通信を停止することをデリゲートに伝えるために使用されます。
`sessionDidDeactivate`はセッションが前回のセッションからすべてのデータを配信し、Apple Watch との通信が終了したことをデリゲートに伝えるために使用されます。
以下ではそれぞれ、セッションの状態をFlutter側に伝えるのみになっています。
```swift
func sessionDidBecomeInactive(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
        self?.methodChannel.invokeMethod("sessionStateChanged",
                                       arguments: ["status_key": "not_reachable"])
    }
}

func sessionDidDeactivate(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
        self?.methodChannel.invokeMethod("sessionStateChanged",
                                       arguments: ["status_key": "error"])
    }
}
````

以下では、watchOSからメッセージを受け取った際の挙動を定義しています。
`invokeMethod`でFlutterのMethodChannelにカウンターの値を送信しています。
これで、カウンターの値をwatchOSから受け取り、Flutterへ送る流れができています。
```swift
func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    DispatchQueue.main.async { [weak self] in
        if let counter = message["counter"] as? Int {
            self?.methodChannel.invokeMethod("counterUpdated",
                                           arguments: ["counter": counter])
        }
    }
}

func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {

    DispatchQueue.main.async { [weak self] in
        if let counter = message["counter"] as? Int {
            self?.methodChannel.invokeMethod("counterUpdated",
                                           arguments: ["counter": counter])
        }

        let reply = ["status": "received"] as [String : Any]
        replyHandler(reply)
    }
}
```

#### AppDelegateの修正
次にAppDelegateの修正を行います。
コードは以下の通りです。
```swift: ios/Runner/AppDelegate.swift
import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var wcSessionManager: WCSessionManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let counterChannel = FlutterMethodChannel(name: "flutter_watch/counter",
                                              binaryMessenger: controller.binaryMessenger)

    wcSessionManager = WCSessionManager(methodChannel: counterChannel)

    counterChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleMethodCall(call: call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initializeSession":
      wcSessionManager?.initializeSession { success, statusKey in
        DispatchQueue.main.async {
          result(["status_key": statusKey])
        }
      }

    case "sendCounter":
      guard let args = call.arguments as? [String: Any],
            let counter = args["counter"] as? Int else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid counter value", details: nil))
        return
      }

      wcSessionManager?.sendCounterValue(counter) { success in
        DispatchQueue.main.async {
          result(success)
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

それぞれ詳しくみていきます。
以下では、`FlutterViewController`を使ってMethodChannelを使用できるようにしています。この辺りは前の章のMethodChannelの設定と同じかと思います。
以下では追加で`counterChannel`を渡して`WCSessionManager`のインスタンス化も行なっています。
`setMethodCallHandler`の中では`handleMethodCall`メソッドを実行しています。この内容については後述します。
```swift
@main
@objc class AppDelegate: FlutterAppDelegate {
  private var wcSessionManager: WCSessionManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let counterChannel = FlutterMethodChannel(name: "flutter_watch/counter",
                                              binaryMessenger: controller.binaryMessenger)

    wcSessionManager = WCSessionManager(methodChannel: counterChannel)

    counterChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleMethodCall(call: call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
```

以下では先ほどの触れた`handleMethodCall`の実装を行なっています。
Flutter側からMethodChannelを通して送信されたメッセージに関して、そのメソッド名によって行う処理を分岐させています。
`initializeSession`という名前の場合は`WCSessionManager`の`initializeSession`メソッドを実行しています。これでWCSessionが初期化され、Flutter側にはセッションのステータスを返すようにしています。
```swift
private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case "initializeSession":
            wcSessionManager?.initializeSession { success, statusKey in
                DispatchQueue.main.async {
                  result(["status_key": statusKey])
                }
            }
```

以下では、Flutter側から送られたメソッドの名前が`sendCounter`だった場合の処理を記述しています。
Flutterから送られたカウンターの値は`WCSessionManager`の`sendCounterValue`メソッドでwatchOS側に送信されています。
```swift
case "sendCounter":
  guard let args = call.arguments as? [String: Any],
        let counter = args["counter"] as? Int else {
    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid counter value", details: nil))
    return
  }

  wcSessionManager?.sendCounterValue(counter) { success in
    DispatchQueue.main.async {
      result(success)
    }
  }

default:
  result(FlutterMethodNotImplemented)
}
```

これでiOSとwatchOS間のデータのやり取りの実装は完了です。

## iOSとFlutter間のデータのやり取り
次にiOSとFlutter間のデータのやり取りを実装します。
以下の手順で進めていきます。
1. 必要な定数等の定義
2. Providerの定義
3. UIの作成

### 1. 必要な定数等の定義
以下では、Flutter側で使用するMethodChannelの名前を管理するためのenumを作成しています。
カウンターが更新された際のメソッド名と、セッションの状態が変更された際のメソッド名を定義しています。
```dart: lib/models/method_channel_method.dart
enum MethodChannelMethod {
  counterUpdated('counterUpdated'),
  sessionStateChanged('sessionStateChanged');

  const MethodChannelMethod(this.value);

  final String value;

  static MethodChannelMethod? fromString(String value) {
    for (final method in MethodChannelMethod.values) {
      if (method.value == value) {
        return method;
      }
    }
    return null;
  }
}
```

以下では、WCSessionの接続状態のenumを定義しています。
接続状態をFlutter側でも確認できるようにしています。
```dart: lib/models/watch_connection_status.dart
enum WatchConnectionStatus {
  connecting('接続確認中...'),
  connected('接続完了'),
  error('エラー'),
  notPaired('Apple Watchとペアリングされていません'),
  notInstalled('Watchアプリがインストールされていません'),
  notReachable('Apple Watchと通信できません');

  const WatchConnectionStatus(this.message);

  final String message;

  bool get isError =>
      this == WatchConnectionStatus.error ||
      this == WatchConnectionStatus.notPaired ||
      this == WatchConnectionStatus.notInstalled ||
      this == WatchConnectionStatus.notReachable;
}
```

以下では、Apple WatchとiPhoneとの接続状態のenumを定義しています。
```dart: lib/models/watch_status_key.dart
enum WatchStatusKey {
  connected('connected'),
  connecting('connecting'),
  error('error'),
  notPaired('not_paired'),
  notInstalled('not_installed'),
  notReachable('not_reachable');

  const WatchStatusKey(this.value);

  final String value;

  static WatchStatusKey? fromString(String value) {
    for (final key in WatchStatusKey.values) {
      if (key.value == value) {
        return key;
      }
    }
    return null;
  }
}
```

### 2. Providerの定義
次にFlutter側で必要なProviderの定義をしていきます。
それぞれ以下を用意します。
- 通信状態の管理を行うProvider
- カウンターの値を保持するProvider
- iOSとのやり取りを行うProvider

#### 通信状態の管理を行うProvider
以下では、WCSessionの状態の管理を行うためのProviderを用意しています。
```dart: lib/providers/connection_status_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_watch/models/watch_connection_status.dart';

part 'connection_status_provider.g.dart';

@riverpod
class ConnectionStatus extends _$ConnectionStatus {
  @override
  WatchConnectionStatus build() => WatchConnectionStatus.connected;

  void update(WatchConnectionStatus status) => state = status;
}
```

#### カウンターの値を保持するProvider
以下ではカウンターの値を保持するためのProviderを用意しています。
値の増加/減少や設定を行う基本的な作りになっています。
```dart: lib/providers/counter_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state += 1;
  void decrement() => state -= 1;
  void set(int value) => state = value;
}
```

#### iOSとのやり取りを行うProvider
以下では、iOSとのやり取りを行うサービスのProviderを用意しています。
それぞれ詳しく見ていきます。
```dart: lib/providers/watch_communication_service_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_watch/models/method_channel_method.dart';
import 'package:flutter_watch/models/watch_connection_status.dart';
import 'package:flutter_watch/models/watch_status_key.dart';
import 'package:flutter_watch/providers/connection_status_provider.dart';
import 'package:flutter_watch/providers/counter_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_communication_service_provider.g.dart';

@riverpod
WatchCommunicationService watchCommunicationService(
  WatchCommunicationServiceRef ref,
) {
  return WatchCommunicationService(ref);
}

const MethodChannel platformChannel = MethodChannel('flutter_watch/counter');

class WatchCommunicationService {
  final Ref _ref;

  WatchCommunicationService(this._ref) {
    _setupMessageListener();
  }

  Future<void> initializeConnection() async {
    try {
      final result = await platformChannel.invokeMethod('initializeSession');
      final statusKey = result['status_key'] ?? 'error';
      final status = _parseConnectionStatus(statusKey);
      _ref.read(connectionStatusProvider.notifier).update(status);
    } on PlatformException {
      _ref
          .read(connectionStatusProvider.notifier)
          .update(WatchConnectionStatus.error);
    }
  }

  void _setupMessageListener() {
    platformChannel.setMethodCallHandler((call) async {
      final method = MethodChannelMethod.fromString(call.method);

      switch (method) {
        case MethodChannelMethod.counterUpdated:
          final int newValue = call.arguments['counter'];
          _ref.read(counterProvider.notifier).set(newValue);
          break;

        case MethodChannelMethod.sessionStateChanged:
          final String statusKey = call.arguments['status_key'] ?? '';
          final status = _parseConnectionStatus(statusKey);
          _ref.read(connectionStatusProvider.notifier).update(status);
          break;

        default:
          debugPrint('📱 Unknown method received: ${call.method}');
          break;
      }
    });
  }

  Future<bool> updateCounter(int newValue) async {
    try {
      final success = await platformChannel.invokeMethod('sendCounter', {
        'counter': newValue,
      });

      return success == true;
    } on PlatformException catch (e) {
      debugPrint('📱 Send error: ${e.message}');
      rethrow;
    }
  }

  WatchConnectionStatus _parseConnectionStatus(String statusKey) {
    final key = WatchStatusKey.fromString(statusKey);

    switch (key) {
      case WatchStatusKey.connected:
        return WatchConnectionStatus.connected;
      case WatchStatusKey.notPaired:
        return WatchConnectionStatus.notPaired;
      case WatchStatusKey.notInstalled:
        return WatchConnectionStatus.notInstalled;
      case WatchStatusKey.notReachable:
        return WatchConnectionStatus.notReachable;
      case WatchStatusKey.error:
        return WatchConnectionStatus.error;
      case WatchStatusKey.connecting:
      case null:
        return WatchConnectionStatus.connecting;
    }
  }
}
```

以下では、iOSとカウンターに関する通信を行うためのMethodChannelを定義しています。
また、初期化の段階で`_setupMessageListener`メソッドを実行しています。
```dart
const MethodChannel platformChannel = MethodChannel('flutter_watch/counter');

class WatchCommunicationService {
  final Ref _ref;

  WatchCommunicationService(this._ref) {
    _setupMessageListener();
  }
```

以下では、Method Channelの`invokeMethod`で、`initializeSession`を実行しています。
返り値としては`status_key`が返却されます。
返却されたキーを元にして、Flutter側で表示する通信状態を更新しています。
```dart
Future<void> initializeConnection() async {
  try {
    final result = await platformChannel.invokeMethod('initializeSession');
    final statusKey = result['status_key'] ?? 'error';
    final status = _parseConnectionStatus(statusKey);
    _ref.read(connectionStatusProvider.notifier).update(status);
  } on PlatformException {
    _ref
      .read(connectionStatusProvider.notifier)
      .update(WatchConnectionStatus.error);
  }
}
```

以下では、Method Channelのハンドラを設定しています。
iOSからMethod Channelを通してイベントが送信されてきた際の処理を記述しています。
メソッド名ごとで異なる処理を割り当てています。
カウンターの値と通信状況を更新するイベントがあり、それぞれに対応するProviderを更新しています。
```dart
void _setupMessageListener() {
  platformChannel.setMethodCallHandler((call) async {
    final method = MethodChannelMethod.fromString(call.method);

    switch (method) {
      case MethodChannelMethod.counterUpdated:
        final int newValue = call.arguments['counter'];
        _ref.read(counterProvider.notifier).set(newValue);
        break;

      case MethodChannelMethod.sessionStateChanged:
        final String statusKey = call.arguments['status_key'] ?? '';
        final status = _parseConnectionStatus(statusKey);
        _ref.read(connectionStatusProvider.notifier).update(status);
        break;

      default:
        debugPrint('📱 Unknown method received: ${call.method}');
        break;
    }
  });
}
```

以下では、Method Channelで`sendCounter`イベントを送信して、iOS側のカウンターの値を更新するためのメソッドを実装しています。
```dart
Future<bool> updateCounter(int newValue) async {
  try {
    final success = await platformChannel.invokeMethod('sendCounter', {
      'counter': newValue,
    });

    return success == true;
  } on PlatformException catch (e) {
    debugPrint('📱 Send error: ${e.message}');
    rethrow;
  }
}
```

以下では、iOS側から送信されてきた通信状態のキーから`WatchConnectionStatus`に変換するメソッドを定義しています。
これで、iOSから受け取った文字列をenumに変換してFlutter側ではenumとして扱うことができます。
```dart
WatchConnectionStatus _parseConnectionStatus(String statusKey) {
  final key = WatchStatusKey.fromString(statusKey);

  switch (key) {
    case WatchStatusKey.connected:
      return WatchConnectionStatus.connected;
    case WatchStatusKey.notPaired:
      return WatchConnectionStatus.notPaired;
    case WatchStatusKey.notInstalled:
      return WatchConnectionStatus.notInstalled;
    case WatchStatusKey.notReachable:
      return WatchConnectionStatus.notReachable;
    case WatchStatusKey.error:
      return WatchConnectionStatus.error;
    case WatchStatusKey.connecting:
    case null:
      return WatchConnectionStatus.connecting;
  }
}
```

これでProviderの作成は完了です。

### 3. UIの作成
次にUIを作成していきます。
コードは以下の通りです。
```dart: lib/pages/counter_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_watch/providers/connection_status_provider.dart';
import 'package:flutter_watch/providers/counter_provider.dart';
import 'package:flutter_watch/providers/watch_communication_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CounterPage extends HookConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final watchService = ref.read(watchCommunicationServiceProvider);

    useEffect(() {
      watchService.initializeConnection();
      return null;
    }, []);

    Future<void> incrementCounter() async {
      try {
        ref.read(counterProvider.notifier).increment();
        final newValue = ref.read(counterProvider);

        await watchService.updateCounter(newValue);
      } on PlatformException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('送信エラー: ${e.message}')));
        }
      }
    }

    Future<void> decrementCounter() async {
      try {
        ref.read(counterProvider.notifier).decrement();
        final newValue = ref.read(counterProvider);

        await watchService.updateCounter(newValue);
      } on PlatformException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('送信エラー: ${e.message}')));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('iPhone ↔ Watch Demo'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'iPhone',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Text(
              '$counter',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: decrementCounter,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                ),
                IconButton(
                  onPressed: incrementCounter,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  connectionStatus.isError ? Icons.error : Icons.watch,
                  color: connectionStatus.isError ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  connectionStatus.isError ? 'エラー' : '接続完了',
                  style: TextStyle(
                    color: connectionStatus.isError ? Colors.red : Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

以下では、画面が表示された段階で`initializeConnection`メソッドを実行して、セッションの初期化を行なっています。
```dart
useEffect(() {
  watchService.initializeConnection();
  return null;
}, []);
```

以下では、カウンターの値の増加処理を記述しています。
まずは`counterProvider`の`increment`でFlutter側のカウンターの値を増加させています。
そして次に`watchService`の`updateCounter`でiOS側にカウンターの値の増加を通知しています。カウンターの値を減少させる処理についても同様です。
```dart
Future<void> incrementCounter() async {
  try {
    ref.read(counterProvider.notifier).increment();
    final newValue = ref.read(counterProvider);

    await watchService.updateCounter(newValue);
  } on PlatformException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('送信エラー: ${e.message}')));
    }
  }
}
```

これで、watchOS、iOS、Flutterを繋ぐカウンターの実装が完了しました。

## まとめ
この章では、WCSession の `sendMessage` メソッドを使って iOS と watchOS 間でデータのやり取りを行う方法を学びました。

主なポイント
- WCSession は iOS と watchOS 間の通信を管理する
- `sendMessage` は即座の応答が必要な操作に適している
- 接続状態を確認してからメッセージを送信する

実践編では他の WCSession メソッドについても触れているので、そちらで `sendMessage`以外のメソッドについても扱っていきます。

## 参考

https://developer.apple.com/jp/videos/play/wwdc2021/10003/
