import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon/settings_api.g.dart',
    swiftOut: 'ios/Runner/Pigeon/SettingsApi.g.swift',
  ),
)
class SettingsData {
  final int color;
  final int fontSize;
  final bool notificationEnabled;
  final double lastUpdated;

  SettingsData({
    required this.color,
    required this.fontSize,
    required this.notificationEnabled,
    required this.lastUpdated,
  });
}

@HostApi()
abstract class SettingsHostApi {
  @TaskQueue(type: TaskQueueType.serial)
  void updateSettings(SettingsData settings);

  @TaskQueue(type: TaskQueueType.serial)
  SettingsData getCurrentSettings();

  @TaskQueue(type: TaskQueueType.serial)
  bool isWatchReachable();
}

@FlutterApi()
abstract class SettingsFlutterApi {
  @TaskQueue(type: TaskQueueType.serial)
  void onSettingsUpdated(SettingsData settings);

  @TaskQueue(type: TaskQueueType.serial)
  void onReachabilityChanged(bool isReachable);
}
