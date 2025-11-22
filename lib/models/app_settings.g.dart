// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      themeColor:
          $enumDecodeNullable(_$ThemeColorEnumMap, json['themeColor']) ??
          ThemeColor.blue,
      fontSize:
          $enumDecodeNullable(_$FontSizeEnumMap, json['fontSize']) ??
          FontSize.medium,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'themeColor': _$ThemeColorEnumMap[instance.themeColor]!,
      'fontSize': _$FontSizeEnumMap[instance.fontSize]!,
      'notificationEnabled': instance.notificationEnabled,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };

const _$ThemeColorEnumMap = {
  ThemeColor.red: 'red',
  ThemeColor.blue: 'blue',
  ThemeColor.green: 'green',
};

const _$FontSizeEnumMap = {
  FontSize.small: 'small',
  FontSize.medium: 'medium',
  FontSize.large: 'large',
};
