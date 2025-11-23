import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/image_transfer.dart';
import '../providers/image_transfer_provider.dart';

class ImageTransferPage extends ConsumerWidget {
  const ImageTransferPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferHistory = ref.watch(transferHistoryProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Transfer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(transferHistoryProvider.notifier).refresh();
              ref.read(activeTransfersProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          activeTransfers.when(
            data: (transfers) {
              if (transfers.isEmpty) {
                return const SizedBox.shrink();
              }
              return ActiveTransfersSection(transfers: transfers);
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          Expanded(
            child: transferHistory.when(
              data: (history) {
                if (history.isEmpty) {
                  return const EmptyStateView();
                }
                return TransferHistoryList(history: history);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('エラー: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndTransferImage(context, ref),
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('画像を選択'),
      ),
    );
  }

  Future<void> _pickAndTransferImage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final imageBytes = await pickedFile.readAsBytes();
      final image = await decodeImageFromList(imageBytes);
      final width = image.width;
      final height = image.height;

      final metadata = AppImageMetadata(
        id: const Uuid().v4(),
        fileName: pickedFile.name,
        fileSize: imageBytes.length,
        width: width,
        height: height,
        timestamp: DateTime.now(),
      );

      await ref.read(transferHistoryProvider.notifier).transferImage(
            Uint8List.fromList(imageBytes),
            metadata,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('転送を開始しました: ${metadata.fileName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ActiveTransfersSection extends StatelessWidget {
  final List<AppTransferProgress> transfers;

  const ActiveTransfersSection({
    super.key,
    required this.transfers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '転送中 (${transfers.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              return TransferProgressCard(progress: transfers[index]);
            },
          ),
        ],
      ),
    );
  }
}

class TransferProgressCard extends ConsumerWidget {
  final AppTransferProgress progress;

  const TransferProgressCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Image ${progress.imageId.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, size: 20),
                  onPressed: () {
                    ref
                        .read(activeTransfersProvider.notifier)
                        .cancelTransfer(progress.imageId);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.progressPercent}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${progress.bytesTransferredFormatted} / ${progress.totalBytesFormatted}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      progress.transferSpeedFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '残り ${progress.estimatedTimeRemainingFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransferHistoryList extends StatelessWidget {
  final List<AppTransferHistoryItem> history;

  const TransferHistoryList({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[history.length - 1 - index];
        return TransferHistoryCard(item: item);
      },
    );
  }
}

class TransferHistoryCard extends StatelessWidget {
  final AppTransferHistoryItem item;

  const TransferHistoryCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);
    final statusIcon = _getStatusIcon(item.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.image,
            color: Colors.grey.shade500,
            size: 28,
          ),
        ),
        title: Text(
          item.metadata.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${item.metadata.fileSizeFormatted} • ${item.metadata.resolution}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('yyyy/MM/dd HH:mm').format(item.metadata.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                item.statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return Colors.grey;
      case TransferStatus.transferring:
        return Colors.blue;
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return Icons.schedule;
      case TransferStatus.transferring:
        return Icons.sync;
      case TransferStatus.completed:
        return Icons.check_circle;
      case TransferStatus.failed:
        return Icons.error;
      case TransferStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '画像を転送してみましょう',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下の「画像を選択」ボタンから開始',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}


