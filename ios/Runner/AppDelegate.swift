import Flutter
import UIKit

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
