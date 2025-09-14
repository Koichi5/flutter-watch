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
