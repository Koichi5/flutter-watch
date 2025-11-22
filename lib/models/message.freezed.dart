// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  MessageSender get sender => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call({
    String id,
    String text,
    MessageSender sender,
    DateTime timestamp,
    bool isRead,
  });
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? sender = null,
    Object? timestamp = null,
    Object? isRead = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            sender: null == sender
                ? _value.sender
                : sender // ignore: cast_nullable_to_non_nullable
                      as MessageSender,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isRead: null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
    _$MessageImpl value,
    $Res Function(_$MessageImpl) then,
  ) = __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String text,
    MessageSender sender,
    DateTime timestamp,
    bool isRead,
  });
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
    _$MessageImpl _value,
    $Res Function(_$MessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? sender = null,
    Object? timestamp = null,
    Object? isRead = null,
  }) {
    return _then(
      _$MessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        sender: null == sender
            ? _value.sender
            : sender // ignore: cast_nullable_to_non_nullable
                  as MessageSender,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isRead: null == isRead
            ? _value.isRead
            : isRead // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl extends _Message {
  const _$MessageImpl({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
  }) : super._();

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  @override
  final String id;
  @override
  final String text;
  @override
  final MessageSender sender;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isRead;

  @override
  String toString() {
    return 'Message(id: $id, text: $text, sender: $sender, timestamp: $timestamp, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isRead, isRead) || other.isRead == isRead));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, text, sender, timestamp, isRead);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(this);
  }
}

abstract class _Message extends Message {
  const factory _Message({
    required final String id,
    required final String text,
    required final MessageSender sender,
    required final DateTime timestamp,
    final bool isRead,
  }) = _$MessageImpl;
  const _Message._() : super._();

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  @override
  String get id;
  @override
  String get text;
  @override
  MessageSender get sender;
  @override
  DateTime get timestamp;
  @override
  bool get isRead;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageQueueStatus _$MessageQueueStatusFromJson(Map<String, dynamic> json) {
  return _MessageQueueStatus.fromJson(json);
}

/// @nodoc
mixin _$MessageQueueStatus {
  int get outstandingCount => throw _privateConstructorUsedError;
  bool get isTransferring => throw _privateConstructorUsedError;

  /// Serializes this MessageQueueStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageQueueStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageQueueStatusCopyWith<MessageQueueStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageQueueStatusCopyWith<$Res> {
  factory $MessageQueueStatusCopyWith(
    MessageQueueStatus value,
    $Res Function(MessageQueueStatus) then,
  ) = _$MessageQueueStatusCopyWithImpl<$Res, MessageQueueStatus>;
  @useResult
  $Res call({int outstandingCount, bool isTransferring});
}

/// @nodoc
class _$MessageQueueStatusCopyWithImpl<$Res, $Val extends MessageQueueStatus>
    implements $MessageQueueStatusCopyWith<$Res> {
  _$MessageQueueStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageQueueStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? outstandingCount = null, Object? isTransferring = null}) {
    return _then(
      _value.copyWith(
            outstandingCount: null == outstandingCount
                ? _value.outstandingCount
                : outstandingCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isTransferring: null == isTransferring
                ? _value.isTransferring
                : isTransferring // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageQueueStatusImplCopyWith<$Res>
    implements $MessageQueueStatusCopyWith<$Res> {
  factory _$$MessageQueueStatusImplCopyWith(
    _$MessageQueueStatusImpl value,
    $Res Function(_$MessageQueueStatusImpl) then,
  ) = __$$MessageQueueStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int outstandingCount, bool isTransferring});
}

/// @nodoc
class __$$MessageQueueStatusImplCopyWithImpl<$Res>
    extends _$MessageQueueStatusCopyWithImpl<$Res, _$MessageQueueStatusImpl>
    implements _$$MessageQueueStatusImplCopyWith<$Res> {
  __$$MessageQueueStatusImplCopyWithImpl(
    _$MessageQueueStatusImpl _value,
    $Res Function(_$MessageQueueStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageQueueStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? outstandingCount = null, Object? isTransferring = null}) {
    return _then(
      _$MessageQueueStatusImpl(
        outstandingCount: null == outstandingCount
            ? _value.outstandingCount
            : outstandingCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isTransferring: null == isTransferring
            ? _value.isTransferring
            : isTransferring // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageQueueStatusImpl implements _MessageQueueStatus {
  const _$MessageQueueStatusImpl({
    this.outstandingCount = 0,
    this.isTransferring = false,
  });

  factory _$MessageQueueStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageQueueStatusImplFromJson(json);

  @override
  @JsonKey()
  final int outstandingCount;
  @override
  @JsonKey()
  final bool isTransferring;

  @override
  String toString() {
    return 'MessageQueueStatus(outstandingCount: $outstandingCount, isTransferring: $isTransferring)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageQueueStatusImpl &&
            (identical(other.outstandingCount, outstandingCount) ||
                other.outstandingCount == outstandingCount) &&
            (identical(other.isTransferring, isTransferring) ||
                other.isTransferring == isTransferring));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, outstandingCount, isTransferring);

  /// Create a copy of MessageQueueStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageQueueStatusImplCopyWith<_$MessageQueueStatusImpl> get copyWith =>
      __$$MessageQueueStatusImplCopyWithImpl<_$MessageQueueStatusImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageQueueStatusImplToJson(this);
  }
}

abstract class _MessageQueueStatus implements MessageQueueStatus {
  const factory _MessageQueueStatus({
    final int outstandingCount,
    final bool isTransferring,
  }) = _$MessageQueueStatusImpl;

  factory _MessageQueueStatus.fromJson(Map<String, dynamic> json) =
      _$MessageQueueStatusImpl.fromJson;

  @override
  int get outstandingCount;
  @override
  bool get isTransferring;

  /// Create a copy of MessageQueueStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageQueueStatusImplCopyWith<_$MessageQueueStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
