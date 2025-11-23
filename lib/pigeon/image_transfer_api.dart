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


