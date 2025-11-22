// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: $enumDecode(_$MessageSenderEnumMap, json['sender']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'sender': _$MessageSenderEnumMap[instance.sender]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'isRead': instance.isRead,
    };

const _$MessageSenderEnumMap = {
  MessageSender.iPhone: 'iPhone',
  MessageSender.watch: 'watch',
};

_$MessageQueueStatusImpl _$$MessageQueueStatusImplFromJson(
  Map<String, dynamic> json,
) => _$MessageQueueStatusImpl(
  outstandingCount: (json['outstandingCount'] as num?)?.toInt() ?? 0,
  isTransferring: json['isTransferring'] as bool? ?? false,
);

Map<String, dynamic> _$$MessageQueueStatusImplToJson(
  _$MessageQueueStatusImpl instance,
) => <String, dynamic>{
  'outstandingCount': instance.outstandingCount,
  'isTransferring': instance.isTransferring,
};
