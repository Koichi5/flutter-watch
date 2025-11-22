import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let binaryMessenger = controller.binaryMessenger
    let sessionManager = WCSessionManager.shared

    let messageHostApi = MessageHostApiImpl(sessionManager: sessionManager)
    MessageHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: messageHostApi)
    sessionManager.setupFlutterApi(binaryMessenger: binaryMessenger)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
