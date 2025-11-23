import 'package:flutter/foundation.dart';
import 'package:flutter_watch/models/image_transfer.dart';
import 'package:flutter_watch/pigeon/image_transfer_api.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_transfer_service.g.dart';

@riverpod
ImageTransferService imageTransferService(Ref ref) {
  return ImageTransferService();
}

class ImageTransferService implements ImageTransferFlutterApi {
  final ImageTransferHostApi _hostApi = ImageTransferHostApi();

  Function(AppTransferProgress)? progressUpdatedCallback;
  Function(String)? transferCompletedCallback;
  Function(String, String)? transferFailedCallback;

  ImageTransferService() {
    _setupFlutterApi();
  }

  void _setupFlutterApi() {
    ImageTransferFlutterApi.setUp(this);
  }

  @override
  void onProgressUpdated(TransferProgress progress) {
    try {
      final appProgress = AppTransferProgress.fromPigeon(progress);
      progressUpdatedCallback?.call(appProgress);
    } catch (e) {
      debugPrint('Flutter: Error handling progress update: $e');
    }
  }

  @override
  void onTransferCompleted(String imageId) {
    transferCompletedCallback?.call(imageId);
  }

  @override
  void onTransferFailed(String imageId, String error) {
    transferFailedCallback?.call(imageId, error);
  }

  Future<void> transferImage(
    Uint8List imageData,
    AppImageMetadata metadata,
  ) async {
    try {
      await _hostApi.transferImage(imageData, metadata.toPigeon());
    } catch (e) {
      debugPrint('Flutter: Error initiating transfer: $e');
      rethrow;
    }
  }

  Future<void> cancelTransfer(String imageId) async {
    try {
      _hostApi.cancelTransfer(imageId);
    } catch (e) {
      debugPrint('Flutter: Error cancelling transfer: $e');
      rethrow;
    }
  }

  Future<List<AppTransferHistoryItem>> getTransferHistory() async {
    try {
      final historyData = await _hostApi.getTransferHistory();
      final history = historyData
          .map((item) => AppTransferHistoryItem.fromPigeon(item))
          .toList();
      return history;
    } catch (e) {
      debugPrint('Flutter: Error getting transfer history: $e');
      return [];
    }
  }

  Future<List<AppTransferProgress>> getActiveTransfers() async {
    try {
      final transfersData = await _hostApi.getActiveTransfers();
      final transfers = transfersData
          .map((progress) => AppTransferProgress.fromPigeon(progress))
          .toList();
      return transfers;
    } catch (e) {
      debugPrint('Flutter: Error getting active transfers: $e');
      return [];
    }
  }
}


