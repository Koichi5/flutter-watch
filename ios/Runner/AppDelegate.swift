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
