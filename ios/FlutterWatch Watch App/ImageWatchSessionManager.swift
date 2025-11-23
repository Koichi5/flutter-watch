//
//  ImageWatchSessionManager.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/11/23.
//

import Foundation
import WatchConnectivity
import Combine
import UIKit

class ImageWatchSessionManager: NSObject, ObservableObject {
    static let shared = ImageWatchSessionManager()

    private let session = WCSession.default

    @Published var images: [WatchImage] = []
    @Published var isReachable: Bool = false

    private let defaults = UserDefaults.standard
    private let imagesMetadataKey = "watch_images_metadata"

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        loadImagesMetadata()

        session.delegate = self
        session.activate()
    }

    func deleteImage(imageId: String) {
        guard let index = images.firstIndex(where: { $0.id == imageId }) else {
            return
        }

        let image = images[index]

        do {
            try FileManager.default.removeItem(at: image.fileURL)
        } catch {
            print("Failed to delete file: \(error)")
        }
        images.remove(at: index)
        saveImagesMetadata()
    }

    private func loadImagesMetadata() {
        guard let data = defaults.data(forKey: imagesMetadataKey),
              let decoded = try? JSONDecoder().decode([WatchImage].self, from: data) else {
            return
        }

        images = decoded.filter { image in
            FileManager.default.fileExists(atPath: image.fileURL.path)
        }

        if images.count != decoded.count {
            saveImagesMetadata()
        }
    }

    private func saveImagesMetadata() {
        if let encoded = try? JSONEncoder().encode(images) {
            defaults.set(encoded, forKey: imagesMetadataKey)
        }
    }

    private func addImage(_ image: WatchImage) {
        images.append(image)
        saveImagesMetadata()
    }
}

extension ImageWatchSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if let error = error {
            print("Activation error: \(error.localizedDescription)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata = file.metadata,
              let id = metadata["id"] as? String,
              let fileName = metadata["fileName"] as? String,
              let fileSize = metadata["fileSize"] as? Int,
              let width = metadata["width"] as? Int,
              let height = metadata["height"] as? Int,
              let timestamp = metadata["timestamp"] as? Double else {
            print("Invalid metadata")
            return
        }

        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let destinationURL = documentsURL
            .appendingPathComponent(id)
            .appendingPathExtension("jpg")

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.moveItem(
                at: file.fileURL,
                to: destinationURL
            )

            let watchImage = WatchImage(
                id: id,
                fileName: fileName,
                fileSize: fileSize,
                width: width,
                height: height,
                timestamp: Date(timeIntervalSince1970: timestamp),
                fileURL: destinationURL
            )

            DispatchQueue.main.async {
                self.addImage(watchImage)
            }

        } catch {
            print("Failed to save file: \(error)")
        }
    }
}


