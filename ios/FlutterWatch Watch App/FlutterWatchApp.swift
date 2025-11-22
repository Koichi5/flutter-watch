//
//  FlutterWatchApp.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/08/24.
//

import SwiftUI

@main
struct FlutterWatch_Watch_AppApp: App {
    init() {
        _ = WatchSessionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
