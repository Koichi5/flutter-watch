//
//  ContentView.swift
//  FlutterWatch Watch App
//

import SwiftUI
import WatchConnectivity
import Combine

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                ConnectionStatusView(isReachable: sessionManager.isReachable)

                Text("\(sessionManager.count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 16) {
                    Button(action: {
                        sessionManager.decrementCounter()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 32, weight: .bold))
                    }
                    .disabled(!sessionManager.isReachable)

                    Button(action: {
                        sessionManager.incrementCounter()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .bold))
                    }
                    .disabled(!sessionManager.isReachable)
                }
            }
            .padding()
        }
    }
}

struct ConnectionStatusView: View {
    let isReachable: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isReachable ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(isReachable ? "iPhone 接続中" : "iPhone 未接続")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

class WatchSessionManager: NSObject, ObservableObject {
    @Published var count: Int = 0
    @Published var isReachable: Bool = false

    private let session = WCSession.default
    private var isSending: Bool = false

    override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func incrementCounter() {
        guard !isSending else {
            return
        }

        guard session.isReachable else {
            return
        }

        isSending = true

        let previousCount = count
        count += 1

        let message: [String: Any] = [
            "action": "increment",
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(
            message,
            replyHandler: { [weak self] reply in
                DispatchQueue.main.async {
                    self?.handleReply(reply)
                }
            },
            errorHandler: { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.count = previousCount
                    self.handleError(error)
                }
            }
        )
    }

    func decrementCounter() {
        guard !isSending else {
            return
        }

        guard session.isReachable else {
            return
        }

        isSending = true

        let previousCount = count
        count -= 1

        let message: [String: Any] = [
            "action": "decrement",
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(
            message,
            replyHandler: { [weak self] reply in
                DispatchQueue.main.async {
                    self?.handleReply(reply)
                }
            },
            errorHandler: { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.count = previousCount
                    self.handleError(error)
                }
            }
        )
    }

    private func handleReply(_ reply: [String: Any]) {
        isSending = false

        if let serverCount = reply["count"] as? Int {
            if count != serverCount {
                count = serverCount
            }
        }
    }

    private func handleError(_ error: Error) {
        isSending = false
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let counterValue = message["counter"] as? Int {
                self.count = counterValue
            }
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        DispatchQueue.main.async {
            if let counterValue = message["counter"] as? Int {
                self.count = counterValue
            }
        }

        let reply: [String: Any] = [
            "status": "received",
            "count": count
        ]
        replyHandler(reply)
    }
}

#Preview {
    ContentView()
}
