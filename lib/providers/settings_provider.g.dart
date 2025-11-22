// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsHash() => r'94c2677db8917393f20cd6d7747b2d108520df08';

/// アプリ設定のプロバイダー
///
/// updateApplicationContextを使ってApple Watchと同期します
///
/// Copied from [Settings].
@ProviderFor(Settings)
final settingsProvider =
    AutoDisposeNotifierProvider<Settings, AppSettings>.internal(
      Settings.new,
      name: r'settingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Settings = AutoDisposeNotifier<AppSettings>;
String _$watchReachableHash() => r'b1b8ef878072d16a550a01b201e3911ffc040c1f';

/// Watchの到達可能性プロバイダー
///
/// Copied from [WatchReachable].
@ProviderFor(WatchReachable)
final watchReachableProvider =
    AutoDisposeNotifierProvider<WatchReachable, bool>.internal(
      WatchReachable.new,
      name: r'watchReachableProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$watchReachableHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WatchReachable = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
