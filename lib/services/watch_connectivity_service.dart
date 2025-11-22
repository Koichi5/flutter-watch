import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_watch/models/app_settings.dart';
import 'package:flutter_watch/pigeon/settings_api.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_connectivity_service.g.dart';

@riverpod
WatchConnectivityService watchConnectivityService(Ref ref) {
  return WatchConnectivityService();
}

class WatchConnectivityService implements SettingsFlutterApi {
  final SettingsHostApi _hostApi = SettingsHostApi();
  Function(AppSettings)? settingsUpdatedCallback;
  Function(bool)? reachabilityChangedCallback;

  WatchConnectivityService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    SettingsFlutterApi.setUp(this);
  }

  @override
  void onSettingsUpdated(SettingsData settings) {
    try {
      final appSettings = AppSettings.fromPigeon(settings);
      settingsUpdatedCallback?.call(appSettings);
    } catch (e) {
      debugPrint('Flutter: Error handling settings update: $e');
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

  Future<void> updateSettings(AppSettings settings) async {
    try {
      _hostApi.updateSettings(settings.toPigeon());
    } catch (e) {
      debugPrint('Flutter: Failed to update settings: $e');
      rethrow;
    }
  }

  /// 現在の設定を取得
  Future<AppSettings> getCurrentSettings() async {
    try {
      final settingsData = await _hostApi.getCurrentSettings();
      return AppSettings.fromPigeon(settingsData);
    } catch (e) {
      debugPrint('Flutter: Failed to get current settings: $e');
      rethrow;
    }
  }

  Future<bool> isWatchReachable() async {
    try {
      final isReachable = await _hostApi.isWatchReachable();
      return isReachable;
    } catch (e) {
      debugPrint('Flutter: Failed to check reachability: $e');
      return false;
    }
  }
}
