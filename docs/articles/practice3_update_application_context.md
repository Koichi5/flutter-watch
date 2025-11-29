## updateApplicationContext とは
`updateApplicationContext`は、WatchConnectivity フレームワークが提供するメソッドの一つで、最新の状態（コンテキスト）を同期します。`updateApplicationContext`では、常に最新のデータのみが保持されます。また複数回連続で送信すると、古いデータは自動的に上書きされ、最後の値のみが送信されるといった特徴もあります。

## updateApplicationContext の特徴
`updateApplicationContext`には以下のような特徴があります。

- 最新データのみ保持
  - 連続して送信すると、古いデータは自動的に破棄され、最後の値のみが送信される
- バックグラウンド動作
  - アプリが非アクティブでも動作し、次回起動時に最新設定が反映される
- 自動配信
  - システムが適切なタイミングで配信するため、即座の配信は保証されない
- 到達可能性のチェック不要
  - `sendMessage`とは異なり、`isReachable`のチェックが不要

`updateApplicationContext`は、設定値など、最新値だけが重要なデータの同期に適しています。例えば、テーマカラーやフォントサイズなどの設定を、iPhone と Apple Watch 間で同期する場合に使用します。

一方で、即座の応答が必要な操作には`sendMessage`、確実な配信が必要な場合には`transferUserInfo`を検討する必要があるかと思います。

## 使ってみる
次は実際に`updateApplicationContext`を使って iOS と watchOS の設定データのやり取りを行い、さらにそれを Flutter 側にも反映させる実装を行います。
今回の実装では、設定画面を題材として扱います。

最終的には以下のように、iPhone と Apple Watch でそれぞれの設定変更を受け取り、表示内容が同期するような実装を行います。
実装は以下の手順で進めていきます。
1. iOS と watchOS 間のデータのやり取り
2. iOS と Flutter 間のデータのやり取り

## iOS と watchOS 間のデータのやり取り
### 前提
iOS と watchOS 間の通信の実装に際して、前提を確認しておきます。
iOS と watchOS の通信は全体の中では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/61d92efbe9e2-20251129.png)

両 OS では、以下の二つを定義することで双方向の通信ができるようになります。
- 相手側に設定を送る処理（updateApplicationContext）
- 相手側から設定が届いた時に実行する処理（didReceiveApplicationContext）

![](https://storage.googleapis.com/zenn-user-upload/01436fc174fd-20251129.png)

### watch 側の実装
前提が確認できたところで、watch 側の実装から進めていきます。
watchOS で実現したい挙動は以下の通りです。

- watchOS で受け付けた設定変更を反映しつつ iOS 側に送信する
- iOS から送信されてきた設定を watchOS に反映する

#### iOS との連絡部分
まずは iOS との連絡部分を実装していきます。
コードは以下の通りです。以下で詳しくみていきます。
```swift: ios/FlutterWatch Watch App/WatchSessionManager.swift
import Foundation
import WatchConnectivity
import Combine

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    private let session = WCSession.default

    private let defaults = UserDefaults.standard
    private let settingsKey = "app_settings"

    @Published var color: Int = 1
    @Published var fontSize: Int = 1
    @Published var notificationEnabled: Bool = true
    @Published var lastUpdated: Date = Date()
    @Published var isReachable: Bool = false

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        loadSettings()

        session.delegate = self
        session.activate()
    }

    func updateSettings() {
        saveSettings()

        let context: [String: Any] = [
            "color": color,
            "fontSize": fontSize,
            "notificationEnabled": notificationEnabled,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error)")
        }
    }

    private func saveSettings() {
        let dict: [String: Any] = [
            "color": color,
            "fontSize": fontSize,
            "notificationEnabled": notificationEnabled,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]
        defaults.set(dict, forKey: settingsKey)
    }

    private func loadSettings() {
        guard let dict = defaults.dictionary(forKey: settingsKey) else {
            return
        }

        color = dict["color"] as? Int ?? 1
        fontSize = dict["fontSize"] as? Int ?? 1
        notificationEnabled = dict["notificationEnabled"] as? Bool ?? true
        if let timestamp = dict["lastUpdated"] as? Double {
            lastUpdated = Date(timeIntervalSince1970: timestamp)
        }
    }
}
```

以下では、`WatchSessionManager`を`ObservableObject`に準拠させています。これで外部からは`StateObject`や`EnvironmentObject`として扱うことができます。
`color`、`fontSize`、`notificationEnabled`、`lastUpdated`では Apple Watch 側の現在の設定値を保持しています。
`isReachable`では、iPhone と接続されているかどうかを保持しています。

```swift
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    private let session = WCSession.default

    private let defaults = UserDefaults.standard
    private let settingsKey = "app_settings"

    @Published var color: Int = 1
    @Published var fontSize: Int = 1
    @Published var notificationEnabled: Bool = true
    @Published var lastUpdated: Date = Date()
    @Published var isReachable: Bool = false
```

以下では、`WatchSessionManager`の初期化処理を記述しています。
初期化処理では、WCSession がサポートされているかどうかを確認しています。
`WCSession.default`は現在のデバイスのセッションのシングルトンオブジェクトであり、これを使って iOS との通信を行います。
また、`loadSettings()`で保存されている設定を読み込んでいます。

```swift
private override init() {
    super.init()

    guard WCSession.isSupported() else {
        return
    }

    loadSettings()

    session.delegate = self
    session.activate()
}
```

以下では、設定を更新して iOS 側に送信する処理を記述しています。
`updateApplicationContext`メソッドで設定を iOS へ送信しています。
`sendMessage`と違い、`isReachable`のチェックは不要です。また、連続して送信すると、古いデータは自動的に上書きされ、最後の値のみが送信されます。
```swift
func updateSettings() {
    saveSettings()

    let context: [String: Any] = [
        "color": color,
        "fontSize": fontSize,
        "notificationEnabled": notificationEnabled,
        "lastUpdated": lastUpdated.timeIntervalSince1970
    ]

    do {
        try session.updateApplicationContext(context)
    } catch {
        print("Failed to update application context: \(error)")
    }
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
            print("Session activation error: \(error.localizedDescription)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
```

以下では、`didReceiveApplicationContext`で iOS から設定を受け取った際の処理を記述しています。
`applicationContext`から設定の値を取得し、`@Published`プロパティを更新することで、UI が更新されます。
`DispatchQueue.main.async`でメインスレッドでの更新を保証しています。
```swift
func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String : Any]
) {
    guard let color = applicationContext["color"] as? Int,
          let fontSize = applicationContext["fontSize"] as? Int,
          let notificationEnabled = applicationContext["notificationEnabled"] as? Bool,
          let lastUpdated = applicationContext["lastUpdated"] as? Double else {
        return
    }

    DispatchQueue.main.async {
        self.color = color
        self.fontSize = fontSize
        self.notificationEnabled = notificationEnabled
        self.lastUpdated = Date(timeIntervalSince1970: lastUpdated)
        self.saveSettings()
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
コードは以下の通りで、シンプルな設定画面になっています。
テーマカラー、フォントサイズ、通知設定などを表示・変更できるようになっています。

```swift: ios/FlutterWatch Watch App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    var body: some View {
        NavigationStack {
            List {
                // 接続状態の表示
                HStack {
                    Circle()
                        .fill(sessionManager.isReachable ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(sessionManager.isReachable ? "接続中" : "未接続")
                        .font(.caption)
                }

                // テーマカラーの選択
                Section("テーマカラー") {
                    // カラー選択のUI
                }

                // フォントサイズの選択
                Section("フォントサイズ") {
                    // フォントサイズ選択のUI
                }

                // 通知設定
                Section("通知") {
                    Toggle("通知を有効にする", isOn: Binding(
                        get: { sessionManager.notificationEnabled },
                        set: { newValue in
                            sessionManager.notificationEnabled = newValue
                            sessionManager.updateSettings()
                        }
                    ))
                }

                // 最終更新時刻
                Section("最終更新") {
                    Text(sessionManager.lastUpdated, style: .time)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

これで watchOS 側の実装は完了です。
iOS 側に設定の変更を送信することができるようになりました。

### iOS 側の実装
次に iOS 側の実装を行います。
iOS で実現したい挙動は以下の通りです。

- iOS で受け付けた設定変更を反映しつつ watchOS 側に送信する
- watchOS から送信されてきた設定を iOS に反映する

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
    private var flutterApi: SettingsFlutterApi?

    private let defaults = UserDefaults.standard
    private let settingsKey = "app_settings"

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func setupFlutterApi(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = SettingsFlutterApi(binaryMessenger: binaryMessenger)
    }

    func updateSettings(settings: SettingsData) throws {
        saveSettings(settings)

        let context: [String: Any] = [
            "color": settings.color,
            "fontSize": settings.fontSize,
            "notificationEnabled": settings.notificationEnabled,
            "lastUpdated": settings.lastUpdated
        ]

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error)")
            throw error
        }
    }

    func getCurrentSettings() -> SettingsData {
        return loadSettings()
    }

    func isWatchReachable() -> Bool {
        return session.isReachable
    }

    private func saveSettings(_ settings: SettingsData) {
        let dict: [String: Any] = [
            "color": settings.color,
            "fontSize": settings.fontSize,
            "notificationEnabled": settings.notificationEnabled,
            "lastUpdated": settings.lastUpdated
        ]
        defaults.set(dict, forKey: settingsKey)
    }

    private func loadSettings() -> SettingsData {
        guard let dict = defaults.dictionary(forKey: settingsKey) else {
            return SettingsData(
                color: 1,
                fontSize: 1,
                notificationEnabled: true,
                lastUpdated: Date().timeIntervalSince1970
            )
        }

        return SettingsData(
            color: dict["color"] as? Int64 ?? 1,
            fontSize: dict["fontSize"] as? Int64 ?? 1,
            notificationEnabled: dict["notificationEnabled"] as? Bool ?? true,
            lastUpdated: dict["lastUpdated"] as? Double ?? Date().timeIntervalSince1970
        )
    }

    private func notifyFlutter(settings: SettingsData) {
        guard let api = flutterApi else {
            return
        }

        DispatchQueue.main.async {
            api.onSettingsUpdated(settings: settings) { result in
                switch result {
                case .success:
                    print("Notified Flutter of settings update")
                case .failure(let error):
                    print("Failed to notify Flutter: \(error)")
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
                    print("Notified Flutter: reachable = \(isReachable)")
                case .failure(let error):
                    print("Failed to notify reachability: \(error)")
                }
            }
        }
    }
}
```

それぞれ詳しくみていきます。

以下では、iOS 側の`WCSessionManager`を`NSObject`として定義しています。
Flutter とのやり取りを行うための`SettingsFlutterApi`と、watchOS とのやり取りを行うための`WCSession`をそれぞれ保持しています。
```swift
class WCSessionManager: NSObject {
    static let shared = WCSessionManager()

    private let session = WCSession.default
    private var flutterApi: SettingsFlutterApi?

    private let defaults = UserDefaults.standard
    private let settingsKey = "app_settings"
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

以下では、設定を watchOS 側に送信する処理を記述しています。
`session.updateApplicationContext`の処理は、watchOS 側で定義した内容と同じになっています。
iOS から watchOS に送信する場合も`updateApplicationContext`を用います。
watchOSの場合と同様に、`isReachable`のチェックは不要で、連続して送信すると、古いデータは自動的に上書きされ、最後の値のみが送信されます。
```swift
func updateSettings(settings: SettingsData) throws {
    saveSettings(settings)

    let context: [String: Any] = [
        "color": settings.color,
        "fontSize": settings.fontSize,
        "notificationEnabled": settings.notificationEnabled,
        "lastUpdated": settings.lastUpdated
    ]

    do {
        try session.updateApplicationContext(context)
    } catch {
        print("Failed to update application context: \(error)")
        throw error
    }
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
            print("Error: \(error.localizedDescription)")
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

以下では、watchOS から設定を受け取った際の挙動を定義しています。
`didReceiveApplicationContext`で設定を受け取り、Flutter 側に通知しています。
これで、設定の値を watchOS から受け取り、Flutter へ送る流れができます。
```swift
func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String : Any]
) {
    guard let color = applicationContext["color"] as? Int,
          let fontSize = applicationContext["fontSize"] as? Int,
          let notificationEnabled = applicationContext["notificationEnabled"] as? Bool,
          let lastUpdated = applicationContext["lastUpdated"] as? Double else {
        print("Invalid context format")
        return
    }

    let settings = SettingsData(
        color: Int64(color),
        fontSize: Int64(fontSize),
        notificationEnabled: notificationEnabled,
        lastUpdated: lastUpdated
    )
    saveSettings(settings)
    notifyFlutter(settings: settings)
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
    let settingsHostApi = SettingsHostApiImpl(sessionManager: sessionManager)
    SettingsHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: settingsHostApi)

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
let settingsHostApi = SettingsHostApiImpl(sessionManager: sessionManager)
SettingsHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: settingsHostApi)
```
これで iOS と watchOS 間のデータのやり取りの実装は完了です。

## iOS と Flutter 間のデータのやり取り
次に iOS と Flutter 間のデータのやり取りを実装します。
iOS と Flutter 間の通信は全体の中では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/c4bdd3838fad-20251129.png)

以下の手順で進めていきます。
1. Pigeon API の定義
2. Service 層の定義
3. Provider の定義
4. UI の作成

### 1. Pigeon API の定義
まず、Flutter と iOS 間の通信を行うための Pigeon API を定義します。
コードは以下の通りです。
```dart: lib/pigeon/settings_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon/settings_api.g.dart',
    swiftOut: 'ios/Runner/Pigeon/SettingsApi.g.swift',
  ),
)
class SettingsData {
  final int color;
  final int fontSize;
  final bool notificationEnabled;
  final double lastUpdated;

  SettingsData({
    required this.color,
    required this.fontSize,
    required this.notificationEnabled,
    required this.lastUpdated,
  });
}

@HostApi()
abstract class SettingsHostApi {
  @TaskQueue(type: TaskQueueType.serial)
  void updateSettings(SettingsData settings);

  @TaskQueue(type: TaskQueueType.serial)
  SettingsData getCurrentSettings();

  @TaskQueue(type: TaskQueueType.serial)
  bool isWatchReachable();
}

@FlutterApi()
abstract class SettingsFlutterApi {
  @TaskQueue(type: TaskQueueType.serial)
  void onSettingsUpdated(SettingsData settings);

  @TaskQueue(type: TaskQueueType.serial)
  void onReachabilityChanged(bool isReachable);
}
```

以下では、設定データを表すクラスを定義しています。
`SettingsData`は、テーマカラー、フォントサイズ、通知設定、最終更新時刻を保持します。
```dart
class SettingsData {
  final int color;
  final int fontSize;
  final bool notificationEnabled;
  final double lastUpdated;

  SettingsData({
    required this.color,
    required this.fontSize,
    required this.notificationEnabled,
    required this.lastUpdated,
  });
}
```

以下では、Flutter から iOS に対して実行する処理を記述しています。
Flutter から各プラットフォームに対して実行する処理は`@HostApi()`アノテーションをつけて、`abstract`つまり抽象クラスとしてまとめて定義します。
Flutter 側からは以下の三つのメソッドを呼び出したいのでそれぞれ定義しています。
- 設定の更新
- 現在の設定の取得
- Apple Watch との接続状態の確認

```dart
@HostApi()
abstract class SettingsHostApi {
  @TaskQueue(type: TaskQueueType.serial)
  void updateSettings(SettingsData settings);

  @TaskQueue(type: TaskQueueType.serial)
  SettingsData getCurrentSettings();

  @TaskQueue(type: TaskQueueType.serial)
  bool isWatchReachable();
}
```

以下では iOS から Flutter に対して実行する処理を記述しています。上記の`@HostApi()`の逆です。
iOS から Flutter へは以下の二つのメソッドを呼び出したいのでそれぞれ定義しています。

- 設定の更新通知
- 接続状態の変更通知

```dart
@FlutterApi()
abstract class SettingsFlutterApi {
  @TaskQueue(type: TaskQueueType.serial)
  void onSettingsUpdated(SettingsData settings);

  @TaskQueue(type: TaskQueueType.serial)
  void onReachabilityChanged(bool isReachable);
}
```

### 2. Service 層の定義
次に、Flutter 側で iOS とのやり取りを行うサービスの定義をしていきます。
コードは以下の通りです。
```dart: lib/services/watch_connectivity_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_watch/models/app_settings.dart';
import 'package:flutter_watch/pigeon/settings_api.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_connectivity_service.g.dart';

@riverpod
WatchConnectivityService watchConnectivityService(Ref ref) {
  return WatchConnectivityService();
}

class WatchConnectivityService implements SettingsFlutterApi {
  final SettingsHostApi _hostApi = SettingsHostApi();
  Function(AppSettings)? settingsUpdatedCallback;
  Function(bool)? reachabilityChangedCallback;

  WatchConnectivityService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    SettingsFlutterApi.setUp(this);
  }

  @override
  void onSettingsUpdated(SettingsData settings) {
    try {
      final appSettings = AppSettings.fromPigeon(settings);
      settingsUpdatedCallback?.call(appSettings);
    } catch (e) {
      debugPrint('Flutter: Error handling settings update: $e');
    }
  }

  @override
  void onReachabilityChanged(bool isReachable) {
    try {
      reachabilityChangedCallback?.call(isReachable);
    } catch (e) {
      debugPrint('Flutter: Error handling reachability change: $e');
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    try {
      _hostApi.updateSettings(settings.toPigeon());
    } catch (e) {
      debugPrint('Flutter: Failed to update settings: $e');
      rethrow;
    }
  }

  Future<AppSettings> getCurrentSettings() async {
    try {
      final settingsData = await _hostApi.getCurrentSettings();
      return AppSettings.fromPigeon(settingsData);
    } catch (e) {
      debugPrint('Flutter: Failed to get current settings: $e');
      rethrow;
    }
  }

  Future<bool> isWatchReachable() async {
    try {
      final isReachable = await _hostApi.isWatchReachable();
      return isReachable;
    } catch (e) {
      debugPrint('Flutter: Failed to check reachability: $e');
      return false;
    }
  }
}
```

以下では、iOS と設定に関する通信を行うための Service を定義しています。
また、初期化の段階で`_setupFlutterApi`メソッドを実行しています。
```dart
class WatchConnectivityService implements SettingsFlutterApi {
  final SettingsHostApi _hostApi = SettingsHostApi();
  Function(AppSettings)? settingsUpdatedCallback;
  Function(bool)? reachabilityChangedCallback;

  WatchConnectivityService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    SettingsFlutterApi.setUp(this);
  }
```

以下では、iOS から設定が更新された際の処理を記述しています。
`onSettingsUpdated`で設定を受け取り、コールバックを呼び出しています。
```dart
@override
void onSettingsUpdated(SettingsData settings) {
  try {
    final appSettings = AppSettings.fromPigeon(settings);
    settingsUpdatedCallback?.call(appSettings);
  } catch (e) {
    debugPrint('Flutter: Error handling settings update: $e');
  }
}
```

以下では、Pigeon の HostApi で`updateSettings`イベントを送信して、iOS 側の設定を更新するためのメソッドを実装しています。
```dart
Future<void> updateSettings(AppSettings settings) async {
  try {
    _hostApi.updateSettings(settings.toPigeon());
  } catch (e) {
    debugPrint('Flutter: Failed to update settings: $e');
    rethrow;
  }
}
```

### 3. Provider の定義
次に Flutter 側で必要な Provider の定義をしていきます。
コードは以下の通りです。
```dart: lib/providers/settings_provider.dart
import 'package:flutter_watch/models/app_settings.dart';
import 'package:flutter_watch/services/watch_connectivity_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  @override
  AppSettings build() {
    final service = ref.watch(watchConnectivityServiceProvider);
    service.settingsUpdatedCallback = (settings) {
      state = settings;
    };

    return const AppSettings();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      state = newSettings;
      final service = ref.read(watchConnectivityServiceProvider);
      await service.updateSettings(newSettings);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateColor(ThemeColor color) async {
    final newSettings = state.copyWith(
      themeColor: color,
      lastUpdated: DateTime.now(),
    );
    await updateSettings(newSettings);
  }

  Future<void> updateFontSize(FontSize fontSize) async {
    final newSettings = state.copyWith(
      fontSize: fontSize,
      lastUpdated: DateTime.now(),
    );
    await updateSettings(newSettings);
  }

  Future<void> updateNotification(bool enabled) async {
    final newSettings = state.copyWith(
      notificationEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    await updateSettings(newSettings);
  }
}

@riverpod
class WatchReachable extends _$WatchReachable {
  @override
  bool build() {
    final service = ref.watch(watchConnectivityServiceProvider);
    service.reachabilityChangedCallback = (isReachable) {
      state = isReachable;
    };

    _checkReachability();

    return false;
  }

  Future<void> _checkReachability() async {
    final service = ref.read(watchConnectivityServiceProvider);
    final isReachable = await service.isWatchReachable();
    state = isReachable;
  }

  Future<void> refresh() async {
    await _checkReachability();
  }
}
```

以下では、設定の状態を管理する Provider を定義しています。
`build`メソッドで、Service のコールバックを設定し、設定が更新された際に状態を更新するようにしています。
```dart
@riverpod
class Settings extends _$Settings {
  @override
  AppSettings build() {
    final service = ref.watch(watchConnectivityServiceProvider);
    service.settingsUpdatedCallback = (settings) {
      state = settings;
    };

    return const AppSettings();
  }
```

以下では、設定を更新するメソッドを実装しています。
まず、状態を更新し、その後 Service を通じて iOS 側に設定を送信しています。
```dart
Future<void> updateSettings(AppSettings newSettings) async {
  try {
    state = newSettings;
    final service = ref.read(watchConnectivityServiceProvider);
    await service.updateSettings(newSettings);
  } catch (e) {
    rethrow;
  }
}
```

### 4. UI の作成
次に UI を作成していきます。
コードは以下の通りです。
```dart: lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_watch/models/app_settings.dart';
import 'package:flutter_watch/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isReachable = ref.watch(watchReachableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: DefaultTextStyle(
        style: TextStyle(
          fontSize: settings.fontSize.points,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        child: ListView(
          children: [
            ConnectionStatusWidget(
              isReachable: isReachable,
              fontSize: settings.fontSize,
            ),
            const Divider(),
            ColorSectionWidget(settings: settings, fontSize: settings.fontSize),
            const Divider(),
            FontSizeSectionWidget(settings: settings),
            const Divider(),
            NotificationSectionWidget(
              settings: settings,
              fontSize: settings.fontSize,
            ),
            const Divider(),
            LastUpdatedSectionWidget(
              settings: settings,
              fontSize: settings.fontSize,
            ),
          ],
        ),
      ),
    );
  }
}
```

以下では、設定画面の UI を実装しています。
各セクションで設定を変更できるようになっており、設定が変更されると自動的に iOS 側に送信され、watchOS 側にも反映されます。

```dart
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isReachable = ref.watch(watchReachableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // 接続状態の表示
          // テーマカラーの選択
          // フォントサイズの選択
          // 通知設定
          // 最終更新時刻
        ],
      ),
    );
  }
}
```

これで、watchOS、iOS、Flutter を繋ぐ設定アプリの実装が完了しました。

## まとめ
この章では、`updateApplicationContext`を使って設定データを同期するアプリを実装しました。
`updateApplicationContext`の特徴をまとめると以下のようになります。

- 最新データのみが保持される
- バックグラウンドでも動作する
- 到達可能性のチェックが不要
- 設定値などの同期に適している

## 参考

