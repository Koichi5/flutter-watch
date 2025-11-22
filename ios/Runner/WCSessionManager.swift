//
//  WCSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/11/09.
//

import Foundation
import WatchConnectivity
import Flutter

class WCSessionManager: NSObject {
    static let shared = WCSessionManager()
    private var counter: Int = 0
    private let session = WCSession.default
    private var flutterApi: CounterFlutterApi?

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func setupFlutterApi(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = CounterFlutterApi(binaryMessenger: binaryMessenger)
    }

    func getCurrentCount() -> Int {
        return counter
    }

    func resetCounter() {
        counter = 0
        notifyFlutter(counter: counter)
        sendCounterToWatch(counter)
    }

    func updateCounter(_ newValue: Int) {
        counter = newValue
        notifyFlutter(counter: counter)
        sendCounterToWatch(counter)
    }

    func isWatchReachable() -> Bool {
        return session.isReachable
    }

    private func sendCounterToWatch(_ value: Int) {
        guard session.isReachable else {
            return
        }

        let message: [String: Any] = [
            "counter": value,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(
            message,
            replyHandler: { reply in
                print("Watch replied: \(reply)")
            },
            errorHandler: { error in
                print("Failed to send to Watch: \(error.localizedDescription)")
            }
        )
    }

    private func notifyFlutter(counter: Int) {
        guard let api = flutterApi else {
            return
        }

        DispatchQueue.main.async {
            api.onCounterIncremented(count: Int64(counter)) { result in
                switch result {
                case .success:
                    print("📱 📤 Notified Flutter: counter = \(counter)")
                case .failure(let error):
                    print("📱 ❌ Failed to notify Flutter: \(error)")
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
                    print("📱 📤 Notified Flutter: reachable = \(isReachable)")
                case .failure(let error):
                    print("📱 ❌ Failed to notify reachability: \(error)")
                }
            }
        }
    }
}

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

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        guard let action = message["action"] as? String else {
            replyHandler(["error": "Invalid message format"])
            return
        }

        switch action {
        case "increment":
            counter += 1
            notifyFlutter(counter: counter)

            let reply: [String: Any] = [
                "count": counter,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)

        case "decrement":
            counter -= 1
            notifyFlutter(counter: counter)

            let reply: [String: Any] = [
                "count": counter,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)

        case "reset":
            counter = 0
            notifyFlutter(counter: counter)

            let reply: [String: Any] = [
                "count": counter,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)

        case "getCount":
            let reply: [String: Any] = [
                "count": counter,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)

        default:
            replyHandler(["error": "Unknown action: \(action)"])
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {}
}

