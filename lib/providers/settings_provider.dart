import 'package:flutter_watch/models/app_settings.dart';
import 'package:flutter_watch/services/watch_connectivity_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  @override
  AppSettings build() {
    final service = ref.watch(watchConnectivityServiceProvider);
    service.settingsUpdatedCallback = (settings) {
      state = settings;
    };

    return const AppSettings();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      state = newSettings;
      final service = ref.read(watchConnectivityServiceProvider);
      await service.updateSettings(newSettings);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateColor(ThemeColor color) async {
    final newSettings = state.copyWith(
      themeColor: color,
      lastUpdated: DateTime.now(),
    );
    await updateSettings(newSettings);
  }

  Future<void> updateFontSize(FontSize fontSize) async {
    final newSettings = state.copyWith(
      fontSize: fontSize,
      lastUpdated: DateTime.now(),
    );
    await updateSettings(newSettings);
  }

  Future<void> updateNotification(bool enabled) async {
    final newSettings = state.copyWith(
      notificationEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    await updateSettings(newSettings);
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
    final service = ref.read(watchConnectivityServiceProvider);
    final isReachable = await service.isWatchReachable();
    state = isReachable;
  }

  Future<void> refresh() async {
    await _checkReachability();
  }
}



