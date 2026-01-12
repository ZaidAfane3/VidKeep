import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../data/models/video.dart';
import '../../data/models/queue_status.dart';
import '../../providers/video_providers.dart';

/// Queue screen showing downloading and queued videos
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load videos immediately when queue tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videosProvider.notifier).loadVideos();
      ref.invalidate(queueStatusProvider);
    });

    // Periodic refresh every 5 seconds for queue (faster than grid)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.read(videosProvider.notifier).loadVideos();
      ref.invalidate(queueStatusProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videosState = ref.watch(videosProvider);
    final queueStatus = ref.watch(queueStatusProvider);

    // Listen to WebSocket progress updates for real-time updates
    ref.listen(progressStreamProvider, (_, next) {
      next.whenData((progress) {
        ref.read(videosProvider.notifier).updateProgress(progress);
        // If download completed (100%), refresh to update status
        if (progress.percent >= 100) {
          ref.read(videosProvider.notifier).refresh();
          ref.invalidate(queueStatusProvider);
        }
      });
    });

    // Filter to show only queued/downloading/resuming videos
    final queuedVideos = videosState.videos.where((v) => v.isLoading).toList();

    return Column(
      children: [
        // Queue status header
        _buildStatusHeader(queueStatus),
        // Queue list
        Expanded(
          child: queuedVideos.isEmpty
              ? _buildEmptyState()
              : _buildQueueList(context, ref, queuedVideos),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(AsyncValue<QueueStatus?> queueStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: queueStatus.when(
        data: (status) => Row(
          children: [
            const Icon(Icons.download, color: AppColors.neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'QUEUE STATUS',
              style: GoogleFonts.shareTechMono(
                color: AppColors.neonGreen,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (status != null) ...[
              _buildStatusBadge('PENDING', status.pending, AppColors.statusQueued),
              const SizedBox(width: 8),
              _buildStatusBadge('ACTIVE', status.processing, AppColors.neonGreen),
            ],
          ],
        ),
        loading: () => const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.neonGreen,
            ),
          ),
        ),
        error: (e, _) => Text(
          'Error loading status',
          style: GoogleFonts.shareTechMono(color: AppColors.statusFailed),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$label: $count',
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 60,
            color: AppColors.neonGreen.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'QUEUE EMPTY',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No downloads in progress',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(BuildContext context, WidgetRef ref, List<Video> videos) {
    return RefreshIndicator(
      onRefresh: () => ref.read(videosProvider.notifier).refresh(),
      color: AppColors.neonGreen,
      backgroundColor: AppColors.cardBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return _buildQueueItem(context, ref, video);
        },
      ),
    );
  }

  Widget _buildQueueItem(BuildContext context, WidgetRef ref, Video video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(video.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      video.channelName.toUpperCase(),
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Cancel button
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.statusFailed, size: 20),
                onPressed: () => _showCancelDialog(context, ref, video),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (video.downloadProgress != null) ...[
            const SizedBox(height: 8),
            _buildProgressBar(video),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(VideoStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case VideoStatus.queued:
        icon = Icons.schedule;
        color = AppColors.statusQueued;
        break;
      case VideoStatus.downloading:
        icon = Icons.downloading;
        color = AppColors.neonGreen;
        break;
      case VideoStatus.resuming:
        icon = Icons.refresh;
        color = AppColors.statusResuming;
        break;
      default:
        icon = Icons.help_outline;
        color = AppColors.textSecondary;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildProgressBar(Video video) {
    final percent = video.downloadProgress ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkGreen,
                  border: Border.all(color: AppColors.borderColor, width: 0.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent / 100,
                  child: Container(color: AppColors.neonGreen),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percent%',
              style: GoogleFonts.shareTechMono(
                color: AppColors.neonGreen,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, Video video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'CANCEL DOWNLOAD?',
          style: GoogleFonts.shareTechMono(color: AppColors.neonGreen),
        ),
        content: Text(
          video.title,
          style: GoogleFonts.shareTechMono(color: AppColors.textSecondary, fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NO',
              style: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(videosProvider.notifier).cancelDownload(video.videoId);
            },
            style: ElevatedButton.styleFrom(
              side: const BorderSide(color: AppColors.statusFailed),
            ),
            child: Text(
              'CANCEL',
              style: GoogleFonts.shareTechMono(color: AppColors.statusFailed),
            ),
          ),
        ],
      ),
    );
  }
}
