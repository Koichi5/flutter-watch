//
//  WCSessionManager.swift

import Foundation
import WatchConnectivity
import Flutter

class WCSessionManager: NSObject {
    static let shared = WCSessionManager()

    private let session = WCSession.default
    private var flutterApi: SettingsFlutterApi?

    private let defaults = UserDefaults.standard
    private let settingsKey = "app_settings"

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func setupFlutterApi(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = SettingsFlutterApi(binaryMessenger: binaryMessenger)
    }

    func updateSettings(settings: SettingsData) throws {
        saveSettings(settings)

        let context: [String: Any] = [
            "color": settings.color,
            "fontSize": settings.fontSize,
            "notificationEnabled": settings.notificationEnabled,
            "lastUpdated": settings.lastUpdated
        ]

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error)")
            throw error
        }
    }

    func getCurrentSettings() -> SettingsData {
        return loadSettings()
    }

    func isWatchReachable() -> Bool {
        return session.isReachable
    }

    private func saveSettings(_ settings: SettingsData) {
        let dict: [String: Any] = [
            "color": settings.color,
            "fontSize": settings.fontSize,
            "notificationEnabled": settings.notificationEnabled,
            "lastUpdated": settings.lastUpdated
        ]
        defaults.set(dict, forKey: settingsKey)
    }

    private func loadSettings() -> SettingsData {
        guard let dict = defaults.dictionary(forKey: settingsKey) else {
            return SettingsData(
                color: 1,
                fontSize: 1,
                notificationEnabled: true,
                lastUpdated: Date().timeIntervalSince1970
            )
        }

        return SettingsData(
            color: dict["color"] as? Int64 ?? 1,
            fontSize: dict["fontSize"] as? Int64 ?? 1,
            notificationEnabled: dict["notificationEnabled"] as? Bool ?? true,
            lastUpdated: dict["lastUpdated"] as? Double ?? Date().timeIntervalSince1970
        )
    }

    private func notifyFlutter(settings: SettingsData) {
        guard let api = flutterApi else {
            return
        }

        DispatchQueue.main.async {
            api.onSettingsUpdated(settings: settings) { result in
                switch result {
                case .success:
                    print("Notified Flutter of settings update")
                case .failure(let error):
                    print("Failed to notify Flutter: \(error)")
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
                    print("Notified Flutter: reachable = \(isReachable)")
                case .failure(let error):
                    print("Failed to notify reachability: \(error)")
                }
            }
        }
    }
}

extension WCSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("Error: \(error.localizedDescription)")
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
        didReceiveApplicationContext applicationContext: [String : Any]
    ) {
        guard let color = applicationContext["color"] as? Int,
              let fontSize = applicationContext["fontSize"] as? Int,
              let notificationEnabled = applicationContext["notificationEnabled"] as? Bool,
              let lastUpdated = applicationContext["lastUpdated"] as? Double else {
            print("Invalid context format")
            return
        }

        let settings = SettingsData(
            color: Int64(color),
            fontSize: Int64(fontSize),
            notificationEnabled: notificationEnabled,
            lastUpdated: lastUpdated
        )
        saveSettings(settings)
        notifyFlutter(settings: settings)
    }
}
