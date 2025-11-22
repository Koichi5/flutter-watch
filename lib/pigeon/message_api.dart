import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon/message_api.g.dart',
    swiftOut: 'ios/Runner/Pigeon/MessageApi.g.swift',
  ),
)
class MessageData {
  final String id;
  final String text;
  final String sender;
  final double timestamp;
  final bool isRead;

  MessageData({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.isRead,
  });
}

class QueueStatus {
  final int outstandingCount;
  final bool isTransferring;

  QueueStatus({required this.outstandingCount, required this.isTransferring});
}

@HostApi()
abstract class MessageHostApi {
  @TaskQueue(type: TaskQueueType.serial)
  void sendMessage(MessageData message);

  @TaskQueue(type: TaskQueueType.serial)
  List<MessageData> getSentMessages();

  @TaskQueue(type: TaskQueueType.serial)
  List<MessageData> getReceivedMessages();

  @TaskQueue(type: TaskQueueType.serial)
  QueueStatus getQueueStatus();

  @TaskQueue(type: TaskQueueType.serial)
  bool cancelMessage(String messageId);

  @TaskQueue(type: TaskQueueType.serial)
  void markAsRead(String messageId);

  @TaskQueue(type: TaskQueueType.serial)
  bool isWatchReachable();
}

@FlutterApi()
abstract class MessageFlutterApi {
  @TaskQueue(type: TaskQueueType.serial)
  void onMessageReceived(MessageData message);

  @TaskQueue(type: TaskQueueType.serial)
  void onQueueStatusChanged(QueueStatus status);

  @TaskQueue(type: TaskQueueType.serial)
  void onReachabilityChanged(bool isReachable);
}
