import 'package:freezed_annotation/freezed_annotation.dart';
import '../pigeon/image_transfer_api.g.dart' as pigeon;

part 'image_transfer.freezed.dart';
part 'image_transfer.g.dart';

enum TransferStatus {
  pending,
  transferring,
  completed,
  failed,
  cancelled;

  int toInt() => index;
  static TransferStatus fromInt(int value) => TransferStatus.values[value];
}

@freezed
class AppImageMetadata with _$AppImageMetadata {
  const AppImageMetadata._();

  const factory AppImageMetadata({
    required String id,
    required String fileName,
    required int fileSize,
    required int width,
    required int height,
    required DateTime timestamp,
  }) = _AppImageMetadata;

  factory AppImageMetadata.fromJson(Map<String, dynamic> json) =>
      _$AppImageMetadataFromJson(json);

  pigeon.ImageMetadata toPigeon() {
    return pigeon.ImageMetadata(
      id: id,
      fileName: fileName,
      fileSize: fileSize,
      width: width,
      height: height,
      timestamp: timestamp.millisecondsSinceEpoch / 1000.0,
    );
  }

  factory AppImageMetadata.fromPigeon(pigeon.ImageMetadata data) {
    return AppImageMetadata(
      id: data.id,
      fileName: data.fileName,
      fileSize: data.fileSize,
      width: data.width,
      height: data.height,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data.timestamp * 1000).toInt(),
      ),
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get resolution => '${width}x$height';
}

@freezed
class AppTransferProgress with _$AppTransferProgress {
  const AppTransferProgress._();

  const factory AppTransferProgress({
    required String imageId,
    required double progress,
    required int bytesTransferred,
    required int totalBytes,
    required double transferSpeed,
    required double estimatedTimeRemaining,
  }) = _AppTransferProgress;

  factory AppTransferProgress.fromJson(Map<String, dynamic> json) =>
      _$AppTransferProgressFromJson(json);

  factory AppTransferProgress.fromPigeon(pigeon.TransferProgress data) {
    return AppTransferProgress(
      imageId: data.imageId,
      progress: data.progress,
      bytesTransferred: data.bytesTransferred,
      totalBytes: data.totalBytes,
      transferSpeed: data.transferSpeed,
      estimatedTimeRemaining: data.estimatedTimeRemaining,
    );
  }

  int get progressPercent => (progress * 100).toInt();

  String get transferSpeedFormatted {
    if (transferSpeed < 1024) {
      return '${transferSpeed.toStringAsFixed(0)} B/s';
    } else if (transferSpeed < 1024 * 1024) {
      return '${(transferSpeed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(transferSpeed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  String get estimatedTimeRemainingFormatted {
    if (estimatedTimeRemaining < 60) {
      return '${estimatedTimeRemaining.toStringAsFixed(0)}秒';
    } else if (estimatedTimeRemaining < 3600) {
      return '${(estimatedTimeRemaining / 60).toStringAsFixed(0)}分';
    } else {
      return '${(estimatedTimeRemaining / 3600).toStringAsFixed(1)}時間';
    }
  }

  String get bytesTransferredFormatted {
    if (bytesTransferred < 1024) {
      return '$bytesTransferred B';
    } else if (bytesTransferred < 1024 * 1024) {
      return '${(bytesTransferred / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytesTransferred / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get totalBytesFormatted {
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

@freezed
class AppTransferHistoryItem with _$AppTransferHistoryItem {
  const AppTransferHistoryItem._();

  const factory AppTransferHistoryItem({
    required AppImageMetadata metadata,
    required TransferStatus status,
    DateTime? completedAt,
  }) = _AppTransferHistoryItem;

  factory AppTransferHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$AppTransferHistoryItemFromJson(json);

  factory AppTransferHistoryItem.fromPigeon(pigeon.TransferHistoryItem data) {
    return AppTransferHistoryItem(
      metadata: AppImageMetadata.fromPigeon(data.metadata),
      status: TransferStatus.fromInt(data.status),
      completedAt: data.completedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data.completedAt! * 1000).toInt(),
            )
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case TransferStatus.pending:
        return '待機中';
      case TransferStatus.transferring:
        return '転送中';
      case TransferStatus.completed:
        return '完了';
      case TransferStatus.failed:
        return '失敗';
      case TransferStatus.cancelled:
        return 'キャンセル';
    }
  }

  String get statusColor {
    switch (status) {
      case TransferStatus.pending:
        return 'gray';
      case TransferStatus.transferring:
        return 'blue';
      case TransferStatus.completed:
        return 'green';
      case TransferStatus.failed:
        return 'red';
      case TransferStatus.cancelled:
        return 'orange';
    }
  }
}


