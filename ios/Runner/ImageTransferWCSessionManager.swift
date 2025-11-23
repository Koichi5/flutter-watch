//
//  ImageTransferWCSessionManager.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/11/23.
//

import Foundation
import WatchConnectivity
import Flutter
import UIKit

class ImageTransferWCSessionManager: NSObject {
    static let shared = ImageTransferWCSessionManager()

    private let session = WCSession.default
    private var flutterApi: ImageTransferFlutterApi?

    private let defaults = UserDefaults.standard
    private let transferHistoryKey = "image_transfer_history"

    private var progressObservations: [String: NSKeyValueObservation] = [:]
    private var transferStartTimes: [String: Date] = [:]
    private var lastProgressValues: [String: Double] = [:]
    private var progressTimer: Timer?

    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func setupFlutterApi(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = ImageTransferFlutterApi(binaryMessenger: binaryMessenger)
    }

    func transferImage(imageData: FlutterStandardTypedData, metadata: ImageMetadata) throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(metadata.id)
            .appendingPathExtension("jpg")

        do {
            try imageData.data.write(to: tempURL)
        } catch {
            print("Failed to write temp file: \(error)")
            throw error
        }

        let metadataDict: [String: Any] = [
            "id": metadata.id,
            "fileName": metadata.fileName,
            "fileSize": metadata.fileSize,
            "width": metadata.width,
            "height": metadata.height,
            "timestamp": metadata.timestamp
        ]

        addToHistory(metadata: metadata, status: 0) // 0 = pending

        let transfer = session.transferFile(tempURL, metadata: metadataDict)
        startMonitoringProgress(transfer: transfer, imageId: metadata.id)
    }

    func cancelTransfer(imageId: String) {

        for transfer in session.outstandingFileTransfers {
            if let id = transfer.file.metadata?["id"] as? String, id == imageId {
                transfer.cancel()
                stopMonitoringProgress(imageId: imageId)
                updateHistoryStatus(imageId: imageId, status: 4) // 4 = cancelled
                return
            }
        }
    }

    func getTransferHistory() -> [TransferHistoryItem] {
        return loadHistory()
    }

    func getActiveTransfers() -> [TransferProgress] {
        var activeTransfers: [TransferProgress] = []

        for transfer in session.outstandingFileTransfers {
            guard let imageId = transfer.file.metadata?["id"] as? String else {
                continue
            }

            let progress = calculateProgress(
                transfer: transfer,
                imageId: imageId
            )
            activeTransfers.append(progress)
        }

        return activeTransfers
    }

    private func startMonitoringProgress(transfer: WCSessionFileTransfer, imageId: String) {
        transferStartTimes[imageId] = Date()
        lastProgressValues[imageId] = 0.0

        let observation = transfer.progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                let progressData = self.calculateProgress(
                    transfer: transfer,
                    imageId: imageId
                )
                self.notifyProgress(progressData)
                self.lastProgressValues[imageId] = progress.fractionCompleted
            }
        }

        progressObservations[imageId] = observation

        if progressTimer == nil {
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.updateAllProgress()
            }
        }
    }

    private func stopMonitoringProgress(imageId: String) {
        progressObservations[imageId]?.invalidate()
        progressObservations.removeValue(forKey: imageId)
        transferStartTimes.removeValue(forKey: imageId)
        lastProgressValues.removeValue(forKey: imageId)

        if progressObservations.isEmpty {
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }

    private func updateAllProgress() {
        for transfer in session.outstandingFileTransfers {
            guard let imageId = transfer.file.metadata?["id"] as? String else {
                continue
            }

            let progressData = calculateProgress(
                transfer: transfer,
                imageId: imageId
            )
            notifyProgress(progressData)
        }
    }

    private func calculateProgress(
        transfer: WCSessionFileTransfer,
        imageId: String
    ) -> TransferProgress {
        let progress = transfer.progress.fractionCompleted
        let completedBytes = transfer.progress.completedUnitCount
        let totalBytes = transfer.progress.totalUnitCount

        var transferSpeed: Double = 0.0
        var estimatedTimeRemaining: Double = 0.0

        if let startTime = transferStartTimes[imageId] {
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime > 0 {
                transferSpeed = Double(completedBytes) / elapsedTime

                let remainingBytes = totalBytes - completedBytes
                if transferSpeed > 0 {
                    estimatedTimeRemaining = Double(remainingBytes) / transferSpeed
                }
            }
        }

        return TransferProgress(
            imageId: imageId,
            progress: progress,
            bytesTransferred: completedBytes,
            totalBytes: totalBytes,
            transferSpeed: transferSpeed,
            estimatedTimeRemaining: max(0, estimatedTimeRemaining)
        )
    }

    private func notifyProgress(_ progress: TransferProgress) {
        guard let api = flutterApi else { return }

        api.onProgressUpdated(progress: progress) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Failed to notify progress: \(error)")
            }
        }
    }

    private func addToHistory(metadata: ImageMetadata, status: Int) {
        var history = loadHistory()

        let item = TransferHistoryItem(
            metadata: metadata,
            status: Int64(status),
            completedAt: nil
        )

        history.append(item)
        saveHistory(history)
    }

    private func updateHistoryStatus(imageId: String, status: Int, completedAt: Double? = nil) {
        var history = loadHistory()

        if let index = history.firstIndex(where: { $0.metadata.id == imageId }) {
            let metadata = history[index].metadata
            history[index] = TransferHistoryItem(
                metadata: metadata,
                status: Int64(status),
                completedAt: completedAt
            )
            saveHistory(history)
        }
    }

    private func loadHistory() -> [TransferHistoryItem] {
        guard let data = defaults.data(forKey: transferHistoryKey),
              let dictionaries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return dictionaries.compactMap { dict in
            guard let metadataDict = dict["metadata"] as? [String: Any],
                  let id = metadataDict["id"] as? String,
                  let fileName = metadataDict["fileName"] as? String,
                  let fileSize = metadataDict["fileSize"] as? Int,
                  let width = metadataDict["width"] as? Int,
                  let height = metadataDict["height"] as? Int,
                  let timestamp = metadataDict["timestamp"] as? Double,
                  let status = dict["status"] as? Int else {
                return nil
            }

            let metadata = ImageMetadata(
                id: id,
                fileName: fileName,
                fileSize: Int64(fileSize),
                width: Int64(width),
                height: Int64(height),
                timestamp: timestamp
            )

            let completedAt = dict["completedAt"] as? Double

            return TransferHistoryItem(
                metadata: metadata,
                status: Int64(status),
                completedAt: completedAt
            )
        }
    }

    private func saveHistory(_ history: [TransferHistoryItem]) {
        let dictionaries: [[String: Any]] = history.map { item in
            let metadataDict: [String: Any] = [
                "id": item.metadata.id,
                "fileName": item.metadata.fileName,
                "fileSize": item.metadata.fileSize,
                "width": item.metadata.width,
                "height": item.metadata.height,
                "timestamp": item.metadata.timestamp
            ]

            var dict: [String: Any] = [
                "metadata": metadataDict,
                "status": item.status
            ]

            if let completedAt = item.completedAt {
                dict["completedAt"] = completedAt
            }

            return dict
        }

        if let data = try? JSONSerialization.data(withJSONObject: dictionaries) {
            defaults.set(data, forKey: transferHistoryKey)
        }
    }
}

extension ImageTransferWCSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("Activation error: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: Error?
    ) {
        guard let imageId = fileTransfer.file.metadata?["id"] as? String else {
            print("No imageId in transfer metadata")
            return
        }

        stopMonitoringProgress(imageId: imageId)

        if let error = error {
            print("Error: \(error.localizedDescription)")

            updateHistoryStatus(imageId: imageId, status: 3) // 3 = failed

            flutterApi?.onTransferFailed(imageId: imageId, error: error.localizedDescription) { _ in }
        } else {
            let completedAt = Date().timeIntervalSince1970
            updateHistoryStatus(imageId: imageId, status: 2, completedAt: completedAt) // 2 = completed

            flutterApi?.onTransferCompleted(imageId: imageId) { _ in }
        }
    }
}


