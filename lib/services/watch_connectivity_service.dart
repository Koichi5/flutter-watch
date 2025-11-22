import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_watch/pigeon/counter_api.g.dart';

part 'watch_connectivity_service.g.dart';

@riverpod
WatchConnectivityService watchConnectivityService(Ref ref) {
  return WatchConnectivityService();
}

class WatchConnectivityService implements CounterFlutterApi {
  final CounterHostApi _hostApi = CounterHostApi();

  Function(int)? counterIncrementedCallback;
  Function(bool)? reachabilityChangedCallback;

  WatchConnectivityService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    CounterFlutterApi.setUp(this);
  }

  @override
  void onCounterIncremented(int count) {
    try {
      counterIncrementedCallback?.call(count);
    } catch (e) {
      debugPrint('Flutter: Error handling counter increment: $e');
    }
  }

  @override
  void onReachabilityChanged(bool isReachable) {
    try {
      reachabilityChangedCallback?.call(isReachable);
    } catch (e) {
      debugPrint('Flutter: Error handling reachability change: $e');
    }
  }

  Future<void> resetCounter() async {
    try {
      _hostApi.resetCounter();
    } catch (e) {
      debugPrint('Flutter: Failed to reset counter: $e');
      rethrow;
    }
  }

  Future<void> updateCounter(int count) async {
    try {
      _hostApi.updateCounter(count);
    } catch (e) {
      debugPrint('Flutter: Failed to update counter: $e');
      rethrow;
    }
  }

  Future<bool> isWatchReachable() async {
    try {
      final isReachable = _hostApi.isWatchReachable();
      return isReachable;
    } catch (e) {
      debugPrint('Flutter: Failed to check reachability: $e');
      return false;
    }
  }
}
