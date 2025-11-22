//
//  WatchSessionManager.swift

import Foundation
import WatchConnectivity
import Combine

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    private let session = WCSession.default

    private let defaults = UserDefaults.standard
    private let settingsKey = "app_settings"

    @Published var color: Int = 1
    @Published var fontSize: Int = 1
    @Published var notificationEnabled: Bool = true
    @Published var lastUpdated: Date = Date()
    @Published var isReachable: Bool = false

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        loadSettings()

        session.delegate = self
        session.activate()
    }

    func updateSettings() {
        saveSettings()

        let context: [String: Any] = [
            "color": color,
            "fontSize": fontSize,
            "notificationEnabled": notificationEnabled,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error)")
        }
    }

    private func saveSettings() {
        let dict: [String: Any] = [
            "color": color,
            "fontSize": fontSize,
            "notificationEnabled": notificationEnabled,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]
        defaults.set(dict, forKey: settingsKey)
    }

    private func loadSettings() {
        guard let dict = defaults.dictionary(forKey: settingsKey) else {
            return
        }

        color = dict["color"] as? Int ?? 1
        fontSize = dict["fontSize"] as? Int ?? 1
        notificationEnabled = dict["notificationEnabled"] as? Bool ?? true
        if let timestamp = dict["lastUpdated"] as? Double {
            lastUpdated = Date(timeIntervalSince1970: timestamp)
        }
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
            print("Session activation error: \(error.localizedDescription)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("Reachability changed: \(session.isReachable)")
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String : Any]
    ) {
        guard let color = applicationContext["color"] as? Int,
              let fontSize = applicationContext["fontSize"] as? Int,
              let notificationEnabled = applicationContext["notificationEnabled"] as? Bool,
              let lastUpdated = applicationContext["lastUpdated"] as? Double else {
            return
        }

        DispatchQueue.main.async {
            self.color = color
            self.fontSize = fontSize
            self.notificationEnabled = notificationEnabled
            self.lastUpdated = Date(timeIntervalSince1970: lastUpdated)
            self.saveSettings()
        }
    }
}

