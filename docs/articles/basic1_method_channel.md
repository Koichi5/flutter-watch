## 初めに
この基礎編では、Method ChannelとWCSessionを使って、FlutterとApple Watch間でデータのやり取りをするアプリを作成していきます。
この基礎編の目的は、実際に動くアプリケーションを作成するのと同時に、Method ChannelやWCSessionがどのようにして動いているのかを理解していくことです。

### この章でできるようになること
- Method Channel を使って Flutter と iOS 間で通信する方法を理解する
- 実際に動作するカウンターアプリを実装する
- Platform Channel の仕組みを理解する

## Method Channelとは
Flutterアプリでは、Method Channelを使用することで、iOSやAndroidなどのプラットフォーム固有のコードを使用できます。
Flutter側の[Method Channel](https://api.flutter.dev/flutter/services/MethodChannel-class.html?_gl=1*1n90s58*_ga*MTcwNDUxMzQwMS4xNzU2OTkyOTk1*_ga_04YGWK0175*czE3NTY5OTI5OTQkbzEkZzEkdDE3NTY5OTMyNzgkajYwJGwwJGgw)では、プラットフォーム側にメソッド呼び出しに対応するメッセージを送信することができます。
Androidの[Method Channel](https://api.flutter.dev/javadoc/io/flutter/plugin/common/MethodChannel.html?_gl=1*11bvvgm*_ga*MTcwNDUxMzQwMS4xNzU2OTkyOTk1*_ga_04YGWK0175*czE3NTY5OTI5OTQkbzEkZzEkdDE3NTY5OTMyMTgkajE2JGwwJGgw)やiOSの[FlutterMethodChannel](https://api.flutter.dev/ios-embedder/interface_flutter_method_channel.html?_gl=1*11bvvgm*_ga*MTcwNDUxMzQwMS4xNzU2OTkyOTk1*_ga_04YGWK0175*czE3NTY5OTI5OTQkbzEkZzEkdDE3NTY5OTMyMTgkajE2JGwwJGgw)では、Flutter側からのメソッド呼び出しをプラットフォーム側で受信し、結果を返すことができます。

Flutterでは以下のようなプラットフォーム固有の言語がサポートされています。
| プラットフォーム | 言語 |
| ---- | ---- |
| Android | Kotlin、Java |
| iOS | Swift、Objective-C |
| Windows | C++ |
| macOS | Objective-C |
| Linux | C |

Flutter公式ドキュメント[Writing custom platform-specific code](https://docs.flutter.dev/platform-integration/platform-channels#architecture)の以下の図にある通り、Method Channelを使用してFlutterと各プラットフォーム間でメッセージの送受信ができます。
![](https://storage.googleapis.com/zenn-user-upload/808e6afaa668-20250831.png =500x)

前の章の図では以下の赤枠部分にあたります。
![](https://storage.googleapis.com/zenn-user-upload/43a507af9f67-20250913.png)

## Platform Channelとは
Flutterと各プラットフォームとの連絡やメッセージ送信には基本的にはMethod Channelを使用することが多いです。しかし、Method ChannelはFlutterと各プラットフォームの連携を行うPlatform Channel APIの一種であり、Method Channel以外にも非同期でバイナリーメッセージを送信してプラットフォームコードと通信する方法は存在します。
Method Channelの特性の多くは、よりシンプルなMessage Channelや、その基盤となるBinaryMessengerから派生しています。
したがって、ここでは少しPlatform Channelについて深掘りしてみたいと思います。

## Binary Messengerを使ってみる
FlutterからSwiftへメッセージを送るシンプルなBinary Messengerのサンプルを作成してみます。
以下のようなイメージです。
![](https://storage.googleapis.com/zenn-user-upload/54de918217c2-20250906.png)

### Flutter側実装
まずはFlutter側で、BinaryMessengerを使って、プラットフォーム側にBinaryDataを送信する処理を実装します。
`BinaryMessenger`はabstract classなので、以下のように`implements`で使用します。
`send`メソッドでは、チャンネル名と送信するデータを受け取り、`PlatformDispatcher.instance.sendPlatformMessage`で各プラットフォームにデータを送信します。
```dart: lib/main.dart
class CustomMessenger implements BinaryMessenger {
  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,![](https://storage.googleapis.com/zenn-user-upload/43a507af9f67-20250913.png)
    PlatformMessageResponseCallback? callback,
  ) {
    throw UnsupportedError("This platform message handling is not supported.");
  }![](https://storage.googleapis.com/zenn-user-upload/43a507af9f67-20250913.png)

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    ui.PlatformDispatcher.instance.sendPlatformMessage(
      channel,
      message,
      (data) {},
    );
    return null;
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    throw UnsupportedError("Setting message handler is not supported.");
  }
}
```

次にボタンを押した時に先ほど作成した`CustomMessenger`の`send`メソッドが発火するようにします。
コードは以下の通りです。
```dart: lib/main.dart
ElevatedButton(
  onPressed: () async {
    final messenger = CustomMessenger();
    const message = "Hello from Flutter!";
    final WriteBuffer buffer = WriteBuffer();
    final data = message.codeUnits;
    buffer.putUint8List(Uint8List.fromList(data));
    final ByteData byteData = buffer.done();
    await messenger.send('foo', byteData);
  },
  child: const Text('Send Message'),
),
```

上記で登場する`WriteBuffer`は、書き込み専用のバッファでByteDataインスタンスを格納できます。
ここでは、「Hello from Flutter!」の文字列をUint8Listに変換したデータを格納しています。
`messenger.send`の第一引数にはチャンネル名、第二引数にはデータを指定しています。したがって上記コードでは、`foo`というチャンネルに対してUint8List型に変換された「Hello from Flutter!」という文字列を送信しています。

これでFlutter側の実装ができました。

::: details Flutter側の実装コード
```dart: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Platform Channel Sample'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final messenger = CustomMessenger();
            const message = "Hello from Flutter!";
            final WriteBuffer buffer = WriteBuffer();
            final data = message.codeUnits;
            buffer.putUint8List(Uint8List.fromList(data));
            final ByteData byteData = buffer.done();
            await messenger.send('foo', byteData);
          },
          child: const Text('Send Message'),
        ),
      ),
    );
  }
}

class CustomMessenger implements BinaryMessenger {
  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) {
    throw UnsupportedError("This platform message handling is not supported.");
  }

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    ui.PlatformDispatcher.instance.sendPlatformMessage(
      channel,
      message,
      (data) {},
    );
    return null;
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    throw UnsupportedError("Setting message handler is not supported.");
  }
}
```
:::


### Swift側実装
次はSwift側の実装です。Swift側では、Flutterからのメッセージを受け取った後の処理を記述します。
コードは以下の通りです。それぞれ詳しくみていきます。
```swift: ios/Runner/AppDelegate.swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      guard let window = self.window,
            let flutterViewController = window.rootViewController as? FlutterViewController else {
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }

      let binaryMessenger = flutterViewController.engine.binaryMessenger
      binaryMessenger.setMessageHandlerOnChannel("foo", binaryMessageHandler: { [weak self] (message: Data?, reply: @escaping FlutterBinaryReply) in
           guard let message = message else {
               reply(nil)
               return
           }

           let messageString = String(data: message, encoding: .utf8) ?? "Failed to decode message"
           DispatchQueue.main.async {
               let alertController = UIAlertController(
                   title: "Message from Flutter",
                   message: messageString,
                   preferredStyle: .alert
               )
               alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
               flutterViewController.present(alertController, animated: true, completion: nil)
           }

           reply(nil)
      }
    )

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

以下は、`AppDelegate`で、Flutterプロジェクトを作成した段階で`FlutterAppDelegate`を継承するようになっています。
AppDelegateのwindowのrootViewControllerを`FlutterViewController`として取得しています。この`FlutterViewController`でFlutterから送られてきたバイナリーメッセージにアクセスできます。
```swift
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      guard let window = self.window,
            let flutterViewController = window.rootViewController as? FlutterViewController else {
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
```

:::details FlutterViewController
[Flutter architectural overview](https://docs.flutter.dev/resources/architectural-overview#platform-channels)にある通り、FlutterとiOSの連絡はFlutterViewControllerのFlutterBinaryMessengerを通じて行われます。
![](https://storage.googleapis.com/zenn-user-upload/99ab42b5570c-20250906.png)

Flutterアプリでは、AppDelegateが[FlutterAppDelegate](https://api.flutter.dev/ios-embedder/interface_flutter_app_delegate.html)を継承しています。FlutterAppDelegateは以下のような挙動を実現するために継承されています。
- ステータスバーのタッチをルートビューの`FlutterViewController`に転送して、上部へのスクロールが起こるようにする
- 画面がロックされている場合でもデバッグモードでFlutter接続を開いたままにする

[AppDelegate](https://developer.apple.com/documentation/uikit/uiapplicationdelegate)は実質的にアプリのルートオブジェクトであり、[UIApplication](https://developer.apple.com/documentation/uikit/uiapplication/)とのやり取りを管理するために連携して動作します。
基本的にiOSアプリには、UIApplicationのインスタンスが一つだけ存在します。UIApplicationは開いているウィンドウである[UIWindow](https://developer.apple.com/documentation/uikit/uiwindow)のリストを保持しています。
UIWindowは[UIViewController](https://developer.apple.com/documentation/UIKit/UIViewController)を持ち、ビューコントローラに共通する動作を定義します。
今回はそのルートにあるUIViewControllerを[FlutterViewController](https://api.flutter.dev/ios-embedder/interface_flutter_view_controller.html)として使用しています。

FlutterViewControllerはFlutterのためにカスタマイズされたUIViewControllerです。
以下のようなことを行なっており、すべてFlutterEngineで管理されています。
- Dartの実行
- チャンネルのコミュニケーション
- プラグインの登録
:::

以下では、flutterViewControllerからさらにbinaryMessengerを取得しています。
binaryMessengerには、setMessageHandlerOnChannelメソッドがあり、このメソッドではチャンネルのハンドラを追加することができます。
第一引数にはメソッドの名前、第二引数にはそのチャンネルでメッセージを受け取った場合の挙動を定義することができます。
messageが存在しない場合はFlutter側にnilを返して終了しています。
```swift
let binaryMessenger = flutterViewController.engine.binaryMessenger
binaryMessenger.setMessageHandlerOnChannel("foo", binaryMessageHandler: { [weak self] (message: Data?, reply: @escaping FlutterBinaryReply) in
  guard let message = message else {
    reply(nil)
    return
}
```

以下では、Flutterから送られてきたメッセージをUTF-8文字列にデコードし、アラートダイアログで表示させています。
これで、Flutterから送られてきた文字列をSwift側で受け取り、ダイアログに表示させることができます。
```swift
let messageString = String(data: message, encoding: .utf8) ?? "Failed to decode message"

DispatchQueue.main.async {
   let alertController = UIAlertController(
       title: "Message from Flutter",
       message: messageString,
       preferredStyle: .alert
   )
   alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
   flutterViewController.present(alertController, animated: true, completion: nil)
}

reply(nil)
```

## Method Channelを使ってみる
これまでで、Binary Messengerを使ってFlutterから各プラットフォームのコードにアクセスして連携できることがわかりました。次はMethod Channelを使ったメッセージングを行いたいと思います。

### Flutter側の実装
早速実装してみたいと思います。
コードは以下の通りです。
```dart
ElevatedButton(
  onPressed: () async {
    const methodChannel = MethodChannel('foo');
    try {
      const message = "Hello from Flutter!";
      await methodChannel.invokeMethod('showMessage', message);
    } on PlatformException catch (e) {
      print("Failed to send message: '${e.message}'.");
    }
  },
  child: const Text('Send Message'),
),
```

実装方法がBinary Messengerの場合とかなり異なります。
以下では、Method Channelを定義しています。
第一引数はMethod Channelの名前で、以下では`foo`を渡しています。
```dart
const methodChannel = MethodChannel('foo');
```

以下では、`invokeMethod`で各プラットフォームに向けてメッセージを送信しています。
```dart
const message = "Hello from Flutter!";
await methodChannel.invokeMethod('showMessage', message);
```

この `invokeMethod` の内部実装を少しみてみます。
一部省略していますが、コードは以下の通りです。
内部の処理で Binary Messengerを使用して、ByteDataを送信していることがわかります。
これは前の章で言及したものと同じ処理であり、`invokeMethod`を使用する側では`WriteBuffer`を使用する必要がないため実装がシンプルになっています。
```dart
Future<T?> _invokeMethod<T>(String method, {required bool missingOk, dynamic arguments}) async {
  final ByteData input = codec.encodeMethodCall(MethodCall(method, arguments));
  final ByteData? result = shouldProfilePlatformChannels
      ? await (binaryMessenger as _ProfiledBinaryMessenger).sendWithPostfix(
          name,
          '#$method',
          input,
        )
      : await binaryMessenger.send(name, input);
```

なお、上記の`sendWithPostfix`メソッドに関しても以下のようになっていて、`proxy`がBinaryMessengerであるため、同じような処理内容であることがわかります。
```dart
Future<ByteData?>? sendWithPostfix(String channel, String postfix, ByteData? message) async {
  _debugRecordUpStream(channelTypeName, '$channel$postfix', codecTypeName, message);
  final TimelineTask timelineTask = TimelineTask()
    ..start('Platform Channel send $channel$postfix');
  final ByteData? result;
  try {
    result = await proxy.send(channel, message);
  } finally {
    timelineTask.finish();
  }
```

以上の通り、Method Channelを使用した各プラットフォームへのメッセージの送信は前の章で扱ったBinaryMessengerの処理をより扱いやすくしたものであると言えるかと思います。

### Swift側の実装
次にSwift側の実装を行います。
コードは以下の通りです。
```swift
guard let window = self.window,
      let flutterViewController = window.rootViewController as? FlutterViewController else {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}

let methodChannel = FlutterMethodChannel(name: "foo", binaryMessenger: flutterViewController.binaryMessenger)

methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
    if call.method == "showMessage" {
        guard let message = call.arguments as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid message argument", details: nil))
            return
        }

        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "Message from Flutter",
                message: message,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            flutterViewController.present(alertController, animated: true, completion: nil)
        }

        result(nil)
    } else {
        result(FlutterMethodNotImplemented)
    }
}
```

以下では、FlutterMethodChannelを定義しています。
第一引数にはFlutter側と同じMethod Channelの名前を指定しています。
第二引数には、前の章と同様に`flutterViewController`から取得したBinary Messengerを指定しています。
```swift
let methodChannel = FlutterMethodChannel(name: "foo", binaryMessenger: flutterViewController.binaryMessenger)
```

以下では、定義した`methodChannel`の`setMethodCallHandler`を使って、Flutter側からメッセージを受け取った際の挙動を記述しています。
`call.method`では、メソッドの名前を参照して、Flutter側のメソッドと照合しています。Flutter側では`invokeMethod('showMessage', message)`を実行しているため合致しています。
```swift
methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
    if call.method == "showMessage" {
        guard let message = call.arguments as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid message argument", details: nil))
            return
        }
```

最後に、以下では受け取ったメッセージをダイアログで表示させています。
この辺りの処理は前の章と同様かと思います。
```swift
DispatchQueue.main.async {
    let alertController = UIAlertController(
        title: "Message from Flutter",
        message: message,
        preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    flutterViewController.present(alertController, animated: true, completion: nil)
}
```



## 参考
https://docs.flutter.dev/platform-integration/platform-channels#architecture

https://medium.com/flutter/flutter-platform-channels-ce7f540a104e

https://medium.com/codingmountain-blog/flutter-communicating-with-the-native-platform-ef2326d985c8