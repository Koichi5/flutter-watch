//
//  ImageDetailView.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/11/23.
//

import SwiftUI

struct ImageDetailView: View {
    let image: WatchImage
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            VStack(spacing: 12) {
                if let uiImage = image.loadUIImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                        Text("画像を読み込めません")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 150)
                }

                VStack(alignment: .leading, spacing: 6) {
                    MetadataRow(label: "ファイル名", value: image.fileName)
                    MetadataRow(label: "サイズ", value: image.fileSizeFormatted)
                    MetadataRow(label: "解像度", value: image.resolution)
                    MetadataRow(label: "受信日時", value: formatDateTime(image.timestamp))
                }
                .padding(.horizontal, 8)

                Button(role: .destructive, action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("削除")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("画像詳細")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "この画像を削除しますか？",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                ImageWatchSessionManager.shared.deleteImage(imageId: image.id)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        ImageDetailView(
            image: WatchImage(
                id: "preview",
                fileName: "sample.jpg",
                fileSize: 1024000,
                width: 1920,
                height: 1080,
                timestamp: Date(),
                fileURL: URL(fileURLWithPath: "/tmp/sample.jpg")
            )
        )
    }
}

