import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_watch/providers/connection_status_provider.dart';
import 'package:flutter_watch/providers/counter_provider.dart';
import 'package:flutter_watch/providers/watch_communication_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CounterPage extends HookConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final watchService = ref.read(watchCommunicationServiceProvider);

    useEffect(() {
      watchService.initializeConnection();
      return null;
    }, []);

    Future<void> incrementCounter() async {
      try {
        ref.read(counterProvider.notifier).increment();
        final newValue = ref.read(counterProvider);

        await watchService.updateCounter(newValue);
      } on PlatformException catch (e) {
        ref.read(counterProvider.notifier).decrement();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('送信エラー: ${e.message}')));
        }
      }
    }

    Future<void> decrementCounter() async {
      try {
        ref.read(counterProvider.notifier).decrement();
        final newValue = ref.read(counterProvider);

        await watchService.updateCounter(newValue);
      } on PlatformException catch (e) {
        ref.read(counterProvider.notifier).increment();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('送信エラー: ${e.message}')));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('iPhone ↔ Watch Demo'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'iPhone',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Text(
              '$counter',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: decrementCounter,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                ),
                IconButton(
                  onPressed: incrementCounter,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  connectionStatus.isError ? Icons.error : Icons.watch,
                  color: connectionStatus.isError ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  connectionStatus.isError ? 'エラー' : '接続完了',
                  style: TextStyle(
                    color: connectionStatus.isError ? Colors.red : Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
