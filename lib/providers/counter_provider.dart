import 'package:flutter_watch/services/watch_connectivity_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() {
    final service = ref.watch(watchConnectivityServiceProvider);
    service.counterIncrementedCallback = (count) {
      state = count;
      ref.read(lastUpdateTimeProvider.notifier).update();
    };

    return 0;
  }

  Future<void> reset() async {
    final service = ref.read(watchConnectivityServiceProvider);
    await service.resetCounter();

    state = 0;
    ref.read(lastUpdateTimeProvider.notifier).update();
  }

  Future<void> increment() async {
    final newValue = state + 1;
    state = newValue;
    ref.read(lastUpdateTimeProvider.notifier).update();

    final service = ref.read(watchConnectivityServiceProvider);
    await service.updateCounter(newValue);
  }

  Future<void> decrement() async {
    final newValue = state - 1;
    state = newValue;
    ref.read(lastUpdateTimeProvider.notifier).update();

    final service = ref.read(watchConnectivityServiceProvider);
    await service.updateCounter(newValue);
  }
}

@riverpod
class WatchReachable extends _$WatchReachable {
  @override
  bool build() {
    final service = ref.watch(watchConnectivityServiceProvider);
    service.reachabilityChangedCallback = (isReachable) {
      state = isReachable;
    };

    _checkReachability();

    return false;
  }

  Future<void> _checkReachability() async {
    try {
      final service = ref.read(watchConnectivityServiceProvider);
      final isReachable = await service.isWatchReachable();
      state = isReachable;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}

@riverpod
class LastUpdateTime extends _$LastUpdateTime {
  @override
  DateTime? build() {
    return null;
  }

  void update() {
    state = DateTime.now();
  }
}
