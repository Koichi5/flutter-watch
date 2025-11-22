//
//  SettingsHostApiImpl 2.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/11/22.
//


//
//  SettingsHostApiImpl.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/11/13.
//

import Foundation

class SettingsHostApiImpl: NSObject, SettingsHostApi {
    private let sessionManager: WCSessionManager

    init(sessionManager: WCSessionManager) {
        self.sessionManager = sessionManager
        super.init()
    }

    func updateSettings(settings: SettingsData) throws {
        try sessionManager.updateSettings(settings: settings)
    }

    func getCurrentSettings() throws -> SettingsData {
        return sessionManager.getCurrentSettings()
    }

    func isWatchReachable() throws -> Bool {
        return sessionManager.isWatchReachable()
    }
}

