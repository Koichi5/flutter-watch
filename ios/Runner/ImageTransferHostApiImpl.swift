//
//  ImageTransferHostApiImpl.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2025/11/23.
//

import Foundation

class ImageTransferHostApiImpl: NSObject, ImageTransferHostApi {
    private let sessionManager: ImageTransferWCSessionManager

    init(sessionManager: ImageTransferWCSessionManager) {
        self.sessionManager = sessionManager
        super.init()
    }

    func transferImage(
        imageData: FlutterStandardTypedData,
        metadata: ImageMetadata,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            try sessionManager.transferImage(imageData: imageData, metadata: metadata)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func cancelTransfer(imageId: String) throws {
        sessionManager.cancelTransfer(imageId: imageId)
    }

    func getTransferHistory() throws -> [TransferHistoryItem] {
        return sessionManager.getTransferHistory()
    }

    func getActiveTransfers() throws -> [TransferProgress] {
        return sessionManager.getActiveTransfers()
    }
}


