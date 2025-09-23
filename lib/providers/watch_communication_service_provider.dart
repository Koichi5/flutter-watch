import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_watch/models/watch_connection_status.dart';
import 'package:flutter_watch/models/watch_status_key.dart';
import 'package:flutter_watch/providers/connection_status_provider.dart';
import 'package:flutter_watch/providers/counter_provider.dart';
import 'package:flutter_watch/pigeons/watch_communication_api.g.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_communication_service_provider.g.dart';

@riverpod
WatchCommunicationService watchCommunicationService(
  WatchCommunicationServiceRef ref,
) {
  return WatchCommunicationService(ref);
}

class WatchCommunicationService extends WatchCommunicationFlutterApi {
  final Ref _ref;
  late final WatchCommunicationHostApi _hostApi;

  WatchCommunicationService(this._ref) {
    _hostApi = WatchCommunicationHostApi();
    WatchCommunicationFlutterApi.setUp(this);
  }

  Future<void> initializeConnection() async {
    try {
      final result = await _hostApi.initializeSession();
      final status = _parseConnectionStatus(result.statusKey);
      _ref.read(connectionStatusProvider.notifier).update(status);
    } on PlatformException {
      _ref
          .read(connectionStatusProvider.notifier)
          .update(WatchConnectionStatus.error);
    }
  }

  Future<bool> updateCounter(int newValue) async {
    try {
      final result = await _hostApi.sendCounter(
        CounterRequest(counter: newValue),
      );
      return result.success;
    } on PlatformException catch (e) {
      debugPrint('📱 Send error: ${e.message}');
      rethrow;
    }
  }

  @override
  void onCounterUpdated(CounterUpdateEvent event) {
    _ref.read(counterProvider.notifier).set(event.counter);
  }

  @override
  void onSessionStateChanged(SessionStateEvent event) {
    final status = _parseConnectionStatus(event.statusKey);
    _ref.read(connectionStatusProvider.notifier).update(status);
  }

  WatchConnectionStatus _parseConnectionStatus(String statusKey) {
    final key = WatchStatusKey.fromString(statusKey);

    switch (key) {
      case WatchStatusKey.connected:
        return WatchConnectionStatus.connected;
      case WatchStatusKey.notPaired:
        return WatchConnectionStatus.notPaired;
      case WatchStatusKey.notInstalled:
        return WatchConnectionStatus.notInstalled;
      case WatchStatusKey.notReachable:
        return WatchConnectionStatus.notReachable;
      case WatchStatusKey.error:
        return WatchConnectionStatus.error;
      case WatchStatusKey.connecting:
      case null:
        return WatchConnectionStatus.connecting;
    }
  }
}
