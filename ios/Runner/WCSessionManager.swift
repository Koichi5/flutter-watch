//
//  WCSessionManager.swift
//  Runner
//

import Foundation
import WatchConnectivity
import Flutter

class WCSessionManager: NSObject {
    static let shared = WCSessionManager()

    private let session = WCSession.default
    private var flutterApi: MessageFlutterApi?

    private let defaults = UserDefaults.standard
    private let sentMessagesKey = "sent_messages"
    private let receivedMessagesKey = "received_messages"
    private let receivedMessageIdsKey = "received_message_ids"

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func setupFlutterApi(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = MessageFlutterApi(binaryMessenger: binaryMessenger)
    }

    func sendMessage(message: MessageData) throws {
        saveSentMessage(message)
        let userInfo: [String: Any] = [
            "type": "message",
            "id": message.id,
            "text": message.text,
            "sender": message.sender,
            "timestamp": message.timestamp,
            "isRead": message.isRead
        ]

        session.transferUserInfo(userInfo)
        notifyQueueStatus()
    }

    func getSentMessages() -> [MessageData] {
        return loadSentMessages()
    }

    func getReceivedMessages() -> [MessageData] {
        return loadReceivedMessages()
    }

    func getQueueStatus() -> QueueStatus {
        let transfers = session.outstandingUserInfoTransfers
        let isTransferring = transfers.contains { $0.isTransferring }

        return QueueStatus(
            outstandingCount: Int64(transfers.count),
            isTransferring: isTransferring
        )
    }

    func cancelMessage(messageId: String) -> Bool {
        for transfer in session.outstandingUserInfoTransfers {
            if let id = transfer.userInfo["id"] as? String, id == messageId {
                transfer.cancel()
                notifyQueueStatus()
                return true
            }
        }

        return false
    }

    func markAsRead(messageId: String) {
        var messages = loadReceivedMessages()
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index] = MessageData(
                id: messages[index].id,
                text: messages[index].text,
                sender: messages[index].sender,
                timestamp: messages[index].timestamp,
                isRead: true
            )
            saveReceivedMessages(messages)
        }
    }

    func isWatchReachable() -> Bool {
        return session.isReachable
    }

    private func saveSentMessage(_ message: MessageData) {
        var messages = loadSentMessages()
        messages.append(message)
        saveSentMessages(messages)
    }

    private func saveSentMessages(_ messages: [MessageData]) {
        let array = messages.map { messageToDict($0) }
        defaults.set(array, forKey: sentMessagesKey)
    }

    private func loadSentMessages() -> [MessageData] {
        guard let array = defaults.array(forKey: sentMessagesKey) as? [[String: Any]] else {
            return []
        }
        return array.compactMap { dictToMessage($0) }
    }

    private func saveReceivedMessages(_ messages: [MessageData]) {
        let array = messages.map { messageToDict($0) }
        defaults.set(array, forKey: receivedMessagesKey)
    }

    private func loadReceivedMessages() -> [MessageData] {
        guard let array = defaults.array(forKey: receivedMessagesKey) as? [[String: Any]] else {
            return []
        }
        return array.compactMap { dictToMessage($0) }
    }

    private func messageToDict(_ message: MessageData) -> [String: Any] {
        return [
            "id": message.id,
            "text": message.text,
            "sender": message.sender,
            "timestamp": message.timestamp,
            "isRead": message.isRead
        ]
    }

    private func dictToMessage(_ dict: [String: Any]) -> MessageData? {
        guard let id = dict["id"] as? String,
              let text = dict["text"] as? String,
              let sender = dict["sender"] as? String,
              let timestamp = dict["timestamp"] as? Double,
              let isRead = dict["isRead"] as? Bool else {
            return nil
        }

        return MessageData(
            id: id,
            text: text,
            sender: sender,
            timestamp: timestamp,
            isRead: isRead
        )
    }

    private func notifyFlutter(message: MessageData) {
        guard let api = flutterApi else {
            print("FlutterApi not set up")
            return
        }

        DispatchQueue.main.async {
            api.onMessageReceived(message: message) { result in
                switch result {
                case .success:
                    print("Message notified to Flutter")
                case .failure(let error):
                    print("Failed to notify message to Flutter: \(error)")
                }
            }
        }
    }

    private func notifyQueueStatus() {
        guard let api = flutterApi else { return }

        let status = getQueueStatus()

        DispatchQueue.main.async {
            api.onQueueStatusChanged(status: status) { result in
                switch result {
                case .success:
                    print("Queue status notified to Flutter: \(status.outstandingCount)")
                case .failure(let error):
                    print("Failed to notify queue status to Flutter: \(error)")
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
                    print("Reachability notified to Flutter: \(isReachable)")
                case .failure(let error):
                    print("Failed to notify reachability to Flutter: \(error)")
                }
            }
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

extension WCSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("Activation error: \(error.localizedDescription)")
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
        didReceiveUserInfo userInfo: [String : Any] = [:]
    ) {
        guard let type = userInfo["type"] as? String, type == "message" else {
            print("Invalid message type")
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

        let message = MessageData(
            id: id,
            text: text,
            sender: sender,
            timestamp: timestamp,
            isRead: isRead
        )
        var messages = loadReceivedMessages()
        messages.append(message)
        saveReceivedMessages(messages)
        addReceivedMessageId(id)
        notifyFlutter(message: message)
    }
}
