//
//  FlutterWatchApp.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/08/24.
//

import SwiftUI
import WatchConnectivity
import Combine

@main
struct FlutterWatch_Watch_AppApp: App {
    @StateObject private var sessionManager = WCSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}
