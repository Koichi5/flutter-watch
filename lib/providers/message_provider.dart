import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/message.dart';
import '../services/message_service.dart';

part 'message_provider.g.dart';

@riverpod
class SentMessages extends _$SentMessages {
  @override
  Future<List<Message>> build() async {
    final service = ref.watch(messageServiceProvider);
    service.messageReceivedCallback = null;
    return await service.getSentMessages();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final service = ref.read(messageServiceProvider);
    final message = Message.create(text: text, sender: MessageSender.iPhone);

    await service.sendMessage(message);

    ref.invalidateSelf();
  }
}

@riverpod
class ReceivedMessages extends _$ReceivedMessages {
  @override
  Future<List<Message>> build() async {
    final service = ref.watch(messageServiceProvider);

    service.messageReceivedCallback = (message) {
      ref.invalidateSelf();
    };

    return await service.getReceivedMessages();
  }

  Future<void> markAsRead(String messageId) async {
    final service = ref.read(messageServiceProvider);
    await service.markAsRead(messageId);

    ref.invalidateSelf();
  }

  int getUnreadCount() {
    return state.maybeWhen(
      data: (messages) => messages.where((m) => !m.isRead).length,
      orElse: () => 0,
    );
  }
}

@riverpod
class QueueStatusNotifier extends _$QueueStatusNotifier {
  @override
  MessageQueueStatus build() {
    final service = ref.watch(messageServiceProvider);

    service.queueStatusChangedCallback = (status) {
      state = status;
    };

    _fetchQueueStatus();

    return const MessageQueueStatus();
  }

  Future<void> _fetchQueueStatus() async {
    final service = ref.read(messageServiceProvider);
    final status = await service.getQueueStatus();
    state = status;
  }

  Future<void> refresh() async {
    await _fetchQueueStatus();
  }
}

@riverpod
class WatchReachableNotifier extends _$WatchReachableNotifier {
  @override
  bool build() {
    final service = ref.watch(messageServiceProvider);

    service.reachabilityChangedCallback = (isReachable) {
      state = isReachable;
    };

    _checkReachability();

    return false;
  }

  Future<void> _checkReachability() async {
    final service = ref.read(messageServiceProvider);
    final isReachable = await service.isWatchReachable();
    state = isReachable;
  }

  Future<void> refresh() async {
    await _checkReachability();
  }
}
