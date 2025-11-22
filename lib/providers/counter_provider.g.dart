// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$counterHash() => r'c9a9f9099579157e5449484c095459d27bb1f89c';

/// カウンター値を管理するプロバイダー
///
/// Apple WatchからのsendMessageを受信してカウンターを更新します。
///
/// Copied from [Counter].
@ProviderFor(Counter)
final counterProvider = AutoDisposeNotifierProvider<Counter, int>.internal(
  Counter.new,
  name: r'counterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$counterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Counter = AutoDisposeNotifier<int>;
String _$watchReachableHash() => r'5fcded63dd5b6f37f1d200d18ea117164fa0038b';

/// See also [WatchReachable].
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
String _$lastUpdateTimeHash() => r'3860cb88cdbd035bfb3c19b148935f48af5c348e';

/// See also [LastUpdateTime].
@ProviderFor(LastUpdateTime)
final lastUpdateTimeProvider =
    AutoDisposeNotifierProvider<LastUpdateTime, DateTime?>.internal(
      LastUpdateTime.new,
      name: r'lastUpdateTimeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$lastUpdateTimeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LastUpdateTime = AutoDisposeNotifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
