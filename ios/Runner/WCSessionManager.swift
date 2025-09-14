//
//  WCSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/09/14.
//

import WatchConnectivity

class WCSessionManager: NSObject {
    private let methodChannel: FlutterMethodChannel
    private var wcSession: WCSession?

    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init()
    }

    func initializeSession(completion: @escaping (Bool, String) -> Void) {
        guard WCSession.isSupported() else {
            completion(false, "WCSession is not supported")
            return
        }

        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let session = self?.wcSession else {
                completion(false, "Session is nil after activation")
                return
            }

            let status = self?.getSessionStatus(session) ?? "Error"
            completion(session.isReachable, status)
        }
    }

    func sendCounterValue(_ counter: Int, completion: @escaping (Bool) -> Void) {
        guard let session = wcSession else {
            completion(false)
            return
        }

        guard session.isReachable else {
            completion(false)
            return
        }

        let message = ["counter": counter]
        session.sendMessage(message, replyHandler: { response in
            completion(true)
        }, errorHandler: { error in
            completion(false)
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

            self?.methodChannel.invokeMethod("sessionStateChanged",
                                           arguments: ["status_key": status])
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel.invokeMethod("sessionStateChanged",
                                           arguments: ["status_key": "not_reachable"])
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel.invokeMethod("sessionStateChanged",
                                           arguments: ["status_key": "error"])
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.methodChannel.invokeMethod("counterUpdated",
                                               arguments: ["counter": counter])
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {

        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.methodChannel.invokeMethod("counterUpdated",
                                               arguments: ["counter": counter])
            }

            let reply = ["status": "received"] as [String : Any]
            replyHandler(reply)
        }
    }
}
