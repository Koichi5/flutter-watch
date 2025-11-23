//
//  ContentView.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/11/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = ImageWatchSessionManager.shared

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.images.isEmpty {
                    EmptyImageStateView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(sessionManager.images.sorted(by: { $0.timestamp > $1.timestamp })) { image in
                                NavigationLink(destination: ImageDetailView(image: image)) {
                                    ImageGridItem(image: image)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("Images")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(sessionManager.isReachable ? Color.green : Color.red)
                            .frame(width: 6, height: 6)

                        if !sessionManager.images.isEmpty {
                            Text("\(sessionManager.images.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct ImageGridItem: View {
    let image: WatchImage

    var body: some View {
        VStack(spacing: 2) {
            if let uiImage = image.loadUIImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 70)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 70)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            Text(image.fileName)
                .font(.system(size: 10))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(.primary)

            Text(formatDate(image.timestamp))
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct EmptyImageStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("画像がありません")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Text("iPhoneから画像を\n送信してください")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
