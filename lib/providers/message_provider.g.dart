// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sentMessagesHash() => r'6b0693eccb5c66a610eb4a799167f3996368b7fd';

/// 送信メッセージ一覧のプロバイダー
///
/// Copied from [SentMessages].
@ProviderFor(SentMessages)
final sentMessagesProvider =
    AutoDisposeAsyncNotifierProvider<SentMessages, List<Message>>.internal(
      SentMessages.new,
      name: r'sentMessagesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sentMessagesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SentMessages = AutoDisposeAsyncNotifier<List<Message>>;
String _$receivedMessagesHash() => r'f66f1199055d9afe219463a291bc55c99d18f21e';

/// 受信メッセージ一覧のプロバイダー
///
/// Copied from [ReceivedMessages].
@ProviderFor(ReceivedMessages)
final receivedMessagesProvider =
    AutoDisposeAsyncNotifierProvider<ReceivedMessages, List<Message>>.internal(
      ReceivedMessages.new,
      name: r'receivedMessagesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$receivedMessagesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReceivedMessages = AutoDisposeAsyncNotifier<List<Message>>;
String _$queueStatusNotifierHash() =>
    r'61704f9044d57f27121d3c7af357643454d1d771';

/// キュー状態のプロバイダー
///
/// Copied from [QueueStatusNotifier].
@ProviderFor(QueueStatusNotifier)
final queueStatusNotifierProvider =
    AutoDisposeNotifierProvider<
      QueueStatusNotifier,
      MessageQueueStatus
    >.internal(
      QueueStatusNotifier.new,
      name: r'queueStatusNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$queueStatusNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$QueueStatusNotifier = AutoDisposeNotifier<MessageQueueStatus>;
String _$watchReachableNotifierHash() =>
    r'd6306686f8b93a8615ff4b07b28261f6f623c62d';

/// Watch到達可能性のプロバイダー
///
/// Copied from [WatchReachableNotifier].
@ProviderFor(WatchReachableNotifier)
final watchReachableNotifierProvider =
    AutoDisposeNotifierProvider<WatchReachableNotifier, bool>.internal(
      WatchReachableNotifier.new,
      name: r'watchReachableNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$watchReachableNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WatchReachableNotifier = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
