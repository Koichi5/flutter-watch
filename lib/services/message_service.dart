import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../pigeon/message_api.g.dart';
import '../models/message.dart';

part 'message_service.g.dart';

@riverpod
MessageService messageService(Ref ref) {
  return MessageService();
}

class MessageService implements MessageFlutterApi {
  final MessageHostApi _hostApi = MessageHostApi();

  Function(Message)? messageReceivedCallback;
  Function(MessageQueueStatus)? queueStatusChangedCallback;
  Function(bool)? reachabilityChangedCallback;

  MessageService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    MessageFlutterApi.setUp(this);
  }

  @override
  void onMessageReceived(MessageData message) {
    try {
      final msg = Message.fromPigeon(message);
      messageReceivedCallback?.call(msg);
    } catch (e) {
      debugPrint('Flutter: Error handling message: $e');
    }
  }

  @override
  void onQueueStatusChanged(QueueStatus status) {
    try {
      final queueStatus = MessageQueueStatus.fromPigeon(status);
      queueStatusChangedCallback?.call(queueStatus);
    } catch (e) {
      debugPrint('Flutter: Error handling queue status: $e');
    }
  }

  @override
  void onReachabilityChanged(bool isReachable) {
    try {
      reachabilityChangedCallback?.call(isReachable);
    } catch (e) {
      debugPrint('Flutter: Error handling reachability: $e');
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      _hostApi.sendMessage(message.toPigeon());
    } catch (e) {
      debugPrint('Flutter: Error sending message: $e');
      rethrow;
    }
  }

  Future<List<Message>> getSentMessages() async {
    try {
      final messages = await _hostApi.getSentMessages();
      return messages.map((m) => Message.fromPigeon(m)).toList();
    } catch (e) {
      debugPrint('Flutter: Error getting sent messages: $e');
      return [];
    }
  }

  Future<List<Message>> getReceivedMessages() async {
    try {
      final messages = await _hostApi.getReceivedMessages();
      return messages.map((m) => Message.fromPigeon(m)).toList();
    } catch (e) {
      debugPrint('Flutter: Error getting received messages: $e');
      return [];
    }
  }

  Future<MessageQueueStatus> getQueueStatus() async {
    try {
      final status = await _hostApi.getQueueStatus();
      return MessageQueueStatus.fromPigeon(status);
    } catch (e) {
      debugPrint('Flutter: Error getting queue status: $e');
      return const MessageQueueStatus();
    }
  }

  Future<bool> cancelMessage(String messageId) async {
    try {
      final result = await _hostApi.cancelMessage(messageId);
      return result;
    } catch (e) {
      debugPrint('Flutter: Error cancelling message: $e');
      return false;
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _hostApi.markAsRead(messageId);
    } catch (e) {
      debugPrint('Flutter: Error marking as read: $e');
    }
  }

  Future<bool> isWatchReachable() async {
    try {
      final isReachable = await _hostApi.isWatchReachable();
      return isReachable;
    } catch (e) {
      debugPrint('Flutter: Error checking reachability: $e');
      return false;
    }
  }
}
