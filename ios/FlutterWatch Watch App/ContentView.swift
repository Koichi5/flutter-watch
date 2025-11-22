//
//  ContentView.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/08/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var showingSendSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MessagesView(sessionManager: sessionManager)
                HeaderView(
                    isReachable: sessionManager.isReachable,
                    unreadCount: sessionManager.getUnreadCount(),
                    queueCount: sessionManager.outstandingCount
                )
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSendSheet = true
                    }) {
                        Image(systemName: "paperplane")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSendSheet) {
            SendMessageSheet(sessionManager: sessionManager)
        }
    }
}

struct HeaderView: View {
    let isReachable: Bool
    let unreadCount: Int
    let queueCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isReachable ? Color.green : Color.red)
                .frame(width: 6, height: 6)

            Text(isReachable ? "接続中" : "未接続")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            if queueCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                    Text("\(queueCount)")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Color.black.opacity(0.3)
                .blur(radius: 10)
        )
    }
}

struct MessagesView: View {
    @ObservedObject var sessionManager: WatchSessionManager

    var body: some View {
        let allMessages = (sessionManager.sentMessages + sessionManager.receivedMessages)
            .sorted { $0.timestamp < $1.timestamp }
        if allMessages.isEmpty {
            EmptyStateView()
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(allMessages) { message in
                        let isSent = message.sender == "Watch"
                        MessageBubble(
                            message: message,
                            isSent: isSent,
                            onTap: {
                                if !isSent && !message.isRead {
                                    sessionManager.markAsRead(messageId: message.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
    }
}

struct MessageBubble: View {
    let message: WatchMessage
    let isSent: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if isSent {
                Spacer(minLength: 20)
            }
            Button(action: onTap) {
                VStack(alignment: isSent ? .trailing : .leading, spacing: 2) {
                    Text(message.text)
                        .font(.system(size: 13))
                        .foregroundColor(isSent ? .white : .primary)
                        .multilineTextAlignment(isSent ? .trailing : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 3) {
                        Text(formatTime(message.date))
                            .font(.system(size: 9))
                            .foregroundColor(isSent ? .white.opacity(0.8) : .secondary)

                        if !isSent && !message.isRead {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSent ? Color.blue : Color.gray.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
            Image(systemName: isSent ? "applewatch" : "iphone")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                )

            if !isSent {
                Spacer(minLength: 20)
            }
        }
        .padding(.horizontal, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "message")
                .font(.system(size: 32))
                .foregroundColor(.gray)

            Text("メッセージなし")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SendMessageSheet: View {
    @ObservedObject var sessionManager: WatchSessionManager
    @Environment(\.dismiss) var dismiss

    let templates = [
        "こんにちは",
        "了解しました",
        "ありがとう",
        "後で連絡します",
        "OK",
        "確認しました"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(templates.indices, id: \.self) { index in
                        Button(action: {
                            sessionManager.sendMessage(text: templates[index])
                            dismiss()
                        }) {
                            HStack {
                                Text(templates[index])
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .navigationTitle("送信")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
