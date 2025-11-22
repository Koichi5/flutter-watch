//
//  ContentView.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/08/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            List {
                // 接続状態
                ConnectionStatusRow(
                    isReachable: sessionManager.isReachable
                )

                // テーマカラー
                ColorSection(sessionManager: sessionManager)

                // フォントサイズ
                FontSizeSection(sessionManager: sessionManager)

                // 通知設定
                NotificationRow(sessionManager: sessionManager)

                // 最終更新
                LastUpdatedRow(lastUpdated: sessionManager.lastUpdated)
            }
            .navigationTitle("Settings")
        }
    }
}

struct ConnectionStatusRow: View {
    let isReachable: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isReachable ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            Text(isReachable ? "接続中" : "未接続")
                .foregroundColor(isReachable ? .green : .gray)
                .font(.caption2)
        }
    }
}

struct ColorSection: View {
    @ObservedObject var sessionManager: WatchSessionManager

    private var themeColors: [(name: String, color: Color, value: Int)] {
        [
            ("赤", Color.red, 0),
            ("青", Color.blue, 1),
            ("緑", Color.green, 2)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("テーマカラー")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                ForEach(themeColors, id: \.value) { item in
                    Button(action: {
                        sessionManager.color = item.value
                        sessionManager.updateSettings()
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 32, height: 32)

                                if sessionManager.color == item.value {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            Text(item.name)
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
}

struct FontSizeSection: View {
    @ObservedObject var sessionManager: WatchSessionManager

    private var fontSizes: [(name: String, size: CGFloat, value: Int)] {
        [
            ("小", 12, 0),
            ("中", 14, 1),
            ("大", 16, 2)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("フォントサイズ")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(fontSizes, id: \.value) { item in
                    Button(action: {
                        sessionManager.fontSize = item.value
                        sessionManager.updateSettings()
                    }) {
                        Text(item.name)
                            .font(.system(size: 14))
                            .foregroundColor(sessionManager.fontSize == item.value ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                sessionManager.fontSize == item.value
                                    ? Color.blue
                                    : Color.gray.opacity(0.2)
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct NotificationRow: View {
    @ObservedObject var sessionManager: WatchSessionManager

    var body: some View {
        Toggle(isOn: Binding(
            get: { sessionManager.notificationEnabled },
            set: { newValue in
                sessionManager.notificationEnabled = newValue
                sessionManager.updateSettings()
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("通知")
                Text(sessionManager.notificationEnabled ? "有効" : "無効")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LastUpdatedRow: View {
    let lastUpdated: Date

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: lastUpdated)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "clock")
                Text("最終更新")
            }
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
