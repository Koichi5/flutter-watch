// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppImageMetadataImpl _$$AppImageMetadataImplFromJson(
  Map<String, dynamic> json,
) => _$AppImageMetadataImpl(
  id: json['id'] as String,
  fileName: json['fileName'] as String,
  fileSize: (json['fileSize'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$AppImageMetadataImplToJson(
  _$AppImageMetadataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'fileName': instance.fileName,
  'fileSize': instance.fileSize,
  'width': instance.width,
  'height': instance.height,
  'timestamp': instance.timestamp.toIso8601String(),
};

_$AppTransferProgressImpl _$$AppTransferProgressImplFromJson(
  Map<String, dynamic> json,
) => _$AppTransferProgressImpl(
  imageId: json['imageId'] as String,
  progress: (json['progress'] as num).toDouble(),
  bytesTransferred: (json['bytesTransferred'] as num).toInt(),
  totalBytes: (json['totalBytes'] as num).toInt(),
  transferSpeed: (json['transferSpeed'] as num).toDouble(),
  estimatedTimeRemaining: (json['estimatedTimeRemaining'] as num).toDouble(),
);

Map<String, dynamic> _$$AppTransferProgressImplToJson(
  _$AppTransferProgressImpl instance,
) => <String, dynamic>{
  'imageId': instance.imageId,
  'progress': instance.progress,
  'bytesTransferred': instance.bytesTransferred,
  'totalBytes': instance.totalBytes,
  'transferSpeed': instance.transferSpeed,
  'estimatedTimeRemaining': instance.estimatedTimeRemaining,
};

_$AppTransferHistoryItemImpl _$$AppTransferHistoryItemImplFromJson(
  Map<String, dynamic> json,
) => _$AppTransferHistoryItemImpl(
  metadata: AppImageMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  status: $enumDecode(_$TransferStatusEnumMap, json['status']),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$$AppTransferHistoryItemImplToJson(
  _$AppTransferHistoryItemImpl instance,
) => <String, dynamic>{
  'metadata': instance.metadata,
  'status': _$TransferStatusEnumMap[instance.status]!,
  'completedAt': instance.completedAt?.toIso8601String(),
};

const _$TransferStatusEnumMap = {
  TransferStatus.pending: 'pending',
  TransferStatus.transferring: 'transferring',
  TransferStatus.completed: 'completed',
  TransferStatus.failed: 'failed',
  TransferStatus.cancelled: 'cancelled',
};
