import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../providers/message_provider.dart';

class MessagePage extends HookConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final isReachable = ref.watch(watchReachableNotifierProvider);
    final queueStatus = ref.watch(queueStatusNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          ConnectionStatusBar(
            isReachable: isReachable,
            queueStatus: queueStatus,
          ),
          Expanded(child: MessagesView()),
          MessageInputForm(
            controller: textController,
            onSend: () async {
              final text = textController.text;
              if (text.trim().isNotEmpty) {
                await ref.read(sentMessagesProvider.notifier).sendMessage(text);
                textController.clear();
                ref.read(queueStatusNotifierProvider.notifier).refresh();
              }
            },
          ),
        ],
      ),
    );
  }
}

class ConnectionStatusBar extends StatelessWidget {
  final bool isReachable;
  final MessageQueueStatus queueStatus;

  const ConnectionStatusBar({
    super.key,
    required this.isReachable,
    required this.queueStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isReachable ? Colors.green.shade50 : Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(
            isReachable ? Icons.watch : Icons.watch_off,
            color: isReachable ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isReachable ? 'Apple Watch 接続中' : 'Apple Watch 未接続',
            style: TextStyle(
              color: isReachable ? Colors.green.shade900 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (queueStatus.outstandingCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue, size: 16, color: Colors.orange.shade900),
                  const SizedBox(width: 4),
                  Text(
                    'キュー: ${queueStatus.outstandingCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MessagesView extends ConsumerWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentMessagesAsync = ref.watch(sentMessagesProvider);
    final receivedMessagesAsync = ref.watch(receivedMessagesProvider);

    return sentMessagesAsync.when(
      data: (sentMessages) {
        return receivedMessagesAsync.when(
          data: (receivedMessages) {
            final allMessages = <Message>[...sentMessages, ...receivedMessages]
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

            if (allMessages.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'メッセージを送信してみましょう',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              reverse: true,
              itemCount: allMessages.length,
              itemBuilder: (context, index) {
                final message = allMessages[allMessages.length - 1 - index];
                final isSent = message.sender == MessageSender.iPhone;

                return MessageBubble(
                  message: message,
                  isSent: isSent,
                  onTap: !isSent && !message.isRead
                      ? () {
                          ref
                              .read(receivedMessagesProvider.notifier)
                              .markAsRead(message.id);
                        }
                      : null,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSent;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSent ? Colors.blue.shade600 : Colors.grey.shade300;
    final textColor = isSent ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.watch, size: 18, color: Colors.white),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isSent ? 18 : 4),
                    bottomRight: Radius.circular(isSent ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        if (!isSent && !message.isRead) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSent) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_iphone,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MessageInputForm extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInputForm({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'メッセージを入力...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: onSend,
              mini: true,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
