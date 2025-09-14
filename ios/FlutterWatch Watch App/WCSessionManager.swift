//
//  WatchSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/09/14.
//

import SwiftUI
import WatchConnectivity
import Combine

final class WCSessionManager: NSObject, ObservableObject {
    @Published var counter: Int = 0
    @Published var isConnected: Bool = false

    private var wcSession: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
        }
    }

    func startSession() {
        wcSession?.activate()
        self.checkSessionState()
    }

    private func checkSessionState() {
        guard let session = wcSession else {
            return
        }

        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }

    func incrementCounter() {
        let newValue = counter + 1
        updateCounter(newValue)
    }

    func decrementCounter() {
        let newValue = counter - 1
        updateCounter(newValue)
    }

    private func updateCounter(_ newValue: Int) {
        counter = newValue
        sendCounterValue(newValue)
    }

    private func sendCounterValue(_ value: Int) {
        guard let session = wcSession else {
            return
        }

        guard session.isReachable else {
            return
        }

        let message = ["counter": value]
        session.sendMessage(message, replyHandler: { _ in
        }, errorHandler: { error in
            debugPrint("⌚️ Send error: \(error.localizedDescription)")
        })
    }
}

extension WCSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let counterValue = message["counter"] as? Int {
                self.counter = counterValue
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            if let counterValue = message["counter"] as? Int {
                self.counter = counterValue
            }

            let reply = ["status": "received"] as [String : Any]
            replyHandler(reply)
        }
    }
}
