import 'package:flutter/material.dart';
import 'package:flutter_watch/pigeon/settings_api.g.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum ThemeColor {
  red,
  blue,
  green;

  String get displayName {
    switch (this) {
      case ThemeColor.red:
        return '赤';
      case ThemeColor.blue:
        return '青';
      case ThemeColor.green:
        return '緑';
    }
  }

  Color get color {
    switch (this) {
      case ThemeColor.red:
        return Colors.red;
      case ThemeColor.blue:
        return Colors.blue;
      case ThemeColor.green:
        return Colors.green;
    }
  }

  int toInt() => index;

  static ThemeColor fromInt(int value) {
    return ThemeColor.values[value];
  }
}

enum FontSize {
  small,
  medium,
  large;

  String get displayName {
    switch (this) {
      case FontSize.small:
        return '小';
      case FontSize.medium:
        return '中';
      case FontSize.large:
        return '大';
    }
  }

  double get points {
    switch (this) {
      case FontSize.small:
        return 14.0;
      case FontSize.medium:
        return 16.0;
      case FontSize.large:
        return 18.0;
    }
  }

  int toInt() => index;

  static FontSize fromInt(int value) {
    return FontSize.values[value];
  }
}

@freezed
class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(ThemeColor.blue) ThemeColor themeColor,
    @Default(FontSize.medium) FontSize fontSize,
    @Default(true) bool notificationEnabled,
    DateTime? lastUpdated,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  SettingsData toPigeon() {
    return SettingsData(
      color: themeColor.toInt(),
      fontSize: fontSize.toInt(),
      notificationEnabled: notificationEnabled,
      lastUpdated:
          (lastUpdated ?? DateTime.now()).millisecondsSinceEpoch / 1000.0,
    );
  }

  factory AppSettings.fromPigeon(SettingsData data) {
    return AppSettings(
      themeColor: ThemeColor.fromInt(data.color),
      fontSize: FontSize.fromInt(data.fontSize),
      notificationEnabled: data.notificationEnabled,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        (data.lastUpdated * 1000).toInt(),
      ),
    );
  }
}
