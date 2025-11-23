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
    let binaryMessenger = controller.binaryMessenger

    let imageTransferSessionManager = ImageTransferWCSessionManager.shared
    imageTransferSessionManager.setupFlutterApi(binaryMessenger: binaryMessenger)

    let imageTransferHostApi = ImageTransferHostApiImpl(sessionManager: imageTransferSessionManager)
    ImageTransferHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: imageTransferHostApi)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
