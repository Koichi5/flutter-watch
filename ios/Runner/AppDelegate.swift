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
      let binaryMessenger = flutterViewController.engine.binaryMessenger
      // print("Swift: メッセージハンドラを登録します")
      binaryMessenger.setMessageHandlerOnChannel("foo", binaryMessageHandler: { [weak self] (message: Data?, reply: @escaping FlutterBinaryReply) in
           // print("Swift: メッセージを受信しました")
           guard let message = message else {
               // print("Swift: メッセージがnilです")
               reply(nil)
               return
           }

           // バイナリデータをUTF-8文字列にデコード
           let messageString = String(data: message, encoding: .utf8) ?? "Failed to decode message"
           // print("Swift: デコードされたメッセージ - \(messageString)")

           // メインスレッドでUIを更新
           DispatchQueue.main.async {
               // print("Swift: ダイアログを表示します")
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
      // print("Swift: メッセージハンドラの登録が完了しました")

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
