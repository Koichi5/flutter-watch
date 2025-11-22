//
//  WatchSessionManager.swift
//  FlutterWatch Watch App

import Foundation
import WatchConnectivity
import Combine

struct WatchMessage: Identifiable, Codable {
    let id: String
    let text: String
    let sender: String
    let timestamp: Double
    var isRead: Bool

    var date: Date {
        Date(timeIntervalSince1970: timestamp)
    }
}

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    private let session = WCSession.default
    private let defaults = UserDefaults.standard
    private let sentMessagesKey = "sent_messages"
    private let receivedMessagesKey = "received_messages"
    private let receivedMessageIdsKey = "received_message_ids"

    @Published var sentMessages: [WatchMessage] = []
    @Published var receivedMessages: [WatchMessage] = []
    @Published var isReachable: Bool = false
    @Published var outstandingCount: Int = 0

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        loadMessages()

        session.delegate = self
        session.activate()
    }

    func sendMessage(text: String) {
        let message = WatchMessage(
            id: UUID().uuidString,
            text: text,
            sender: "Watch",
            timestamp: Date().timeIntervalSince1970,
            isRead: false
        )

        sentMessages.append(message)
        saveSentMessages()
        let userInfo: [String: Any] = [
            "type": "message",
            "id": message.id,
            "text": message.text,
            "sender": message.sender,
            "timestamp": message.timestamp,
            "isRead": message.isRead
        ]

        session.transferUserInfo(userInfo)
        updateQueueStatus()
    }

    func markAsRead(messageId: String) {
        if let index = receivedMessages.firstIndex(where: { $0.id == messageId }) {
            receivedMessages[index].isRead = true
            saveReceivedMessages()
        }
    }

    func getUnreadCount() -> Int {
        return receivedMessages.filter { !$0.isRead }.count
    }

    private func saveSentMessages() {
        if let encoded = try? JSONEncoder().encode(sentMessages) {
            defaults.set(encoded, forKey: sentMessagesKey)
        }
    }

    private func saveReceivedMessages() {
        if let encoded = try? JSONEncoder().encode(receivedMessages) {
            defaults.set(encoded, forKey: receivedMessagesKey)
        }
    }

    private func loadMessages() {
        if let data = defaults.data(forKey: sentMessagesKey),
           let messages = try? JSONDecoder().decode([WatchMessage].self, from: data) {
            sentMessages = messages
        }

        if let data = defaults.data(forKey: receivedMessagesKey),
           let messages = try? JSONDecoder().decode([WatchMessage].self, from: data) {
            receivedMessages = messages
        }
    }

    private func updateQueueStatus() {
        DispatchQueue.main.async {
            self.outstandingCount = self.session.outstandingUserInfoTransfers.count
        }
    }

    private func getReceivedMessageIds() -> Set<String> {
        guard let array = defaults.array(forKey: receivedMessageIdsKey) as? [String] else {
            return Set()
        }
        return Set(array)
    }

    private func addReceivedMessageId(_ id: String) {
        var ids = getReceivedMessageIds()
        ids.insert(id)
        defaults.set(Array(ids), forKey: receivedMessageIdsKey)
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

        if let error = error {
            print("Activation error: \(error.localizedDescription)")
        }
        updateQueueStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String : Any]
    ) {
        guard let type = userInfo["type"] as? String, type == "message" else {
            return
        }

        guard let id = userInfo["id"] as? String,
              let text = userInfo["text"] as? String,
              let sender = userInfo["sender"] as? String,
              let timestamp = userInfo["timestamp"] as? Double,
              let isRead = userInfo["isRead"] as? Bool else {
            print("Invalid message format")
            return
        }

        let receivedIds = getReceivedMessageIds()
        if receivedIds.contains(id) {
            return
        }

        let message = WatchMessage(
            id: id,
            text: text,
            sender: sender,
            timestamp: timestamp,
            isRead: isRead
        )

        DispatchQueue.main.async {
            self.receivedMessages.append(message)
            self.saveReceivedMessages()
            self.addReceivedMessageId(id)
        }
    }
}
