// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_transfer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transferHistoryHash() => r'3502e746f0927ec0654c681506dd3f1062690f11';

/// 転送履歴プロバイダー
///
/// Copied from [TransferHistory].
@ProviderFor(TransferHistory)
final transferHistoryProvider =
    AutoDisposeAsyncNotifierProvider<
      TransferHistory,
      List<AppTransferHistoryItem>
    >.internal(
      TransferHistory.new,
      name: r'transferHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transferHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransferHistory =
    AutoDisposeAsyncNotifier<List<AppTransferHistoryItem>>;
String _$activeTransfersHash() => r'c8f11e5d0fda770f00184c4b2e36fa229e48d3a2';

/// 進行中の転送プロバイダー
///
/// Copied from [ActiveTransfers].
@ProviderFor(ActiveTransfers)
final activeTransfersProvider =
    AutoDisposeAsyncNotifierProvider<
      ActiveTransfers,
      List<AppTransferProgress>
    >.internal(
      ActiveTransfers.new,
      name: r'activeTransfersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeTransfersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveTransfers = AutoDisposeAsyncNotifier<List<AppTransferProgress>>;
String _$transferProgressHash() => r'bd5096bfde7e483ec2c34071c43bc06ab6e7dec5';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$TransferProgress
    extends BuildlessAutoDisposeNotifier<AppTransferProgress?> {
  late final String imageId;

  AppTransferProgress? build(String imageId);
}

/// 特定の画像の転送進捗プロバイダー（Family）
///
/// Copied from [TransferProgress].
@ProviderFor(TransferProgress)
const transferProgressProvider = TransferProgressFamily();

/// 特定の画像の転送進捗プロバイダー（Family）
///
/// Copied from [TransferProgress].
class TransferProgressFamily extends Family<AppTransferProgress?> {
  /// 特定の画像の転送進捗プロバイダー（Family）
  ///
  /// Copied from [TransferProgress].
  const TransferProgressFamily();

  /// 特定の画像の転送進捗プロバイダー（Family）
  ///
  /// Copied from [TransferProgress].
  TransferProgressProvider call(String imageId) {
    return TransferProgressProvider(imageId);
  }

  @override
  TransferProgressProvider getProviderOverride(
    covariant TransferProgressProvider provider,
  ) {
    return call(provider.imageId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'transferProgressProvider';
}

/// 特定の画像の転送進捗プロバイダー（Family）
///
/// Copied from [TransferProgress].
class TransferProgressProvider
    extends
        AutoDisposeNotifierProviderImpl<
          TransferProgress,
          AppTransferProgress?
        > {
  /// 特定の画像の転送進捗プロバイダー（Family）
  ///
  /// Copied from [TransferProgress].
  TransferProgressProvider(String imageId)
    : this._internal(
        () => TransferProgress()..imageId = imageId,
        from: transferProgressProvider,
        name: r'transferProgressProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$transferProgressHash,
        dependencies: TransferProgressFamily._dependencies,
        allTransitiveDependencies:
            TransferProgressFamily._allTransitiveDependencies,
        imageId: imageId,
      );

  TransferProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.imageId,
  }) : super.internal();

  final String imageId;

  @override
  AppTransferProgress? runNotifierBuild(covariant TransferProgress notifier) {
    return notifier.build(imageId);
  }

  @override
  Override overrideWith(TransferProgress Function() create) {
    return ProviderOverride(
      origin: this,
      override: TransferProgressProvider._internal(
        () => create()..imageId = imageId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        imageId: imageId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<TransferProgress, AppTransferProgress?>
  createElement() {
    return _TransferProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransferProgressProvider && other.imageId == imageId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, imageId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TransferProgressRef
    on AutoDisposeNotifierProviderRef<AppTransferProgress?> {
  /// The parameter `imageId` of this provider.
  String get imageId;
}

class _TransferProgressProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          TransferProgress,
          AppTransferProgress?
        >
    with TransferProgressRef {
  _TransferProgressProviderElement(super.provider);

  @override
  String get imageId => (origin as TransferProgressProvider).imageId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
