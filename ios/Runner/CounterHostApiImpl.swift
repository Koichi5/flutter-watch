//
//  CounterHostApiImpl.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/11/09.
//

import Foundation

class CounterHostApiImpl: NSObject, CounterHostApi {
    private let sessionManager: WCSessionManager

    init(sessionManager: WCSessionManager) {
        self.sessionManager = sessionManager
        super.init()
    }

    func resetCounter() throws {
        sessionManager.resetCounter()
    }

    func updateCounter(count: Int64) throws {
        sessionManager.updateCounter(Int(count))
    }

    func isWatchReachable() throws -> Bool {
        return sessionManager.isWatchReachable()
    }
}


