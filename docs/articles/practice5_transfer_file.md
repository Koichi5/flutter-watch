## transferFile とは
`transferFile`は、WatchConnectivity フレームワークが提供するメソッドの一つで、ファイルを確実に転送します。このメソッドのはファイル転送専用であり、進捗状況を監視することもできます。オフライン時でもキューに追加され、接続が回復したら自動的に配信されます。

## transferFile の特徴
`transferFile`には以下のような特徴があります。

- ファイル転送専用
  - テキストデータや辞書型データではなく、ファイル（画像、動画、ドキュメントなど）を転送するために設計されている
- 進捗監視が可能
  - `WCSessionFileTransfer.progress`で転送進捗を監視できる
  - `fractionCompleted`で進捗率（0.0〜1.0）を取得できる
  - `completedUnitCount`と`totalUnitCount`で転送済み/総バイト数を取得できる
- すべてのファイルがキューに保持される
  - `transferUserInfo`と同様に、すべてのファイルが順番に配信される
- 送信順序が保証される
  - 送信した順番通りに受信側で処理される
- オフライン時も動作
  - オフライン時でもキューに追加され、接続回復後に自動的に配信される
- 到達可能性のチェック不要
  - `sendMessage`とは異なり、`isReachable`のチェックが不要
- メタデータの送信
  - ファイルと一緒にメタデータ（辞書型）を送信できる
- キュー状態の管理
  - `outstandingFileTransfers`でキューに残っているファイル数を確認できる

`transferFile`は、画像や動画などのファイルを確実に転送したい場合に適しています。例えば、写真アプリで撮影した画像をApple Watchに転送したい場合に使用します。

一方で、テキストデータの転送には`transferUserInfo`、即座の応答が必要な操作には`sendMessage`、最新値だけが重要な設定の同期には`updateApplicationContext`を検討する必要があるかと思います。

## 使ってみる
次は実際に`transferFile`を使って iOS と watchOS の画像ファイルのやり取りを行い、さらにそれを Flutter 側にも反映させる実装を行います。
今回の実装では、画像転送アプリを題材として扱います。

最終的には以下のように、iPhone と Apple Watch でそれぞれの画像を転送し、表示内容が同期するような実装を行います。
実装は以下の手順で進めていきます。
1. iOS と watchOS 間のデータのやり取り
2. iOS と Flutter 間のデータのやり取り

## iOS と watchOS 間のデータのやり取り
### 前提
iOS と watchOS 間の通信の実装に際して、前提を確認しておきます。
iOS と watchOS の通信は全体の中では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/7585f37f5877-20251129.png)

両 OS では、以下の二つを定義することで双方向の通信ができるようになります。
- 相手側にファイルを送る処理（transferFile）
- 相手側からファイルが届いた時に実行する処理（didReceive file）
![](https://storage.googleapis.com/zenn-user-upload/42b1e25e14a5-20251129.png)

### watch 側の実装
watchOS で実現したい挙動は以下の通りです。

- iOS から送信されてきた画像ファイルを watchOS に保存する
- 受信した画像を一覧表示する

#### iOS との連絡部分
まずは iOS との連絡部分を実装していきます。
コードは以下の通りです。以下で詳しくみていきます。
```swift: ios/FlutterWatch Watch App/ImageWatchSessionManager.swift
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
```

それぞれ詳しくみていきます。

以下では、`ImageWatchSessionManager`を`ObservableObject`に準拠させています。これで外部からは`StateObject`や`EnvironmentObject`として扱うことができます。
`images`では受信済み画像のリストを保持しています。
`isReachable`では、iPhone と接続されているかどうかを保持しています。
```swift
class ImageWatchSessionManager: NSObject, ObservableObject {
    static let shared = ImageWatchSessionManager()

    private let session = WCSession.default

    @Published var images: [WatchImage] = []
    @Published var isReachable: Bool = false

    private let defaults = UserDefaults.standard
    private let imagesMetadataKey = "watch_images_metadata"
```

以下では、`ImageWatchSessionManager`の初期化処理を記述しています。
初期化処理では、WCSession がサポートされているかどうかを確認しています。
この辺りは他のメソッドと同様かと思います。
また、`loadImagesMetadata()`で保存されている画像のメタデータを読み込んでいます。
```swift
private override init() {
    super.init()

    guard WCSession.isSupported() else {
        return
    }

    loadImagesMetadata()

    session.delegate = self
    session.activate()
}
```

以下では、`ImageWatchSessionManager`の extension として`WCSessionDelegate`を定義しています。
このデリゲートで iOS 側との連絡を行います。
`activationDidCompleteWith`では、セッションのアクティベーションが完了した際に`isReachable`を更新する処理を行なっています。
`sessionReachabilityDidChange`では、iOS との通信が可能かどうかのステータスが変化した際に`isReachable`を更新する処理を行なっています。
```swift
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
```

以下では、`didReceive file:`で iOS からファイルを受け取った際の処理を記述しています。
`file.fileURL`からファイルの一時的な場所を取得し、`file.metadata`からメタデータを取得できます。
受信したファイルは適切な場所に移動する必要があります。
`DispatchQueue.main.async`でメインスレッドでの更新を保証しています。
```swift
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
```

次に、watchOS のアプリのエントリーポイントで、WCSession の初期化を行います。
コードは以下の通りです。
先ほど定義した`ImageWatchSessionManager`を`StateObject`で`ContentView`に渡しています。
```swift: ios/FlutterWatch Watch App/FlutterWatchApp.swift
import SwiftUI
import WatchConnectivity

@main
struct FlutterWatch_Watch_AppApp: App {
    @StateObject private var sessionManager = ImageWatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}
```

#### watchOS の UI 作成
次に`ContentView`の実装を行います。
コードは以下の通りで、シンプルな画像一覧画面になっています。
受信した画像をグリッド表示し、タップすると詳細画面に遷移できるようになっています。
```swift: ios/FlutterWatch Watch App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: ImageWatchSessionManager

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
```

これで watchOS 側の実装は完了です。
iOS 側から送信された画像ファイルを受信することができるようになりました。

### iOS 側の実装
次に iOS 側の実装を行います。
iOS で実現したい挙動は以下の通りです。
- iOS で受け付けた画像ファイルを watchOS 側に送信する
- 転送進捗を監視し、Flutter 側に通知する
- 転送履歴を管理する

#### watchOS との連絡部分
watchOS 側の実装と同様に、まずは相手のプラットフォームとの連絡部分を実装していきます。
コードは以下の通りです。
```swift: ios/Runner/ImageTransferWCSessionManager.swift
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
```

それぞれ詳しくみていきます。

以下では、iOS 側の`ImageTransferWCSessionManager`を`NSObject`として定義しています。
Flutter とのやり取りを行うための`ImageTransferFlutterApi`と、watchOS とのやり取りを行うための`WCSession`をそれぞれ保持しています。
また、進捗監視のためのプロパティも保持しています。
```swift
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
```

以下では、セッションを初期化する処理を記述しています。
`WCSession`のデリゲートを`ImageTransferWCSessionManager`自身に割り当て、セッションをアクティベートしています。この初期化処理によって watchOS との通信ができるようになります。
```swift
private override init() {
    super.init()

    guard WCSession.isSupported() else {
        return
    }

    session.delegate = self
    session.activate()
}
```

以下では、画像ファイルを watchOS 側に送信する処理を記述しています。
まず、画像データを一時ファイルとして保存します。
次に、メタデータを辞書型で作成し、`session.transferFile`でファイルを転送します。
`transferFile`メソッドは`WCSessionFileTransfer`を返し、これを使って進捗を監視できます。
送信後、`startMonitoringProgress`で進捗監視を開始しています。
```swift
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
```

以下では、転送進捗を監視する処理を実装しています。
`WCSessionFileTransfer.progress`の`fractionCompleted`を監視することで、転送進捗を取得できます。
また、定期的に進捗を更新するタイマーも開始しています。
```swift
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
```

以下では、転送進捗を計算する処理を実装しています。
転送速度や残り時間も計算できます。
```swift
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
```

以下では、進行中の転送一覧を取得する処理を実装しています。
`outstandingFileTransfers`でキューに残っているファイル転送を確認できます。
```swift
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
```

以下では、特定のファイルの転送をキャンセルする処理を実装しています。
`outstandingFileTransfers`から該当するファイルを見つけて、`cancel()`を呼び出します。
```swift
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
```

以下では watchOS 側の実装と同様に`ImageTransferWCSessionManager`を`WCSessionDelegate`に準拠させています。
セッションのアクティベーションが完了した時に Flutter 側に接続状態を通知するようにしています。
```swift
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
```

以下では、`didFinish fileTransfer`, `error`で転送完了時の挙動を定義しています。
このメソッドは、転送が成功または失敗した際に呼ばれます。
転送が成功した場合は、転送履歴を更新し、Flutter 側に通知します。
転送が失敗した場合も同様に、転送履歴を更新し、Flutter 側にエラーを通知します。
```swift
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
```

#### AppDelegate の修正
次に AppDelegate の修正を行います。
コードは以下の通りです。
```swift: ios/Runner/AppDelegate.swift
import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    // ImageTransferWCSessionManagerの初期化
    let imageTransferSessionManager = ImageTransferWCSessionManager.shared
    imageTransferSessionManager.setupFlutterApi(binaryMessenger: controller.binaryMessenger)

    // Pigeon HostApiの登録
    let imageTransferHostApi = ImageTransferHostApiImpl(sessionManager: imageTransferSessionManager)
    ImageTransferHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: imageTransferHostApi)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

それぞれ詳しくみていきます。
以下では、`FlutterViewController`を使って Pigeon の API を使用できるようにしています。
`ImageTransferWCSessionManager`のインスタンスを取得し、Flutter API を設定しています。
また、Pigeon の HostApi を登録しています。

```swift
let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

// ImageTransferWCSessionManagerの初期化
let imageTransferSessionManager = ImageTransferWCSessionManager.shared
imageTransferSessionManager.setupFlutterApi(binaryMessenger: controller.binaryMessenger)

// Pigeon HostApiの登録
let imageTransferHostApi = ImageTransferHostApiImpl(sessionManager: imageTransferSessionManager)
ImageTransferHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: imageTransferHostApi)
```
これで iOS と watchOS 間のデータのやり取りの実装は完了です。

## iOS と Flutter 間のデータのやり取り
次に iOS と Flutter 間のデータのやり取りを実装します。
iOS と Flutter 間の通信は全体の中では以下の赤枠部分に当たります。
![](https://storage.googleapis.com/zenn-user-upload/0f3c873fe75d-20251129.png)

以下の手順で進めていきます。
1. Pigeon API の定義
2. Service 層の定義
3. Provider の定義
4. UI の作成

### 1. Pigeon API の定義
まず、Flutter と iOS 間の通信を行うための Pigeon API を定義します。
コードは以下の通りです。
```dart: lib/pigeon/image_transfer_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/pigeon/image_transfer_api.g.dart',
  swiftOut: 'ios/Runner/Pigeon/ImageTransferApi.g.swift',
  swiftOptions: SwiftOptions(),
))

class ImageMetadata {
  final String id;
  final String fileName;
  final int fileSize;
  final int width;
  final int height;
  final double timestamp;

  ImageMetadata({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.timestamp,
  });
}

class TransferProgress {
  final String imageId;
  final double progress;
  final int bytesTransferred;
  final int totalBytes;
  final double transferSpeed;
  final double estimatedTimeRemaining;

  TransferProgress({
    required this.imageId,
    required this.progress,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.transferSpeed,
    required this.estimatedTimeRemaining,
  });
}

class TransferHistoryItem {
  final ImageMetadata metadata;
  final int status; // 0: pending, 1: transferring, 2: completed, 3: failed, 4: cancelled
  final double? completedAt;

  TransferHistoryItem({
    required this.metadata,
    required this.status,
    this.completedAt,
  });
}

@HostApi()
abstract class ImageTransferHostApi {
  @async
  void transferImage(Uint8List imageData, ImageMetadata metadata);
  void cancelTransfer(String imageId);
  List<TransferHistoryItem> getTransferHistory();
  List<TransferProgress> getActiveTransfers();
}

@FlutterApi()
abstract class ImageTransferFlutterApi {
  void onProgressUpdated(TransferProgress progress);
  void onTransferCompleted(String imageId);
  void onTransferFailed(String imageId, String error);
}
```

以下では、画像メタデータを表すクラスを定義しています。
`ImageMetadata`は、画像ID、ファイル名、ファイルサイズ、幅、高さ、タイムスタンプを保持します。
```dart
class ImageMetadata {
  final String id;
  final String fileName;
  final int fileSize;
  final int width;
  final int height;
  final double timestamp;

  ImageMetadata({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.timestamp,
  });
}
```

以下では、転送進捗を表すクラスを定義しています。
`TransferProgress`は、画像ID、進捗率、転送済みバイト数、総バイト数、転送速度、残り時間を保持します。
```dart
class TransferProgress {
  final String imageId;
  final double progress;
  final int bytesTransferred;
  final int totalBytes;
  final double transferSpeed;
  final double estimatedTimeRemaining;

  TransferProgress({
    required this.imageId,
    required this.progress,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.transferSpeed,
    required this.estimatedTimeRemaining,
  });
}
```

以下では、転送履歴項目を表すクラスを定義しています。
`TransferHistoryItem`は、メタデータ、転送ステータス、完了時刻を保持します。
```dart
class TransferHistoryItem {
  final ImageMetadata metadata;
  final int status; // 0: pending, 1: transferring, 2: completed, 3: failed, 4: cancelled
  final double? completedAt;

  TransferHistoryItem({
    required this.metadata,
    required this.status,
    this.completedAt,
  });
}
```

以下では、Flutter から iOS に対して実行する処理を記述しています。
Flutter から各プラットフォームに対して実行する処理は`@HostApi()`アノテーションをつけて、`abstract`つまり抽象クラスとしてまとめて定義します。
Flutter 側からは以下のメソッドを呼び出したいのでそれぞれ定義しています。
- 画像の転送
- 転送のキャンセル
- 転送履歴の取得
- 進行中の転送の取得

```dart
@HostApi()
abstract class ImageTransferHostApi {
  @async
  void transferImage(Uint8List imageData, ImageMetadata metadata);
  void cancelTransfer(String imageId);
  List<TransferHistoryItem> getTransferHistory();
  List<TransferProgress> getActiveTransfers();
}
```

以下では iOS から Flutter に対して実行する処理を記述しています。上記の`@HostApi()`の逆です。
iOS から Flutter へは以下のメソッドを呼び出したいのでそれぞれ定義しています。
- 転送進捗の更新通知
- 転送完了通知
- 転送失敗通知

```dart
@FlutterApi()
abstract class ImageTransferFlutterApi {
  void onProgressUpdated(TransferProgress progress);
  void onTransferCompleted(String imageId);
  void onTransferFailed(String imageId, String error);
}
```

### 2. Service 層の定義
次に、Flutter 側で iOS とのやり取りを行うサービスの定義をしていきます。
コードは以下の通りです。
```dart: lib/services/image_transfer_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_watch/models/image_transfer.dart';
import 'package:flutter_watch/pigeon/image_transfer_api.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_transfer_service.g.dart';

@riverpod
ImageTransferService imageTransferService(Ref ref) {
  return ImageTransferService();
}

class ImageTransferService implements ImageTransferFlutterApi {
  final ImageTransferHostApi _hostApi = ImageTransferHostApi();

  Function(AppTransferProgress)? progressUpdatedCallback;
  Function(String)? transferCompletedCallback;
  Function(String, String)? transferFailedCallback;

  ImageTransferService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    ImageTransferFlutterApi.setUp(this);
  }

  @override
  void onProgressUpdated(TransferProgress progress) {
    try {
      final appProgress = AppTransferProgress.fromPigeon(progress);
      progressUpdatedCallback?.call(appProgress);
    } catch (e) {
      debugPrint('Flutter: Error handling progress update: $e');
    }
  }

  @override
  void onTransferCompleted(String imageId) {
    transferCompletedCallback?.call(imageId);
  }

  @override
  void onTransferFailed(String imageId, String error) {
    transferFailedCallback?.call(imageId, error);
  }

  Future<void> transferImage(
    Uint8List imageData,
    AppImageMetadata metadata,
  ) async {
    try {
      await _hostApi.transferImage(imageData, metadata.toPigeon());
    } catch (e) {
      debugPrint('Flutter: Error initiating transfer: $e');
      rethrow;
    }
  }

  Future<void> cancelTransfer(String imageId) async {
    try {
      _hostApi.cancelTransfer(imageId);
    } catch (e) {
      debugPrint('Flutter: Error cancelling transfer: $e');
      rethrow;
    }
  }

  Future<List<AppTransferHistoryItem>> getTransferHistory() async {
    try {
      final historyData = await _hostApi.getTransferHistory();
      final history = historyData
          .map((item) => AppTransferHistoryItem.fromPigeon(item))
          .toList();
      return history;
    } catch (e) {
      debugPrint('Flutter: Error getting transfer history: $e');
      return [];
    }
  }

  Future<List<AppTransferProgress>> getActiveTransfers() async {
    try {
      final transfersData = await _hostApi.getActiveTransfers();
      final transfers = transfersData
          .map((progress) => AppTransferProgress.fromPigeon(progress))
          .toList();
      return transfers;
    } catch (e) {
      debugPrint('Flutter: Error getting active transfers: $e');
      return [];
    }
  }
}
```

以下では、iOS と画像転送に関する通信を行うための Service を定義しています。
また、初期化の段階で`_setupFlutterApi`メソッドを実行しています。
```dart
class ImageTransferService implements ImageTransferFlutterApi {
  final ImageTransferHostApi _hostApi = ImageTransferHostApi();

  Function(AppTransferProgress)? progressUpdatedCallback;
  Function(String)? transferCompletedCallback;
  Function(String, String)? transferFailedCallback;

  ImageTransferService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    ImageTransferFlutterApi.setUp(this);
  }
```

以下では、iOS から転送進捗が更新された際の処理を記述しています。
`onProgressUpdated`で進捗を受け取り、コールバックを呼び出しています。
```dart
@override
void onProgressUpdated(TransferProgress progress) {
  try {
    final appProgress = AppTransferProgress.fromPigeon(progress);
    progressUpdatedCallback?.call(appProgress);
  } catch (e) {
    debugPrint('Flutter: Error handling progress update: $e');
  }
}
```

以下では、Pigeon の HostApi で`transferImage`イベントを送信して、iOS 側の画像を転送するためのメソッドを実装しています。
```dart
Future<void> transferImage(
  Uint8List imageData,
  AppImageMetadata metadata,
) async {
  try {
    await _hostApi.transferImage(imageData, metadata.toPigeon());
  } catch (e) {
    debugPrint('Flutter: Error initiating transfer: $e');
    rethrow;
  }
}
```

### 3. Provider の定義
次に Flutter 側で必要な Provider の定義をしていきます。
コードは以下の通りです。
```dart: lib/providers/image_transfer_provider.dart
import 'package:flutter_watch/models/image_transfer.dart';
import 'package:flutter_watch/services/image_transfer_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:typed_data';

part 'image_transfer_provider.g.dart';

@riverpod
class TransferHistory extends _$TransferHistory {
  @override
  Future<List<AppTransferHistoryItem>> build() async {
    final service = ref.watch(imageTransferServiceProvider);

    service.transferCompletedCallback = (_) => refresh();
    service.transferFailedCallback = (_, __) => refresh();

    return service.getTransferHistory();
  }

  Future<void> refresh() async {
    final service = ref.read(imageTransferServiceProvider);
    state = AsyncData(await service.getTransferHistory());
  }

  Future<void> transferImage(
    Uint8List imageData,
    AppImageMetadata metadata,
  ) async {
    final service = ref.read(imageTransferServiceProvider);
    await service.transferImage(imageData, metadata);
    await refresh();
  }
}

@riverpod
class ActiveTransfers extends _$ActiveTransfers {
  @override
  Future<List<AppTransferProgress>> build() async {
    final service = ref.watch(imageTransferServiceProvider);

    service.progressUpdatedCallback = (progress) {
      final currentTransfers = state.value ?? [];
      final index =
          currentTransfers.indexWhere((t) => t.imageId == progress.imageId);

      if (index >= 0) {
        final updatedTransfers = List<AppTransferProgress>.from(currentTransfers);
        updatedTransfers[index] = progress;
        state = AsyncData(updatedTransfers);
      } else {
        state = AsyncData([...currentTransfers, progress]);
      }
    };

    service.transferCompletedCallback = (imageId) {
      final currentTransfers = state.value ?? [];
      final updatedTransfers =
          currentTransfers.where((t) => t.imageId != imageId).toList();
      state = AsyncData(updatedTransfers);
      ref.read(transferHistoryProvider.notifier).refresh();
    };

    service.transferFailedCallback = (imageId, error) {
      final currentTransfers = state.value ?? [];
      final updatedTransfers =
          currentTransfers.where((t) => t.imageId != imageId).toList();
      state = AsyncData(updatedTransfers);
      ref.read(transferHistoryProvider.notifier).refresh();
    };

    return service.getActiveTransfers();
  }

  Future<void> cancelTransfer(String imageId) async {
    final service = ref.read(imageTransferServiceProvider);
    await service.cancelTransfer(imageId);

    final currentTransfers = state.value ?? [];
    final updatedTransfers =
        currentTransfers.where((t) => t.imageId != imageId).toList();
    state = AsyncData(updatedTransfers);
  }
}
```

以下では、転送履歴の状態を管理する Provider を定義しています。
`build`メソッドで、Service のコールバックを設定し、転送が完了または失敗した際に状態を更新するようにしています。

```dart
@riverpod
class TransferHistory extends _$TransferHistory {
  @override
  Future<List<AppTransferHistoryItem>> build() async {
    final service = ref.watch(imageTransferServiceProvider);

    service.transferCompletedCallback = (_) => refresh();
    service.transferFailedCallback = (_, __) => refresh();

    return service.getTransferHistory();
  }
```

以下では、画像を転送するメソッドを実装しています。
Service を通じて iOS 側に画像を送信しています。
```dart
Future<void> transferImage(
  Uint8List imageData,
  AppImageMetadata metadata,
) async {
  final service = ref.read(imageTransferServiceProvider);
  await service.transferImage(imageData, metadata);
  await refresh();
}
```

以下では、進行中の転送の状態を管理する Provider を定義しています。
`build`メソッドで、Service のコールバックを設定し、転送進捗が更新された際に状態を更新するようにしています。
```dart
@riverpod
class ActiveTransfers extends _$ActiveTransfers {
  @override
  Future<List<AppTransferProgress>> build() async {
    final service = ref.watch(imageTransferServiceProvider);

    service.progressUpdatedCallback = (progress) {
      final currentTransfers = state.value ?? [];
      final index =
          currentTransfers.indexWhere((t) => t.imageId == progress.imageId);

      if (index >= 0) {
        final updatedTransfers = List<AppTransferProgress>.from(currentTransfers);
        updatedTransfers[index] = progress;
        state = AsyncData(updatedTransfers);
      } else {
        state = AsyncData([...currentTransfers, progress]);
      }
    };
```

### 4. UI の作成
次に UI を作成していきます。
コードは以下の通りです。
```dart: lib/pages/image_transfer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_watch/models/image_transfer.dart';
import 'package:flutter_watch/providers/image_transfer_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ImageTransferPage extends ConsumerWidget {
  const ImageTransferPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferHistory = ref.watch(transferHistoryProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Transfer'),
      ),
      body: Column(
        children: [
          // 画像選択と転送ボタン
          // 進行中の転送一覧
          // 転送履歴一覧
        ],
      ),
    );
  }
}
```

以下では、画像転送画面の UI を実装しています。
各セクションで画像を選択して転送できるようになっており、画像が転送されると自動的に iOS 側に送信され、watchOS 側にも反映されます。
また、転送進捗も表示されるようになっています。
```dart
class ImageTransferPage extends ConsumerWidget {
  const ImageTransferPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferHistory = ref.watch(transferHistoryProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Transfer'),
      ),
      body: Column(
        children: [
          // 画像選択と転送ボタン
          // 進行中の転送一覧
          // 転送履歴一覧
        ],
      ),
    );
  }
}
```

これで、watchOS、iOS、Flutter を繋ぐ画像転送アプリの実装が完了しました。

## まとめ
この章では、`transferFile`を使って画像ファイルを転送するアプリを実装しました。
`transferFile`の特徴をまとめると以下のようになります。

- ファイル転送専用である
- 進捗監視が可能である
- すべてのファイルがキューに保持される
- 送信順序が保証される
- オフライン時でも動作する
- 到達可能性のチェックが不要
- ファイル転送に適している

## 参考

