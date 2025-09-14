import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_watch/models/method_channel_method.dart';
import 'package:flutter_watch/models/watch_connection_status.dart';
import 'package:flutter_watch/models/watch_status_key.dart';
import 'package:flutter_watch/providers/connection_status_provider.dart';
import 'package:flutter_watch/providers/counter_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_communication_service_provider.g.dart';

@riverpod
WatchCommunicationService watchCommunicationService(
  WatchCommunicationServiceRef ref,
) {
  return WatchCommunicationService(ref);
}

const MethodChannel platformChannel = MethodChannel('flutter_watch/counter');

class WatchCommunicationService {
  final Ref _ref;

  WatchCommunicationService(this._ref) {
    _setupMessageListener();
  }

  Future<void> initializeConnection() async {
    try {
      final result = await platformChannel.invokeMethod('initializeSession');
      final statusKey = result['status_key'] ?? 'error';
      final status = _parseConnectionStatus(statusKey);
      _ref.read(connectionStatusProvider.notifier).update(status);
    } on PlatformException {
      _ref
          .read(connectionStatusProvider.notifier)
          .update(WatchConnectionStatus.error);
    }
  }

  void _setupMessageListener() {
    platformChannel.setMethodCallHandler((call) async {
      final method = MethodChannelMethod.fromString(call.method);

      switch (method) {
        case MethodChannelMethod.counterUpdated:
          final int newValue = call.arguments['counter'];
          _ref.read(counterProvider.notifier).set(newValue);
          break;

        case MethodChannelMethod.sessionStateChanged:
          final String statusKey = call.arguments['status_key'] ?? '';
          final status = _parseConnectionStatus(statusKey);
          _ref.read(connectionStatusProvider.notifier).update(status);
          break;

        default:
          debugPrint('📱 Unknown method received: ${call.method}');
          break;
      }
    });
  }

  Future<bool> updateCounter(int newValue) async {
    try {
      final success = await platformChannel.invokeMethod('sendCounter', {
        'counter': newValue,
      });

      return success == true;
    } on PlatformException catch (e) {
      debugPrint('📱 Send error: ${e.message}');
      rethrow;
    }
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
