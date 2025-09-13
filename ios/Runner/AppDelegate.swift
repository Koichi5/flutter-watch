import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      // print("Swift: didFinishLaunchingWithOptions が呼ばれました")

      guard let window = self.window,
            let flutterViewController = window.rootViewController as? FlutterViewController else {
          // print("Swift: FlutterViewController の取得に失敗しました")
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }

      // print("Swift: FlutterViewController を取得しました")
      // Method Channelを作成
      let methodChannel = FlutterMethodChannel(name: "foo", binaryMessenger: flutterViewController.binaryMessenger)

      // print("Swift: Method Channelを設定します")
      methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
          // print("Swift: Method Callを受信しました - メソッド名: \(call.method)")

          if call.method == "showMessage" {
              guard let message = call.arguments as? String else {
                  // print("Swift: 引数の取得に失敗しました")
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid message argument", details: nil))
                  return
              }

              // print("Swift: 受信したメッセージ - \(message)")

              // メインスレッドでUIを更新
              DispatchQueue.main.async {
                  // print("Swift: ダイアログを表示します")
                  let alertController = UIAlertController(
                      title: "Message from Flutter",
                      message: message,
                      preferredStyle: .alert
                  )
                  alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                  flutterViewController.present(alertController, animated: true, completion: nil)
              }

              // 成功を返す
              result(nil)
          } else {
              // print("Swift: 不明なメソッド - \(call.method)")
              result(FlutterMethodNotImplemented)
          }
      }
      // print("Swift: Method Channelの設定が完了しました")

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
