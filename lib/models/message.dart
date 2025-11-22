import 'package:freezed_annotation/freezed_annotation.dart';
import '../pigeon/message_api.g.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum MessageSender {
  iPhone,
  watch;

  String get displayName {
    switch (this) {
      case MessageSender.iPhone:
        return 'iPhone';
      case MessageSender.watch:
        return 'Watch';
    }
  }

  String toApiString() {
    switch (this) {
      case MessageSender.iPhone:
        return 'iPhone';
      case MessageSender.watch:
        return 'Watch';
    }
  }

  static MessageSender fromApiString(String value) {
    switch (value) {
      case 'iPhone':
        return MessageSender.iPhone;
      case 'Watch':
        return MessageSender.watch;
      default:
        return MessageSender.iPhone;
    }
  }
}

@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String text,
    required MessageSender sender,
    required DateTime timestamp,
    @Default(false) bool isRead,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  MessageData toPigeon() {
    return MessageData(
      id: id,
      text: text,
      sender: sender.toApiString(),
      timestamp: timestamp.millisecondsSinceEpoch / 1000.0,
      isRead: isRead,
    );
  }

  factory Message.fromPigeon(MessageData data) {
    return Message(
      id: data.id,
      text: data.text,
      sender: MessageSender.fromApiString(data.sender),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data.timestamp * 1000).toInt(),
      ),
      isRead: data.isRead,
    );
  }

  factory Message.create({
    required String text,
    required MessageSender sender,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
      isRead: false,
    );
  }
}

@freezed
class MessageQueueStatus with _$MessageQueueStatus {
  const factory MessageQueueStatus({
    @Default(0) int outstandingCount,
    @Default(false) bool isTransferring,
  }) = _MessageQueueStatus;

  factory MessageQueueStatus.fromJson(Map<String, dynamic> json) =>
      _$MessageQueueStatusFromJson(json);

  factory MessageQueueStatus.fromPigeon(QueueStatus data) {
    return MessageQueueStatus(
      outstandingCount: data.outstandingCount.toInt(),
      isTransferring: data.isTransferring,
    );
  }
}
