import 'package:flutter_watch/models/image_transfer.dart';
import 'package:flutter_watch/services/image_transfer_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:typed_data';

part 'image_transfer_provider.g.dart';

@riverpod
class TransferHistory extends _$TransferHistory {
  @override
  Future<List<AppTransferHistoryItem>> build() async {
    final service = ref.watch(imageTransferServiceProvider);

    service.transferCompletedCallback = (_) => refresh();
    service.transferFailedCallback = (_, __) => refresh();

    return service.getTransferHistory();
  }

  Future<void> refresh() async {
    final service = ref.read(imageTransferServiceProvider);
    state = AsyncData(await service.getTransferHistory());
  }

  Future<void> transferImage(
    Uint8List imageData,
    AppImageMetadata metadata,
  ) async {
    final service = ref.read(imageTransferServiceProvider);
    await service.transferImage(imageData, metadata);
    await refresh();
  }
}

@riverpod
class ActiveTransfers extends _$ActiveTransfers {
  @override
  Future<List<AppTransferProgress>> build() async {
    final service = ref.watch(imageTransferServiceProvider);

    service.progressUpdatedCallback = (progress) {
      final currentTransfers = state.value ?? [];
      final index =
          currentTransfers.indexWhere((t) => t.imageId == progress.imageId);

      if (index >= 0) {
        final updatedTransfers = List<AppTransferProgress>.from(currentTransfers);
        updatedTransfers[index] = progress;
        state = AsyncData(updatedTransfers);
      } else {
        state = AsyncData([...currentTransfers, progress]);
      }
    };

    service.transferCompletedCallback = (imageId) {
      final currentTransfers = state.value ?? [];
      final updatedTransfers =
          currentTransfers.where((t) => t.imageId != imageId).toList();
      state = AsyncData(updatedTransfers);
      ref.read(transferHistoryProvider.notifier).refresh();
    };

    service.transferFailedCallback = (imageId, error) {
      final currentTransfers = state.value ?? [];
      final updatedTransfers =
          currentTransfers.where((t) => t.imageId != imageId).toList();
      state = AsyncData(updatedTransfers);
      ref.read(transferHistoryProvider.notifier).refresh();
    };

    return service.getActiveTransfers();
  }

  Future<void> cancelTransfer(String imageId) async {
    final service = ref.read(imageTransferServiceProvider);
    await service.cancelTransfer(imageId);

    final currentTransfers = state.value ?? [];
    final updatedTransfers =
        currentTransfers.where((t) => t.imageId != imageId).toList();
    state = AsyncData(updatedTransfers);

    ref.read(transferHistoryProvider.notifier).refresh();
  }

  Future<void> refresh() async {
    final service = ref.read(imageTransferServiceProvider);
    state = AsyncData(await service.getActiveTransfers());
  }
}

@riverpod
class TransferProgress extends _$TransferProgress {
  @override
  AppTransferProgress? build(String imageId) {
    final activeTransfers = ref.watch(activeTransfersProvider);

    return activeTransfers.whenOrNull(
      data: (transfers) {
        try {
          return transfers.firstWhere((t) => t.imageId == imageId);
        } catch (_) {
          return null;
        }
      },
    );
  }
}


