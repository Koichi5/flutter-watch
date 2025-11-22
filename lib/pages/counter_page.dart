import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_watch/providers/counter_provider.dart';

class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final isReachable = ref.watch(watchReachableProvider);
    final lastUpdate = ref.watch(lastUpdateTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('sendMessage サンプル'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'sendMessage',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'カウンターアプリ',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              ConnectionStatusWidget(isReachable: isReachable),
              const SizedBox(height: 40),
              CounterDisplayWidget(counter: counter),
              const SizedBox(height: 40),
              CounterButtonsWidget(
                onIncrement: () => ref.read(counterProvider.notifier).increment(),
                onDecrement: () => ref.read(counterProvider.notifier).decrement(),
                isReachable: isReachable,
              ),
              const SizedBox(height: 40),
              if (lastUpdate != null) LastUpdateWidget(lastUpdate: lastUpdate),
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key, required this.isReachable});
  final bool isReachable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isReachable ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReachable ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isReachable ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isReachable ? 'Apple Watch 接続中' : 'Apple Watch 未接続',
            style: TextStyle(
              color: isReachable ? Colors.green.shade900 : Colors.red.shade900,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CounterDisplayWidget extends StatelessWidget {
  const CounterDisplayWidget({super.key, required this.counter});
  final int counter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'カウンター',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$counter',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 72,
            ),
          ),
        ],
      ),
    );
  }
}

class LastUpdateWidget extends StatelessWidget {
  const LastUpdateWidget({super.key, required this.lastUpdate});
  final DateTime lastUpdate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    String timeAgo;
    if (difference.inSeconds < 60) {
      timeAgo = '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}分前';
    } else {
      timeAgo = '${difference.inHours}時間前';
    }

    return Text(
      '最終更新: $timeAgo',
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    );
  }
}

class CounterButtonsWidget extends StatelessWidget {
  const CounterButtonsWidget({
    super.key,
    required this.onIncrement,
    required this.onDecrement,
    required this.isReachable,
  });

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool isReachable;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: isReachable ? onDecrement : null,
          icon: const Icon(Icons.remove),
          iconSize: 48,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: isReachable ? onIncrement : null,
          icon: const Icon(Icons.add),
          iconSize: 48,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
