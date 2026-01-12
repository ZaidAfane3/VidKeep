import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video.dart';
import '../../providers/providers.dart';
import '../../providers/video_providers.dart';
import '../player/video_player_screen.dart';

/// Video detail screen showing full metadata and actions
class VideoDetailScreen extends ConsumerWidget {
  final Video video;

  const VideoDetailScreen({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch video from state to get live updates (fixes BUG-005)
    final videosState = ref.watch(videosProvider);
    final currentVideo = videosState.videos.firstWhere(
      (v) => v.videoId == video.videoId,
      orElse: () => video, // Fallback to original if not found
    );
    
    final videoRepo = ref.watch(videoRepositoryProvider);
    final thumbnailUrl = videoRepo?.getThumbnailUrl(currentVideo.videoId);
    
    return Scaffold(
      backgroundColor: AppColors.terminalBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, currentVideo),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(context, thumbnailUrl, currentVideo),
                _buildTitleSection(currentVideo),
                _buildMetadataSection(currentVideo),
                _buildDescriptionSection(currentVideo),
                if (currentVideo.status == VideoStatus.failed && currentVideo.errorMessage != null)
                  _buildErrorSection(currentVideo),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(context, ref, currentVideo),
    );
  }

  Widget _buildAppBar(BuildContext context, Video currentVideo) {
    return SliverAppBar(
      backgroundColor: AppColors.terminalBg,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.neonGreen),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'VIDEO DETAILS',
        style: GoogleFonts.shareTechMono(
          color: AppColors.neonGreen,
          fontSize: 16,
          letterSpacing: 1.0,
        ),
      ),
      actions: [
        // Copy YouTube URL action
        IconButton(
          icon: const Icon(Icons.link, color: AppColors.neonGreen),
          tooltip: 'Copy YouTube URL',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: currentVideo.youtubeUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'URL COPIED TO CLIPBOARD',
                  style: GoogleFonts.shareTechMono(fontSize: 12),
                ),
                backgroundColor: AppColors.darkGreen,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context, String? thumbnailUrl, Video currentVideo) {
    return GestureDetector(
      onTap: currentVideo.isPlayable
          ? () => _openPlayer(context, currentVideo)
          : null,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or placeholder
            if (thumbnailUrl != null && currentVideo.isPlayable)
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(currentVideo),
                errorWidget: (context, url, error) => _buildPlaceholder(currentVideo),
              )
            else
              _buildPlaceholder(currentVideo),
            // Play button overlay for playable videos
            if (currentVideo.isPlayable)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    border: Border.all(color: AppColors.neonGreen, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: AppColors.neonGreen,
                    size: 48,
                  ),
                ),
              ),
            // Status overlay for non-playable
            if (!currentVideo.isPlayable) _buildStatusOverlay(currentVideo),
            // Duration badge
            if (currentVideo.durationSeconds != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    border: Border.all(color: AppColors.neonGreen, width: 1),
                  ),
                  child: Text(
                    Formatters.formatDuration(currentVideo.durationSeconds),
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.neonGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Video currentVideo) {
    return Container(
      color: AppColors.cardBg,
      child: Center(
        child: Icon(
          currentVideo.isLoading ? Icons.downloading : Icons.videocam_outlined,
          color: AppColors.neonGreen.withValues(alpha: 0.3),
          size: 64,
        ),
      ),
    );
  }

  Widget _buildStatusOverlay(Video currentVideo) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (currentVideo.status) {
      case VideoStatus.queued:
        statusColor = AppColors.statusQueued;
        statusText = 'QUEUED';
        statusIcon = Icons.schedule;
        break;
      case VideoStatus.downloading:
        statusColor = AppColors.statusDownloading;
        statusText = 'DOWNLOADING ${currentVideo.downloadProgress ?? 0}%';
        statusIcon = Icons.downloading;
        break;
      case VideoStatus.resuming:
        statusColor = AppColors.statusResuming;
        statusText = 'RESUMING';
        statusIcon = Icons.refresh;
        break;
      case VideoStatus.failed:
        statusColor = AppColors.statusFailed;
        statusText = 'FAILED';
        statusIcon = Icons.error_outline;
        break;
      case VideoStatus.cancelled:
        statusColor = AppColors.statusCancelled;
        statusText = 'CANCELLED';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: GoogleFonts.shareTechMono(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentVideo.isLoading && currentVideo.downloadProgress != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: (currentVideo.downloadProgress ?? 0) / 100,
                  backgroundColor: AppColors.darkGreen,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(Video currentVideo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.darkGreen, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            currentVideo.title,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Channel name with icon
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.neonGreen, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  currentVideo.channelName.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.neonGreen,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(Video currentVideo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.darkGreen, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildMetadataRow(
            'STATUS',
            _getStatusText(currentVideo),
            _getStatusColor(currentVideo),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow(
            'DURATION',
            Formatters.formatDuration(currentVideo.durationSeconds),
            AppColors.textPrimary,
          ),
          const SizedBox(height: 12),
          _buildMetadataRow(
            'FILE SIZE',
            Formatters.formatFileSize(currentVideo.fileSizeBytes),
            AppColors.textPrimary,
          ),
          if (currentVideo.uploadDate != null) ...[
            const SizedBox(height: 12),
            _buildMetadataRow(
              'UPLOAD DATE',
              _formatUploadDate(currentVideo.uploadDate!),
              AppColors.textPrimary,
            ),
          ],
          const SizedBox(height: 12),
          _buildMetadataRow(
            'ADDED',
            Formatters.formatRelativeDate(currentVideo.createdAt),
            AppColors.textSecondary,
          ),
          if (currentVideo.retryCount > 0) ...[
            const SizedBox(height: 12),
            _buildMetadataRow(
              'RETRY COUNT',
              '${currentVideo.retryCount}/3',
              AppColors.statusFailed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.shareTechMono(
              color: valueColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(Video currentVideo) {
    switch (currentVideo.status) {
      case VideoStatus.queued:
        return 'QUEUED';
      case VideoStatus.downloading:
        return 'DOWNLOADING ${currentVideo.downloadProgress ?? 0}%';
      case VideoStatus.resuming:
        return 'RESUMING';
      case VideoStatus.complete:
        return 'COMPLETE';
      case VideoStatus.failed:
        return 'FAILED';
      case VideoStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getStatusColor(Video currentVideo) {
    switch (currentVideo.status) {
      case VideoStatus.queued:
        return AppColors.statusQueued;
      case VideoStatus.downloading:
        return AppColors.statusDownloading;
      case VideoStatus.resuming:
        return AppColors.statusResuming;
      case VideoStatus.complete:
        return AppColors.neonGreen;
      case VideoStatus.failed:
        return AppColors.statusFailed;
      case VideoStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  String _formatUploadDate(String uploadDate) {
    // Format: YYYYMMDD -> YYYY-MM-DD
    if (uploadDate.length == 8) {
      return '${uploadDate.substring(0, 4)}-${uploadDate.substring(4, 6)}-${uploadDate.substring(6, 8)}';
    }
    return uploadDate;
  }

  Widget _buildDescriptionSection(Video currentVideo) {
    final description = currentVideo.description;
    if (description == null || description.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'NO DESCRIPTION AVAILABLE',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.darkGreen, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESCRIPTION',
            style: GoogleFonts.shareTechMono(
              color: AppColors.neonGreen,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(Video currentVideo) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusFailed.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.statusFailed, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.statusFailed, size: 16),
              const SizedBox(width: 8),
              Text(
                'ERROR MESSAGE',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.statusFailed,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentVideo.errorMessage!,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textPrimary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, WidgetRef ref, Video currentVideo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.neonGreen, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Play button (for complete videos)
            if (currentVideo.isPlayable)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.play_arrow,
                  label: 'PLAY',
                  color: AppColors.neonGreen,
                  onTap: () => _openPlayer(context, currentVideo),
                ),
              ),
            // Cancel button (for loading videos)
            if (currentVideo.isLoading)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'CANCEL',
                  color: AppColors.statusFailed,
                  onTap: () => _cancelDownload(context, ref, currentVideo),
                ),
              ),
            if ((currentVideo.isPlayable || currentVideo.isLoading)) const SizedBox(width: 12),
            // Favorite button
            Expanded(
              child: _buildActionButton(
                icon: currentVideo.isFavorite ? Icons.favorite : Icons.favorite_outline,
                label: currentVideo.isFavorite ? 'UNFAV' : 'FAVORITE',
                color: AppColors.neonGreen,
                onTap: () => _toggleFavorite(context, ref, currentVideo),
              ),
            ),
            const SizedBox(width: 12),
            // Delete button
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete_outline,
                label: 'DELETE',
                color: AppColors.statusFailed,
                onTap: () => _deleteVideo(context, ref, currentVideo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.shareTechMono(
                color: color,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayer(BuildContext context, Video currentVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(video: currentVideo),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, WidgetRef ref, Video currentVideo) async {
    try {
      await ref.read(videosProvider.notifier).toggleFavorite(currentVideo);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERROR: ${e.toString()}',
              style: GoogleFonts.shareTechMono(fontSize: 12),
            ),
            backgroundColor: AppColors.statusFailed,
          ),
        );
      }
    }
  }

  void _cancelDownload(BuildContext context, WidgetRef ref, Video currentVideo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'CANCEL DOWNLOAD?',
          style: GoogleFonts.shareTechMono(
            color: AppColors.neonGreen,
            fontSize: 16,
          ),
        ),
        content: Text(
          'This will stop the download and remove the video from the queue.',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'NO',
              style: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'YES',
              style: GoogleFonts.shareTechMono(color: AppColors.statusFailed),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(videosProvider.notifier).cancelDownload(currentVideo.videoId);
        if (context.mounted) {
          Navigator.pop(context); // Go back after cancel
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ERROR: ${e.toString()}',
                style: GoogleFonts.shareTechMono(fontSize: 12),
              ),
              backgroundColor: AppColors.statusFailed,
            ),
          );
        }
      }
    }
  }

  void _deleteVideo(BuildContext context, WidgetRef ref, Video currentVideo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'DELETE VIDEO?',
          style: GoogleFonts.shareTechMono(
            color: AppColors.statusFailed,
            fontSize: 16,
          ),
        ),
        content: Text(
          'This action cannot be undone. The video file will be permanently removed.',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DELETE',
              style: GoogleFonts.shareTechMono(color: AppColors.statusFailed),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(videosProvider.notifier).deleteVideo(currentVideo.videoId);
        if (context.mounted) {
          Navigator.pop(context); // Go back after delete
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ERROR: ${e.toString()}',
                style: GoogleFonts.shareTechMono(fontSize: 12),
              ),
              backgroundColor: AppColors.statusFailed,
            ),
          );
        }
      }
    }
  }
}
