## 初めに
実践編の目的は、基礎編で扱った技術をさらに深掘りしたり、別の実装方法を紹介することです。
【基礎編-1】MethodChannelでは、Method Channelを使ってFlutterと各プラットフォーム間でメッセージのやり取りを行う方法についてまとめました。しかし、Method Channelをそのまま使用する以外にPigeonパッケージを使用する実装方法があります。
【基礎編-2】WCSessionでは、WCSessionを用いてiPhoneとApple Watchとの連絡を行う方法についてまとめました。この章では`sendMessage`メソッドのみについて触れましたが、iPhoneとApple Watchとの連絡方法には他の方法があります。
このように基礎編では触れていない部分を深掘りしたり、新たなパッケージを導入して実装することが実践編の目的です。

### この章でできるようになること
- Pigeonを使った型安全な通信方法を理解する
- Method ChannelからPigeonへの移行方法を学ぶ

## Pigeon
### Pigeonとは
Pigeonは、Flutterと各プラットフォーム間の通信を型安全に行うためパッケージです。
Dart側でメソッドを用意して、それをもとにインターフェースを生成することができます。
生成されたコードを通じて、Flutterと各プラットフォーム間の通信を行うことができます。

### なぜPigeonを使うのか
基礎編-1ではMethod Channelを使った実装を行いました。Method Channelは十分に機能しますが、以下のような課題があります。

#### Method Channelの課題
- 型安全性が保証されない（実行時にエラーが発生する可能性がある）
- メソッド名や引数の型を文字列で指定するため、タイプミスが発生しやすい
- インターフェースの定義が分散し、管理が難しい

#### Pigeonのメリット
- 型安全性が保証される（コンパイル時にエラーを検出できる）
- インターフェースを一箇所で定義できる
- 自動生成されるコードにより、実装の一貫性が保たれる

#### 具体例
Method Channelの場合
```dart
// タイプミスがあってもコンパイル時には検出されない
await methodChannel.invokeMethod('counterUpdte', counter); // 'counterUpdate'のタイプミス
````

Pigeon の場合
```dart
// コンパイル時にエラーが検出される
await hostApi.sendCounter(CounterRequest(counter: counter)); // 型が明確
```

## 実装
### Method Channelからの書き換え
この章では、【基礎編-1】MethodChannelで扱ったカウンターの実装をPigeonで書き換えてみます。
リポジトリの`basic-2/counter`ブランチから、新たに`practice-1/counter_pigeon`ブランチを作成して、実装を書き換える形で進めていきます。

書き換えの流れは以下の通りです。
1. パッケージ導入
2. インターフェース生成元ファイル作成
3. Swift側の修正
4. Flutter側の修正

#### 1. パッケージ導入
まずはプロジェクトに[pigeon](https://pub.dev/packages/pigeon)パッケージを追加します。
`pubspec.yaml`にpigeonパッケージの最新バージョンを追加します。
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  pigeon: ^26.0.2
```

`pubspec.yaml`に追記できたら以下コマンドを実行して、パッケージ導入は完了です。
```
flutter pub get
```

#### 2. インターフェース生成元ファイル作成
次にFlutterとSwiftを繋ぐインターフェースを作成します。
Method Channelを用いた実装では、`counterUpdated`や`sessionStateChanged`などのメソッドを定義してやり取りをしていました。
この章ではそれらの処理をpigeonで実装し直していきます。

`lib/pigeons`ディレクトリに`watch_communication_api.dart`ファイルを作成し、そこでインターフェースを定義します。
コードは以下の通りです。以下でそれぞれ詳しくみていきます。
```dart: lib/pigeons/watch_communication_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeons/watch_communication_api.g.dart',
    swiftOut: 'ios/Runner/WatchCommunicationApi.g.swift',
  ),
)

// カウンター送信のリクエスト
class CounterRequest {
  final int counter;

  CounterRequest({required this.counter});
}

// カウンター送信の結果
class CounterResult {
  final bool success;

  CounterResult({required this.success});
}

// カウンター更新のイベント
class CounterUpdateEvent {
  final int counter;

  CounterUpdateEvent({required this.counter});
}

// セッション初期化の結果
class SessionInitializeResult {
  final bool success;
  final String statusKey;

  SessionInitializeResult({required this.success, required this.statusKey});
}

// セッション状態変更のイベント
class SessionStateEvent {
  final String statusKey;

  SessionStateEvent({required this.statusKey});
}

// Flutter → iOS の呼び出し (HostApi)
@HostApi()
abstract class WatchCommunicationHostApi {
  @async
  SessionInitializeResult initializeSession();

  @async
  CounterResult sendCounter(CounterRequest request);
}

// iOS → Flutter の呼び出し (FlutterApi)
@FlutterApi()
abstract class WatchCommunicationFlutterApi {
  void onSessionStateChanged(SessionStateEvent event);
  void onCounterUpdated(CounterUpdateEvent event);
}
```

以下では、名前の通りPigeonの設定を行なっています。
ここでは生成するファイルの出力先を定義しています。
今回はFlutter x Apple Watchなので、`dartOut`と`swiftOut`のみ定義していますが、Android向けのインターフェースを作成する場合には出力先として`kotlinOut`や`javaOut`などを設定することもできます。
```dart
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeons/watch_communication_api.g.dart',
    swiftOut: 'ios/Runner/WatchCommunicationApi.g.swift',
  ),
)
```

以下ではカウンターに関するクラスを定義しています。
`CounterRequest`は、FlutterからiOSに対してカウンターの値を送信する際に使用します。
`CounterResult`は上記の`CounterRequest`を送信した際の返り値で、処理が成功したかどうかを返却します。
`CounterUpdateEvent`は、iOSからFlutterに対してカウンターの値を送信する際に使用します。
```dart
// カウンター送信のリクエスト
class CounterRequest {
  final int counter;

  CounterRequest({required this.counter});
}

// カウンター送信の結果
class CounterResult {
  final bool success;

  CounterResult({required this.success});
}

// カウンター更新のイベント
class CounterUpdateEvent {
  final int counter;

  CounterUpdateEvent({required this.counter});
}
```

以下では、セッションに関するクラスを定義しています。
`SessionInitializeResult`は、iPhoneとApple Watchとのセッション初期化時に、初期化が成功したかどうかやセッションのステータスをFlutter側に通知するために使用します。
`SessionStateEvent`は、iPhoneとApple Watchとのセッションの状態が変化した際に、Flutter側にそのステータスを通知するために使用します。
```dart
// セッション初期化の結果
class SessionInitializeResult {
  final bool success;
  final String statusKey;

  SessionInitializeResult({required this.success, required this.statusKey});
}

// セッション状態変更のイベント
class SessionStateEvent {
  final String statusKey;

  SessionStateEvent({required this.statusKey});
}
```

以下ではコメントにある通り、FlutterからiOSに対して実行する処理を記述しています。
Flutterから各プラットフォームに対して実行する処理は`@HostApi()`アノテーションをつけて、`abstract`つまり抽象クラスとしてまとめて定義します。
Flutter側からは以下の二つのメソッドを呼び出したいのでそれぞれ定義しています。
- iPhoneとApple Watchとのセッションの初期化
- Flutter側で受け取ったカウンターの値変更

なお、二つのメソッドは非同期で呼び出したいので、`@async`として定義しています。
```dart
// Flutter → iOS の呼び出し (HostApi)
@HostApi()
abstract class WatchCommunicationHostApi {
  @async
  SessionInitializeResult initializeSession();

  @async
  CounterResult sendCounter(CounterRequest request);
}
```

以下ではiOSからFlutterに対して実行する処理を記述しています。上記の`@HostApi()`の逆です。
iOSからFlutterへは以下の二つのメソッドを呼び出したいのでそれぞれ定義しています。
- iPhoneとApple Watchとのセッション状態の変化
- Apple Watch側で受け取ったカウンターの値の変更
```dart
// iOS → Flutter の呼び出し (FlutterApi)
@FlutterApi()
abstract class WatchCommunicationFlutterApi {
  void onSessionStateChanged(SessionStateEvent event);
  void onCounterUpdated(CounterUpdateEvent event);
}
```

これで生成元のファイルは作成できたので、ルートディレクトリで以下のコマンドを実行します。
```
dart run pigeon --input <生成元のdartファイルのパス>
```

今回のファイルのパスは`lib/pigeons/watch_communication_api.dart`なので、以下のようなコマンドになります。
```
dart run pigeon --input lib/pigeons/watch_communication_api.dart
```

コマンドを実行するとそれぞれ以下のようなファイルが生成されます。
:::details lib/pigeons/watch_communication_api.g.dart
```dart: lib/pigeons/watch_communication_api.g.dart
// Autogenerated from Pigeon (v22.7.2), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

PlatformException _createConnectionError(String channelName) {
  return PlatformException(
    code: 'channel-error',
    message: 'Unable to establish connection on channel: "$channelName".',
  );
}

List<Object?> wrapResponse({Object? result, PlatformException? error, bool empty = false}) {
  if (empty) {
    return <Object?>[];
  }
  if (error == null) {
    return <Object?>[result];
  }
  return <Object?>[error.code, error.message, error.details];
}

class SessionInitializeResult {
  SessionInitializeResult({
    required this.success,
    required this.statusKey,
  });

  bool success;

  String statusKey;

  Object encode() {
    return <Object?>[
      success,
      statusKey,
    ];
  }

  static SessionInitializeResult decode(Object result) {
    result as List<Object?>;
    return SessionInitializeResult(
      success: result[0]! as bool,
      statusKey: result[1]! as String,
    );
  }
}

class CounterRequest {
  CounterRequest({
    required this.counter,
  });

  int counter;

  Object encode() {
    return <Object?>[
      counter,
    ];
  }

  static CounterRequest decode(Object result) {
    result as List<Object?>;
    return CounterRequest(
      counter: result[0]! as int,
    );
  }
}

class CounterResult {
  CounterResult({
    required this.success,
  });

  bool success;

  Object encode() {
    return <Object?>[
      success,
    ];
  }

  static CounterResult decode(Object result) {
    result as List<Object?>;
    return CounterResult(
      success: result[0]! as bool,
    );
  }
}

class SessionStateEvent {
  SessionStateEvent({
    required this.statusKey,
  });

  String statusKey;

  Object encode() {
    return <Object?>[
      statusKey,
    ];
  }

  static SessionStateEvent decode(Object result) {
    result as List<Object?>;
    return SessionStateEvent(
      statusKey: result[0]! as String,
    );
  }
}

class CounterUpdateEvent {
  CounterUpdateEvent({
    required this.counter,
  });

  int counter;

  Object encode() {
    return <Object?>[
      counter,
    ];
  }

  static CounterUpdateEvent decode(Object result) {
    result as List<Object?>;
    return CounterUpdateEvent(
      counter: result[0]! as int,
    );
  }
}


class _PigeonCodec extends StandardMessageCodec {
  const _PigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is int) {
      buffer.putUint8(4);
      buffer.putInt64(value);
    }    else if (value is SessionInitializeResult) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    }    else if (value is CounterRequest) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    }    else if (value is CounterResult) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    }    else if (value is SessionStateEvent) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    }    else if (value is CounterUpdateEvent) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129:
        return SessionInitializeResult.decode(readValue(buffer)!);
      case 130:
        return CounterRequest.decode(readValue(buffer)!);
      case 131:
        return CounterResult.decode(readValue(buffer)!);
      case 132:
        return SessionStateEvent.decode(readValue(buffer)!);
      case 133:
        return CounterUpdateEvent.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class WatchCommunicationHostApi {
  /// Constructor for [WatchCommunicationHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  WatchCommunicationHostApi({BinaryMessenger? binaryMessenger, String messageChannelSuffix = ''})
      : pigeonVar_binaryMessenger = binaryMessenger,
        pigeonVar_messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
  final BinaryMessenger? pigeonVar_binaryMessenger;

  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  final String pigeonVar_messageChannelSuffix;

  Future<SessionInitializeResult> initializeSession() async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_watch.WatchCommunicationHostApi.initializeSession$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else if (pigeonVar_replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (pigeonVar_replyList[0] as SessionInitializeResult?)!;
    }
  }

  Future<CounterResult> sendCounter(CounterRequest request) async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_watch.WatchCommunicationHostApi.sendCounter$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[request]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else if (pigeonVar_replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (pigeonVar_replyList[0] as CounterResult?)!;
    }
  }
}

abstract class WatchCommunicationFlutterApi {
  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  void onSessionStateChanged(SessionStateEvent event);

  void onCounterUpdated(CounterUpdateEvent event);

  static void setUp(WatchCommunicationFlutterApi? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
    messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onSessionStateChanged$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onSessionStateChanged was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final SessionStateEvent? arg_event = (args[0] as SessionStateEvent?);
          assert(arg_event != null,
              'Argument for dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onSessionStateChanged was null, expected non-null SessionStateEvent.');
          try {
            api.onSessionStateChanged(arg_event!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onCounterUpdated$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onCounterUpdated was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final CounterUpdateEvent? arg_event = (args[0] as CounterUpdateEvent?);
          assert(arg_event != null,
              'Argument for dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onCounterUpdated was null, expected non-null CounterUpdateEvent.');
          try {
            api.onCounterUpdated(arg_event!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }
}
```
:::

:::details ios/Runner/WatchCommunicationApi.g.swift
```swift: ios/Runner/WatchCommunicationApi.g.swift
// Autogenerated from Pigeon (v22.7.2), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Error class for passing custom error details to Dart side.
final class PigeonError: Error {
  let code: String
  let message: String?
  let details: Any?

  init(code: String, message: String?, details: Any?) {
    self.code = code
    self.message = message
    self.details = details
  }

  var localizedDescription: String {
    return
      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
      }
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let pigeonError = error as? PigeonError {
    return [
      pigeonError.code,
      pigeonError.message,
      pigeonError.details,
    ]
  }
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details,
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)",
  ]
}

private func createConnectionError(withChannelName channelName: String) -> PigeonError {
  return PigeonError(code: "channel-error", message: "Unable to establish connection on channel: '\(channelName)'.", details: "")
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

/// Generated class from Pigeon that represents data sent in messages.
struct SessionInitializeResult {
  var success: Bool
  var statusKey: String


  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> SessionInitializeResult? {
    let success = pigeonVar_list[0] as! Bool
    let statusKey = pigeonVar_list[1] as! String

    return SessionInitializeResult(
      success: success,
      statusKey: statusKey
    )
  }
  func toList() -> [Any?] {
    return [
      success,
      statusKey,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct CounterRequest {
  var counter: Int64


  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> CounterRequest? {
    let counter = pigeonVar_list[0] as! Int64

    return CounterRequest(
      counter: counter
    )
  }
  func toList() -> [Any?] {
    return [
      counter
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct CounterResult {
  var success: Bool


  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> CounterResult? {
    let success = pigeonVar_list[0] as! Bool

    return CounterResult(
      success: success
    )
  }
  func toList() -> [Any?] {
    return [
      success
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct SessionStateEvent {
  var statusKey: String


  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> SessionStateEvent? {
    let statusKey = pigeonVar_list[0] as! String

    return SessionStateEvent(
      statusKey: statusKey
    )
  }
  func toList() -> [Any?] {
    return [
      statusKey
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct CounterUpdateEvent {
  var counter: Int64


  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> CounterUpdateEvent? {
    let counter = pigeonVar_list[0] as! Int64

    return CounterUpdateEvent(
      counter: counter
    )
  }
  func toList() -> [Any?] {
    return [
      counter
    ]
  }
}

private class WatchCommunicationApiPigeonCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
    case 129:
      return SessionInitializeResult.fromList(self.readValue() as! [Any?])
    case 130:
      return CounterRequest.fromList(self.readValue() as! [Any?])
    case 131:
      return CounterResult.fromList(self.readValue() as! [Any?])
    case 132:
      return SessionStateEvent.fromList(self.readValue() as! [Any?])
    case 133:
      return CounterUpdateEvent.fromList(self.readValue() as! [Any?])
    default:
      return super.readValue(ofType: type)
    }
  }
}

private class WatchCommunicationApiPigeonCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? SessionInitializeResult {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? CounterRequest {
      super.writeByte(130)
      super.writeValue(value.toList())
    } else if let value = value as? CounterResult {
      super.writeByte(131)
      super.writeValue(value.toList())
    } else if let value = value as? SessionStateEvent {
      super.writeByte(132)
      super.writeValue(value.toList())
    } else if let value = value as? CounterUpdateEvent {
      super.writeByte(133)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class WatchCommunicationApiPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return WatchCommunicationApiPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return WatchCommunicationApiPigeonCodecWriter(data: data)
  }
}

class WatchCommunicationApiPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = WatchCommunicationApiPigeonCodec(readerWriter: WatchCommunicationApiPigeonCodecReaderWriter())
}


/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol WatchCommunicationHostApi {
  func initializeSession(completion: @escaping (Result<SessionInitializeResult, Error>) -> Void)
  func sendCounter(request: CounterRequest, completion: @escaping (Result<CounterResult, Error>) -> Void)
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class WatchCommunicationHostApiSetup {
  static var codec: FlutterStandardMessageCodec { WatchCommunicationApiPigeonCodec.shared }
  /// Sets up an instance of `WatchCommunicationHostApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: WatchCommunicationHostApi?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    let initializeSessionChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_watch.WatchCommunicationHostApi.initializeSession\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      initializeSessionChannel.setMessageHandler { _, reply in
        api.initializeSession { result in
          switch result {
          case .success(let res):
            reply(wrapResult(res))
          case .failure(let error):
            reply(wrapError(error))
          }
        }
      }
    } else {
      initializeSessionChannel.setMessageHandler(nil)
    }
    let sendCounterChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_watch.WatchCommunicationHostApi.sendCounter\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      sendCounterChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let requestArg = args[0] as! CounterRequest
        api.sendCounter(request: requestArg) { result in
          switch result {
          case .success(let res):
            reply(wrapResult(res))
          case .failure(let error):
            reply(wrapError(error))
          }
        }
      }
    } else {
      sendCounterChannel.setMessageHandler(nil)
    }
  }
}
/// Generated protocol from Pigeon that represents Flutter messages that can be called from Swift.
protocol WatchCommunicationFlutterApiProtocol {
  func onSessionStateChanged(event eventArg: SessionStateEvent, completion: @escaping (Result<Void, PigeonError>) -> Void)
  func onCounterUpdated(event eventArg: CounterUpdateEvent, completion: @escaping (Result<Void, PigeonError>) -> Void)
}
class WatchCommunicationFlutterApi: WatchCommunicationFlutterApiProtocol {
  private let binaryMessenger: FlutterBinaryMessenger
  private let messageChannelSuffix: String
  init(binaryMessenger: FlutterBinaryMessenger, messageChannelSuffix: String = "") {
    self.binaryMessenger = binaryMessenger
    self.messageChannelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
  }
  var codec: WatchCommunicationApiPigeonCodec {
    return WatchCommunicationApiPigeonCodec.shared
  }
  func onSessionStateChanged(event eventArg: SessionStateEvent, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onSessionStateChanged\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([eventArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
  func onCounterUpdated(event eventArg: CounterUpdateEvent, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onCounterUpdated\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([eventArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
}
```
:::

FlutterとSwiftでそれぞれ生成されたファイルを見てみます。

Flutter側では以下のような処理があります。（簡略化のため一部省略しています）
内容を見てみると、`BasicMessageChannel`の`setMessageHandler`を通じてSwift側からメッセージを受け取り、`onCounterUpdated`を実行していることがわかります。
これで、Swift側からイベントを受け取り、そのメッセージに応じた処理ができるようになっています。
```dart: lib/pigeons/watch_communication_api.g.dart
static void setUp(WatchCommunicationFlutterApi? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
  messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
  {
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_watch.WatchCommunicationFlutterApi.onCounterUpdated$messageChannelSuffix', pigeonChannelCodec,
        binaryMessenger: binaryMessenger);
      pigeonVar_channel.setMessageHandler((Object? message) async {
        final List<Object?> args = (message as List<Object?>?)!;
        final CounterUpdateEvent? arg_event = (args[0] as CounterUpdateEvent?);
          api.onCounterUpdated(arg_event!);
  }
}
```

Swift側では以下のような処理があります。
`FlutterBasicMessageChannel`の`setMessageHandler`を使って、Flutterからの呼び出しを処理しています。
Method Channelを用いた下の実装と生成されたコードを比較すると、使用しているMethod Channel等の違いはありますが、基本的には同じ処理を行なっていることがわかります。
```swift: ios/Runner/WatchCommunicationApi.g.swift
static func setUp(binaryMessenger: FlutterBinaryMessenger, api: WatchCommunicationHostApi?, messageChannelSuffix: String = "") {

  let sendCounterChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_watch.WatchCommunicationHostApi.sendCounter\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)

  sendCounterChannel.setMessageHandler { message, reply in
    let args = message as! [Any?]
    let requestArg = args[0] as! CounterRequest
    api.sendCounter(request: requestArg) { result in
      switch result {
        case .success(let res):
          reply(wrapResult(res))
        }
      }
    }
}

// Method Channelを用いた以前の実装
let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
let counterChannel = FlutterMethodChannel(
  name: "flutter_watch/counter",
  binaryMessenger: controller.binaryMessenger
)
counterChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
  switch call.method {
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
}
```

#### 3. Swift側の修正
次にSwift側の修正を行います。
Swift側では、`AppDelegate.swift`と`WCSessionManager.swift`の修正を行います。

`AppDelegate.swift`は以下の通りです。
それぞれ詳しく見ていきます。
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

    // PigeonのFlutterAPIを初期化
    let flutterApi = WatchCommunicationFlutterApi(binaryMessenger: controller.binaryMessenger)

    // WCSessionManagerを初期化
    wcSessionManager = WCSessionManager(flutterApi: flutterApi)

    // PigeonのHostAPIを設定
    let hostApi = WatchCommunicationHostApiImpl(wcSessionManager: wcSessionManager!)
    WatchCommunicationHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: hostApi)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// PigeonのHostAPIの実装
class WatchCommunicationHostApiImpl: NSObject, WatchCommunicationHostApi {
    private let wcSessionManager: WCSessionManager

    init(wcSessionManager: WCSessionManager) {
        self.wcSessionManager = wcSessionManager
    }

    func initializeSession(completion: @escaping (Result<SessionInitializeResult, Error>) -> Void) {
        wcSessionManager.initializeSession { result in
            completion(.success(result))
        }
    }

    func sendCounter(request: CounterRequest, completion: @escaping (Result<CounterResult, Error>) -> Void) {
        wcSessionManager.sendCounterValue(request.counter) { result in
            completion(.success(result))
        }
    }
}
```

以下では、`FlutterViewController`の`binaryMessenger`を`WatchCommunicationFlutterApi`に渡して、SwiftからFlutterへイベントを送信する際に使用するAPIを初期化しています。
また、今回はApple Watchからカウンターの値やセッションの状態を送信するため、`WCSessionManager`に`flutterApi`を渡しています。
```swift
let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
// PigeonのFlutterAPIを初期化
let flutterApi = WatchCommunicationFlutterApi(binaryMessenger: controller.binaryMessenger)
// WCSessionManagerを初期化
wcSessionManager = WCSessionManager(flutterApi: flutterApi)
```

以下では、Flutterから受け取ったイベントを処理する`WatchCommunicationHostApiSetup`を初期化しています。先ほど取り上げた`setUp`メソッドが実行されており、ここでそれぞれのMethod Channelの定義が行われています。
また、`hostApi`として`WatchCommunicationHostApiImpl`を定義して、`WatchCommunicationHostApiSetup`に渡しています。
```swift
// PigeonのHostAPIを設定
let hostApi = WatchCommunicationHostApiImpl(wcSessionManager: wcSessionManager!)
WatchCommunicationHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: hostApi)
```

以下では、`WatchCommunicationHostApiImpl`の実装を行なっています。
`WatchCommunicationHostApiImpl`は`WatchCommunicationHostApi`を継承いるため、`initializeSession`, `sendCounter` の二つのメソッドを実装する必要があります。

先述の通り、今回はApple WatchからFlutterへ送信するイベントのみなので、Flutterからのイベントを受け取り次第、`WCSessionManager`に定義してあるメソッドを実行しています。
`sendCounter`の場合は、Flutter側で値の変更を検知した時点で`sendCounter`メソッドが実行され、その中に含まれている`wcSessionManager.sendCounterValue`を通じてApple Watchにカウンターの値が送信されるという流れです。
```swift
// PigeonのHostAPIの実装
class WatchCommunicationHostApiImpl: NSObject, WatchCommunicationHostApi {
    private let wcSessionManager: WCSessionManager

    init(wcSessionManager: WCSessionManager) {
        self.wcSessionManager = wcSessionManager
    }

    func initializeSession(completion: @escaping (Result<SessionInitializeResult, Error>) -> Void) {
        wcSessionManager.initializeSession { result in
            completion(.success(result))
        }
    }

    func sendCounter(request: CounterRequest, completion: @escaping (Result<CounterResult, Error>) -> Void) {
        wcSessionManager.sendCounterValue(request.counter) { result in
            completion(.success(result))
        }
    }
}
```

`WCSessionManager.swift`は以下の通りです。
変更した部分を中心に見ていきます。
```swift: ios/Runner/WCSessionManager.swift
import WatchConnectivity
import Flutter

class WCSessionManager: NSObject {
    private let flutterApi: WatchCommunicationFlutterApi
    private var wcSession: WCSession?

    init(flutterApi: WatchCommunicationFlutterApi) {
        self.flutterApi = flutterApi
        super.init()
    }

    func initializeSession(completion: @escaping (SessionInitializeResult) -> Void) {
        guard WCSession.isSupported() else {
            completion(SessionInitializeResult(success: false, statusKey: "not_supported"))
            return
        }

        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let session = self?.wcSession else {
                completion(SessionInitializeResult(success: false, statusKey: "error"))
                return
            }

            let statusKey = self?.getSessionStatus(session) ?? "error"
            completion(SessionInitializeResult(success: session.isReachable, statusKey: statusKey))
        }
    }

    func sendCounterValue(_ counter: Int64, completion: @escaping (CounterResult) -> Void) {
        guard let session = wcSession else {
            completion(CounterResult(success: false))
            return
        }

        guard session.isReachable else {
            completion(CounterResult(success: false))
            return
        }

        let message = ["counter": counter]
        session.sendMessage(message, replyHandler: { response in
            completion(CounterResult(success: true))
        }, errorHandler: { error in
            completion(CounterResult(success: false))
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

// MARK: - WCSessionDelegate
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

            self?.flutterApi.onSessionStateChanged(
                event: SessionStateEvent(statusKey: statusKey),
                completion: { _ in }
            )
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.flutterApi.onSessionStateChanged(
                event: SessionStateEvent(statusKey: "not_reachable"),
                completion: { _ in }
            )
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.flutterApi.onSessionStateChanged(
                event: SessionStateEvent(statusKey: "error"),
                completion: { _ in }
            )
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.flutterApi.onCounterUpdated(
                    event: CounterUpdateEvent(counter: Int64(counter)),
                    completion: { _ in }
                )
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.flutterApi.onCounterUpdated(
                    event: CounterUpdateEvent(counter: Int64(counter)),
                    completion: { _ in }
                )
            }

            let reply = ["status": "received"] as [String : Any]
            replyHandler(reply)
        }
    }
}
```

以前の実装では、`FlutterMethodChannel`を受け取り、メソッドの内容も記述していましたが、今回の実装では`WatchCommunicationFlutterApi`を受け取るように修正しています。
以前はここでそれぞれのメソッドの内容も記述していましたが、今回はAPIに定義してあるメソッドを呼び出すだけで良くなっています。
```swift
// Before
private let methodChannel: FlutterMethodChannel
private var wcSession: WCSession?

init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
    super.init()
}

// After
private let flutterApi: WatchCommunicationFlutterApi
private var wcSession: WCSession?

init(flutterApi: WatchCommunicationFlutterApi) {
    self.flutterApi = flutterApi
    super.init()
}
```

各メソッドの実装に関しては、以前の実装では`(Bool, String)`のように用意されている型をそのまま使用していたのに対し、今回の実装では`SessionInitializeResult`型として扱うことができるようになっています。
```swift
// Before
func initializeSession(completion: @escaping (Bool, String) -> Void) {
    guard WCSession.isSupported() else {
        completion(false, "WCSession is not supported")
        return
    }

// After
func initializeSession(completion: @escaping (SessionInitializeResult) -> Void) {
    guard WCSession.isSupported() else {
        completion(SessionInitializeResult(success: false, statusKey: "not_supported"))
        return
    }
```

メソッドの呼び出しに関しては、`methodChannel.invokeMethod`を使用していたのに対し、`flutterApi`に用意されたメソッドを実行するようになっています。
`invokeMethod`ではメソッドの名前をFlutter側とSwift側で一致させる必要がありましたが、pigeonを使うことでその必要もなくなっています。
```swift
// Before
func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    DispatchQueue.main.async { [weak self] in
        if let counter = message["counter"] as? Int {
            self?.methodChannel.invokeMethod(
                "counterUpdated",
                arguments: ["counter": counter]
            )
        }
    }
}

// After
func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    DispatchQueue.main.async { [weak self] in
        if let counter = message["counter"] as? Int {
            self?.flutterApi.onCounterUpdated(
                event: CounterUpdateEvent(counter: Int64(counter)),
                completion: { _ in }
            )
        }
    }
}
```

#### 4. Flutter側の修正
次にFlutter側の修正に移ります。
Flutter側では主に`lib/providers/watch_communication_service_provider.dart`の修正を行います。コードは以下の通りです。
```dart: lib/providers/watch_communication_service_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_watch/models/watch_connection_status.dart';
import 'package:flutter_watch/models/watch_status_key.dart';
import 'package:flutter_watch/providers/connection_status_provider.dart';
import 'package:flutter_watch/providers/counter_provider.dart';
import 'package:flutter_watch/pigeons/watch_communication_api.g.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_communication_service_provider.g.dart';

@riverpod
WatchCommunicationService watchCommunicationService(
  Ref ref,
) {
  return WatchCommunicationService(ref);
}

class WatchCommunicationService extends WatchCommunicationFlutterApi {
  final Ref ref;
  late final WatchCommunicationHostApi _hostApi;

  WatchCommunicationService(this.ref) {
    _hostApi = WatchCommunicationHostApi();
    WatchCommunicationFlutterApi.setUp(this);
  }

  Future<void> initializeConnection() async {
    try {
      final result = await _hostApi.initializeSession();
      final status = _parseConnectionStatus(result.statusKey);
      ref.read(connectionStatusProvider.notifier).update(status);
    } on PlatformException {
      ref
          .read(connectionStatusProvider.notifier)
          .update(WatchConnectionStatus.error);
    }
  }

  Future<bool> updateCounter(int newValue) async {
    try {
      final result = await _hostApi.sendCounter(
        CounterRequest(counter: newValue),
      );
      return result.success;
    } on PlatformException catch (e) {
      debugPrint('📱 Send error: ${e.message}');
      rethrow;
    }
  }

  @override
  void onCounterUpdated(CounterUpdateEvent event) {
    ref.read(counterProvider.notifier).set(event.counter);
  }

  @override
  void onSessionStateChanged(SessionStateEvent event) {
    final status = _parseConnectionStatus(event.statusKey);
    ref.read(connectionStatusProvider.notifier).update(status);
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

以下では、`WatchCommunicationHostApi`を受け取って初期化しています。
以前の実装では、Flutter側のMethod Channelの登録なども行なっていましたが、`setUp`メソッドを実行することでまとめてできるようになっています。
```dart
class WatchCommunicationService extends WatchCommunicationFlutterApi {
  final Ref ref;
  late final WatchCommunicationHostApi _hostApi;

  WatchCommunicationService(this._ref) {
    _hostApi = WatchCommunicationHostApi();
    WatchCommunicationFlutterApi.setUp(this);
  }
```

以前の実装では、`platformChannel.invokeMethod`を実行してSwift側に通知を行なっていたのに対し、今回の実装では`_hostApi`に用意されたメソッドを実行するだけになっています。
```dart
// Before
Future<bool> updateCounter(int newValue) async {
  try {
    final success = await platformChannel.invokeMethod('sendCounter', {
      'counter': newValue,
    });

    return success == true;
  }

// After
Future<bool> updateCounter(int newValue) async {
  try {
    final result = await _hostApi.sendCounter(
      CounterRequest(counter: newValue),
    );
    return result.success;
  }
```

これでMethod Channelをそのまま使ったカウンターの実装から、pigeonを用いた実装に切り替えることができました。

