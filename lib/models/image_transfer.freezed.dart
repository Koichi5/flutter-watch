// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_transfer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppImageMetadata _$AppImageMetadataFromJson(Map<String, dynamic> json) {
  return _AppImageMetadata.fromJson(json);
}

/// @nodoc
mixin _$AppImageMetadata {
  String get id => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  int get fileSize => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this AppImageMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppImageMetadataCopyWith<AppImageMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppImageMetadataCopyWith<$Res> {
  factory $AppImageMetadataCopyWith(
    AppImageMetadata value,
    $Res Function(AppImageMetadata) then,
  ) = _$AppImageMetadataCopyWithImpl<$Res, AppImageMetadata>;
  @useResult
  $Res call({
    String id,
    String fileName,
    int fileSize,
    int width,
    int height,
    DateTime timestamp,
  });
}

/// @nodoc
class _$AppImageMetadataCopyWithImpl<$Res, $Val extends AppImageMetadata>
    implements $AppImageMetadataCopyWith<$Res> {
  _$AppImageMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? width = null,
    Object? height = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fileName: null == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                      as String,
            fileSize: null == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int,
            width: null == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as int,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as int,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppImageMetadataImplCopyWith<$Res>
    implements $AppImageMetadataCopyWith<$Res> {
  factory _$$AppImageMetadataImplCopyWith(
    _$AppImageMetadataImpl value,
    $Res Function(_$AppImageMetadataImpl) then,
  ) = __$$AppImageMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fileName,
    int fileSize,
    int width,
    int height,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$AppImageMetadataImplCopyWithImpl<$Res>
    extends _$AppImageMetadataCopyWithImpl<$Res, _$AppImageMetadataImpl>
    implements _$$AppImageMetadataImplCopyWith<$Res> {
  __$$AppImageMetadataImplCopyWithImpl(
    _$AppImageMetadataImpl _value,
    $Res Function(_$AppImageMetadataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? width = null,
    Object? height = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$AppImageMetadataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fileName: null == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String,
        fileSize: null == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int,
        width: null == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as int,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as int,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppImageMetadataImpl extends _AppImageMetadata {
  const _$AppImageMetadataImpl({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.timestamp,
  }) : super._();

  factory _$AppImageMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppImageMetadataImplFromJson(json);

  @override
  final String id;
  @override
  final String fileName;
  @override
  final int fileSize;
  @override
  final int width;
  @override
  final int height;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'AppImageMetadata(id: $id, fileName: $fileName, fileSize: $fileSize, width: $width, height: $height, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppImageMetadataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fileName,
    fileSize,
    width,
    height,
    timestamp,
  );

  /// Create a copy of AppImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppImageMetadataImplCopyWith<_$AppImageMetadataImpl> get copyWith =>
      __$$AppImageMetadataImplCopyWithImpl<_$AppImageMetadataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppImageMetadataImplToJson(this);
  }
}

abstract class _AppImageMetadata extends AppImageMetadata {
  const factory _AppImageMetadata({
    required final String id,
    required final String fileName,
    required final int fileSize,
    required final int width,
    required final int height,
    required final DateTime timestamp,
  }) = _$AppImageMetadataImpl;
  const _AppImageMetadata._() : super._();

  factory _AppImageMetadata.fromJson(Map<String, dynamic> json) =
      _$AppImageMetadataImpl.fromJson;

  @override
  String get id;
  @override
  String get fileName;
  @override
  int get fileSize;
  @override
  int get width;
  @override
  int get height;
  @override
  DateTime get timestamp;

  /// Create a copy of AppImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppImageMetadataImplCopyWith<_$AppImageMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppTransferProgress _$AppTransferProgressFromJson(Map<String, dynamic> json) {
  return _AppTransferProgress.fromJson(json);
}

/// @nodoc
mixin _$AppTransferProgress {
  String get imageId => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  int get bytesTransferred => throw _privateConstructorUsedError;
  int get totalBytes => throw _privateConstructorUsedError;
  double get transferSpeed => throw _privateConstructorUsedError;
  double get estimatedTimeRemaining => throw _privateConstructorUsedError;

  /// Serializes this AppTransferProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppTransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppTransferProgressCopyWith<AppTransferProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppTransferProgressCopyWith<$Res> {
  factory $AppTransferProgressCopyWith(
    AppTransferProgress value,
    $Res Function(AppTransferProgress) then,
  ) = _$AppTransferProgressCopyWithImpl<$Res, AppTransferProgress>;
  @useResult
  $Res call({
    String imageId,
    double progress,
    int bytesTransferred,
    int totalBytes,
    double transferSpeed,
    double estimatedTimeRemaining,
  });
}

/// @nodoc
class _$AppTransferProgressCopyWithImpl<$Res, $Val extends AppTransferProgress>
    implements $AppTransferProgressCopyWith<$Res> {
  _$AppTransferProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppTransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageId = null,
    Object? progress = null,
    Object? bytesTransferred = null,
    Object? totalBytes = null,
    Object? transferSpeed = null,
    Object? estimatedTimeRemaining = null,
  }) {
    return _then(
      _value.copyWith(
            imageId: null == imageId
                ? _value.imageId
                : imageId // ignore: cast_nullable_to_non_nullable
                      as String,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            bytesTransferred: null == bytesTransferred
                ? _value.bytesTransferred
                : bytesTransferred // ignore: cast_nullable_to_non_nullable
                      as int,
            totalBytes: null == totalBytes
                ? _value.totalBytes
                : totalBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            transferSpeed: null == transferSpeed
                ? _value.transferSpeed
                : transferSpeed // ignore: cast_nullable_to_non_nullable
                      as double,
            estimatedTimeRemaining: null == estimatedTimeRemaining
                ? _value.estimatedTimeRemaining
                : estimatedTimeRemaining // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppTransferProgressImplCopyWith<$Res>
    implements $AppTransferProgressCopyWith<$Res> {
  factory _$$AppTransferProgressImplCopyWith(
    _$AppTransferProgressImpl value,
    $Res Function(_$AppTransferProgressImpl) then,
  ) = __$$AppTransferProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String imageId,
    double progress,
    int bytesTransferred,
    int totalBytes,
    double transferSpeed,
    double estimatedTimeRemaining,
  });
}

/// @nodoc
class __$$AppTransferProgressImplCopyWithImpl<$Res>
    extends _$AppTransferProgressCopyWithImpl<$Res, _$AppTransferProgressImpl>
    implements _$$AppTransferProgressImplCopyWith<$Res> {
  __$$AppTransferProgressImplCopyWithImpl(
    _$AppTransferProgressImpl _value,
    $Res Function(_$AppTransferProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppTransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageId = null,
    Object? progress = null,
    Object? bytesTransferred = null,
    Object? totalBytes = null,
    Object? transferSpeed = null,
    Object? estimatedTimeRemaining = null,
  }) {
    return _then(
      _$AppTransferProgressImpl(
        imageId: null == imageId
            ? _value.imageId
            : imageId // ignore: cast_nullable_to_non_nullable
                  as String,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        bytesTransferred: null == bytesTransferred
            ? _value.bytesTransferred
            : bytesTransferred // ignore: cast_nullable_to_non_nullable
                  as int,
        totalBytes: null == totalBytes
            ? _value.totalBytes
            : totalBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        transferSpeed: null == transferSpeed
            ? _value.transferSpeed
            : transferSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
        estimatedTimeRemaining: null == estimatedTimeRemaining
            ? _value.estimatedTimeRemaining
            : estimatedTimeRemaining // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppTransferProgressImpl extends _AppTransferProgress {
  const _$AppTransferProgressImpl({
    required this.imageId,
    required this.progress,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.transferSpeed,
    required this.estimatedTimeRemaining,
  }) : super._();

  factory _$AppTransferProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppTransferProgressImplFromJson(json);

  @override
  final String imageId;
  @override
  final double progress;
  @override
  final int bytesTransferred;
  @override
  final int totalBytes;
  @override
  final double transferSpeed;
  @override
  final double estimatedTimeRemaining;

  @override
  String toString() {
    return 'AppTransferProgress(imageId: $imageId, progress: $progress, bytesTransferred: $bytesTransferred, totalBytes: $totalBytes, transferSpeed: $transferSpeed, estimatedTimeRemaining: $estimatedTimeRemaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppTransferProgressImpl &&
            (identical(other.imageId, imageId) || other.imageId == imageId) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.bytesTransferred, bytesTransferred) ||
                other.bytesTransferred == bytesTransferred) &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.transferSpeed, transferSpeed) ||
                other.transferSpeed == transferSpeed) &&
            (identical(other.estimatedTimeRemaining, estimatedTimeRemaining) ||
                other.estimatedTimeRemaining == estimatedTimeRemaining));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    imageId,
    progress,
    bytesTransferred,
    totalBytes,
    transferSpeed,
    estimatedTimeRemaining,
  );

  /// Create a copy of AppTransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppTransferProgressImplCopyWith<_$AppTransferProgressImpl> get copyWith =>
      __$$AppTransferProgressImplCopyWithImpl<_$AppTransferProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppTransferProgressImplToJson(this);
  }
}

abstract class _AppTransferProgress extends AppTransferProgress {
  const factory _AppTransferProgress({
    required final String imageId,
    required final double progress,
    required final int bytesTransferred,
    required final int totalBytes,
    required final double transferSpeed,
    required final double estimatedTimeRemaining,
  }) = _$AppTransferProgressImpl;
  const _AppTransferProgress._() : super._();

  factory _AppTransferProgress.fromJson(Map<String, dynamic> json) =
      _$AppTransferProgressImpl.fromJson;

  @override
  String get imageId;
  @override
  double get progress;
  @override
  int get bytesTransferred;
  @override
  int get totalBytes;
  @override
  double get transferSpeed;
  @override
  double get estimatedTimeRemaining;

  /// Create a copy of AppTransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppTransferProgressImplCopyWith<_$AppTransferProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppTransferHistoryItem _$AppTransferHistoryItemFromJson(
  Map<String, dynamic> json,
) {
  return _AppTransferHistoryItem.fromJson(json);
}

/// @nodoc
mixin _$AppTransferHistoryItem {
  AppImageMetadata get metadata => throw _privateConstructorUsedError;
  TransferStatus get status => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this AppTransferHistoryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppTransferHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppTransferHistoryItemCopyWith<AppTransferHistoryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppTransferHistoryItemCopyWith<$Res> {
  factory $AppTransferHistoryItemCopyWith(
    AppTransferHistoryItem value,
    $Res Function(AppTransferHistoryItem) then,
  ) = _$AppTransferHistoryItemCopyWithImpl<$Res, AppTransferHistoryItem>;
  @useResult
  $Res call({
    AppImageMetadata metadata,
    TransferStatus status,
    DateTime? completedAt,
  });

  $AppImageMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$AppTransferHistoryItemCopyWithImpl<
  $Res,
  $Val extends AppTransferHistoryItem
>
    implements $AppTransferHistoryItemCopyWith<$Res> {
  _$AppTransferHistoryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppTransferHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? status = null,
    Object? completedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as AppImageMetadata,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TransferStatus,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of AppTransferHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppImageMetadataCopyWith<$Res> get metadata {
    return $AppImageMetadataCopyWith<$Res>(_value.metadata, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppTransferHistoryItemImplCopyWith<$Res>
    implements $AppTransferHistoryItemCopyWith<$Res> {
  factory _$$AppTransferHistoryItemImplCopyWith(
    _$AppTransferHistoryItemImpl value,
    $Res Function(_$AppTransferHistoryItemImpl) then,
  ) = __$$AppTransferHistoryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AppImageMetadata metadata,
    TransferStatus status,
    DateTime? completedAt,
  });

  @override
  $AppImageMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$$AppTransferHistoryItemImplCopyWithImpl<$Res>
    extends
        _$AppTransferHistoryItemCopyWithImpl<$Res, _$AppTransferHistoryItemImpl>
    implements _$$AppTransferHistoryItemImplCopyWith<$Res> {
  __$$AppTransferHistoryItemImplCopyWithImpl(
    _$AppTransferHistoryItemImpl _value,
    $Res Function(_$AppTransferHistoryItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppTransferHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? status = null,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$AppTransferHistoryItemImpl(
        metadata: null == metadata
            ? _value.metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as AppImageMetadata,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TransferStatus,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppTransferHistoryItemImpl extends _AppTransferHistoryItem {
  const _$AppTransferHistoryItemImpl({
    required this.metadata,
    required this.status,
    this.completedAt,
  }) : super._();

  factory _$AppTransferHistoryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppTransferHistoryItemImplFromJson(json);

  @override
  final AppImageMetadata metadata;
  @override
  final TransferStatus status;
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'AppTransferHistoryItem(metadata: $metadata, status: $status, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppTransferHistoryItemImpl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, metadata, status, completedAt);

  /// Create a copy of AppTransferHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppTransferHistoryItemImplCopyWith<_$AppTransferHistoryItemImpl>
  get copyWith =>
      __$$AppTransferHistoryItemImplCopyWithImpl<_$AppTransferHistoryItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppTransferHistoryItemImplToJson(this);
  }
}

abstract class _AppTransferHistoryItem extends AppTransferHistoryItem {
  const factory _AppTransferHistoryItem({
    required final AppImageMetadata metadata,
    required final TransferStatus status,
    final DateTime? completedAt,
  }) = _$AppTransferHistoryItemImpl;
  const _AppTransferHistoryItem._() : super._();

  factory _AppTransferHistoryItem.fromJson(Map<String, dynamic> json) =
      _$AppTransferHistoryItemImpl.fromJson;

  @override
  AppImageMetadata get metadata;
  @override
  TransferStatus get status;
  @override
  DateTime? get completedAt;

  /// Create a copy of AppTransferHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppTransferHistoryItemImplCopyWith<_$AppTransferHistoryItemImpl>
  get copyWith => throw _privateConstructorUsedError;
}
