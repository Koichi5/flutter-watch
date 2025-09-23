//
//  WCSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/09/14.
//

import WatchConnectivity
import Flutter

class WCSessionManager: NSObject {
    private let flutterApi: WatchCommunicationFlutterApi
    private var wcSession: WCSession?

    init(flutterApi: WatchCommunicationFlutterApi) {
        self.flutterApi = flutterApi
        super.init()
    }

    func initializeSession(completion: @escaping (SessionInitializeResult) -> Void) {
        guard WCSession.isSupported() else {
            completion(SessionInitializeResult(success: false, statusKey: "not_supported"))
            return
        }

        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let session = self?.wcSession else {
                completion(SessionInitializeResult(success: false, statusKey: "error"))
                return
            }

            let statusKey = self?.getSessionStatus(session) ?? "error"
            completion(SessionInitializeResult(success: session.isReachable, statusKey: statusKey))
        }
    }

    func sendCounterValue(_ counter: Int64, completion: @escaping (CounterResult) -> Void) {
        guard let session = wcSession else {
            completion(CounterResult(success: false))
            return
        }

        guard session.isReachable else {
            completion(CounterResult(success: false))
            return
        }

        let message = ["counter": counter]
        session.sendMessage(message, replyHandler: { response in
            completion(CounterResult(success: true))
        }, errorHandler: { error in
            completion(CounterResult(success: false))
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

            self?.flutterApi.onSessionStateChanged(
                event: SessionStateEvent(statusKey: statusKey),
                completion: { _ in }
            )
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 セッション一時非アクティブ - 自動復旧を待機")
        print("📱 詳細: isPaired=\(session.isPaired), isWatchAppInstalled=\(session.isWatchAppInstalled), isReachable=\(session.isReachable)")

        DispatchQueue.main.async { [weak self] in
            self?.flutterApi.onSessionStateChanged(
                event: SessionStateEvent(statusKey: "not_reachable"),
                completion: { _ in }
            )
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.flutterApi.onSessionStateChanged(
                event: SessionStateEvent(statusKey: "error"),
                completion: { _ in }
            )
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.flutterApi.onCounterUpdated(
                    event: CounterUpdateEvent(counter: Int64(counter)),
                    completion: { _ in }
                )
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async { [weak self] in
            if let counter = message["counter"] as? Int {
                self?.flutterApi.onCounterUpdated(
                    event: CounterUpdateEvent(counter: Int64(counter)),
                    completion: { _ in }
                )
            }

            let reply = ["status": "received"] as [String : Any]
            replyHandler(reply)
        }
    }
}
