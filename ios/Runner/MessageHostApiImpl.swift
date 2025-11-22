//
//  MessageHostApiImpl.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/11/15.
//

import Foundation

class MessageHostApiImpl: NSObject, MessageHostApi {
    private let sessionManager: WCSessionManager

    init(sessionManager: WCSessionManager) {
        self.sessionManager = sessionManager
        super.init()
    }

    func sendMessage(message: MessageData) throws {
        try sessionManager.sendMessage(message: message)
    }

    func getSentMessages() throws -> [MessageData] {
        return sessionManager.getSentMessages()
    }

    func getReceivedMessages() throws -> [MessageData] {
        return sessionManager.getReceivedMessages()
    }

    func getQueueStatus() throws -> QueueStatus {
        return sessionManager.getQueueStatus()
    }

    func cancelMessage(messageId: String) throws -> Bool {
        return sessionManager.cancelMessage(messageId: messageId)
    }

    func markAsRead(messageId: String) throws {
        sessionManager.markAsRead(messageId: messageId)
    }

    func isWatchReachable() throws -> Bool {
        return sessionManager.isWatchReachable()
    }
}

