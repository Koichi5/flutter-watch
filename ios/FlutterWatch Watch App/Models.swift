//
//  Models.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/11/23.
//

import Foundation
import SwiftUI

struct WatchImage: Identifiable, Codable {
    let id: String
    let fileName: String
    let fileSize: Int
    let width: Int
    let height: Int
    let timestamp: Date
    let fileURL: URL

    var date: Date { timestamp }

    var fileSizeFormatted: String {
        if fileSize < 1024 {
            return "\(fileSize) B"
        } else if fileSize < 1024 * 1024 {
            return String(format: "%.1f KB", Double(fileSize) / 1024)
        } else {
            return String(format: "%.1f MB", Double(fileSize) / (1024 * 1024))
        }
    }

    var resolution: String {
        return "\(width)x\(height)"
    }

    func loadUIImage() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: data)
    }

    func loadImage() -> Image? {
        guard let uiImage = loadUIImage() else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    enum CodingKeys: String, CodingKey {
        case id, fileName, fileSize, width, height, timestamp, fileURLPath
    }

    init(id: String, fileName: String, fileSize: Int, width: Int, height: Int, timestamp: Date, fileURL: URL) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.timestamp = timestamp
        self.fileURL = fileURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fileName = try container.decode(String.self, forKey: .fileName)
        fileSize = try container.decode(Int.self, forKey: .fileSize)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        let fileURLPath = try container.decode(String.self, forKey: .fileURLPath)
        fileURL = URL(fileURLWithPath: fileURLPath)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(fileURL.path, forKey: .fileURLPath)
    }
}


