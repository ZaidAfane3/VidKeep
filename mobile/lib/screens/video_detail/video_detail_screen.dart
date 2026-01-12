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
    final videoRepo = ref.watch(videoRepositoryProvider);
    final thumbnailUrl = videoRepo?.getThumbnailUrl(video.videoId);
    
    return Scaffold(
      backgroundColor: AppColors.terminalBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(context, thumbnailUrl),
                _buildTitleSection(),
                _buildMetadataSection(),
                _buildDescriptionSection(),
                if (video.status == VideoStatus.failed && video.errorMessage != null)
                  _buildErrorSection(),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(context, ref),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
            Clipboard.setData(ClipboardData(text: video.youtubeUrl));
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

  Widget _buildThumbnail(BuildContext context, String? thumbnailUrl) {
    return GestureDetector(
      onTap: video.isPlayable
          ? () => _openPlayer(context)
          : null,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or placeholder
            if (thumbnailUrl != null && video.isPlayable)
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),
            // Play button overlay for playable videos
            if (video.isPlayable)
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
            if (!video.isPlayable) _buildStatusOverlay(),
            // Duration badge
            if (video.durationSeconds != null)
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
                    Formatters.formatDuration(video.durationSeconds),
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

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.cardBg,
      child: Center(
        child: Icon(
          video.isLoading ? Icons.downloading : Icons.videocam_outlined,
          color: AppColors.neonGreen.withValues(alpha: 0.3),
          size: 64,
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (video.status) {
      case VideoStatus.queued:
        statusColor = AppColors.statusQueued;
        statusText = 'QUEUED';
        statusIcon = Icons.schedule;
        break;
      case VideoStatus.downloading:
        statusColor = AppColors.statusDownloading;
        statusText = 'DOWNLOADING ${video.downloadProgress ?? 0}%';
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
            if (video.isLoading && video.downloadProgress != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: (video.downloadProgress ?? 0) / 100,
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

  Widget _buildTitleSection() {
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
            video.title,
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
                  video.channelName.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.neonGreen,
                    fontSize: 13,
                  ),
                ),
              ),
              // Favorite indicator
              if (video.isFavorite)
                const Icon(Icons.favorite, color: AppColors.neonGreen, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
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
            _getStatusText(),
            _getStatusColor(),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow(
            'DURATION',
            Formatters.formatDuration(video.durationSeconds),
            AppColors.textPrimary,
          ),
          const SizedBox(height: 12),
          _buildMetadataRow(
            'FILE SIZE',
            Formatters.formatFileSize(video.fileSizeBytes),
            AppColors.textPrimary,
          ),
          if (video.uploadDate != null) ...[
            const SizedBox(height: 12),
            _buildMetadataRow(
              'UPLOAD DATE',
              _formatUploadDate(video.uploadDate!),
              AppColors.textPrimary,
            ),
          ],
          const SizedBox(height: 12),
          _buildMetadataRow(
            'ADDED',
            Formatters.formatRelativeDate(video.createdAt),
            AppColors.textSecondary,
          ),
          if (video.retryCount > 0) ...[
            const SizedBox(height: 12),
            _buildMetadataRow(
              'RETRY COUNT',
              '${video.retryCount}/3',
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

  String _getStatusText() {
    switch (video.status) {
      case VideoStatus.queued:
        return 'QUEUED';
      case VideoStatus.downloading:
        return 'DOWNLOADING ${video.downloadProgress ?? 0}%';
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

  Color _getStatusColor() {
    switch (video.status) {
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

  Widget _buildDescriptionSection() {
    final description = video.description;
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

  Widget _buildErrorSection() {
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
            video.errorMessage!,
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

  Widget _buildActionBar(BuildContext context, WidgetRef ref) {
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
            if (video.isPlayable)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.play_arrow,
                  label: 'PLAY',
                  color: AppColors.neonGreen,
                  onTap: () => _openPlayer(context),
                ),
              ),
            // Cancel button (for loading videos)
            if (video.isLoading)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'CANCEL',
                  color: AppColors.statusFailed,
                  onTap: () => _cancelDownload(context, ref),
                ),
              ),
            if ((video.isPlayable || video.isLoading)) const SizedBox(width: 12),
            // Favorite button
            Expanded(
              child: _buildActionButton(
                icon: video.isFavorite ? Icons.favorite : Icons.favorite_outline,
                label: video.isFavorite ? 'UNFAV' : 'FAVORITE',
                color: AppColors.neonGreen,
                onTap: () => _toggleFavorite(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            // Delete button
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete_outline,
                label: 'DELETE',
                color: AppColors.statusFailed,
                onTap: () => _deleteVideo(context, ref),
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

  void _openPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(video: video),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(videosProvider.notifier).toggleFavorite(video);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              video.isFavorite ? 'REMOVED FROM FAVORITES' : 'ADDED TO FAVORITES',
              style: GoogleFonts.shareTechMono(fontSize: 12),
            ),
            backgroundColor: AppColors.darkGreen,
            duration: const Duration(seconds: 2),
          ),
        );
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

  void _cancelDownload(BuildContext context, WidgetRef ref) async {
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
        await ref.read(videosProvider.notifier).cancelDownload(video.videoId);
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

  void _deleteVideo(BuildContext context, WidgetRef ref) async {
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
        await ref.read(videosProvider.notifier).deleteVideo(video.videoId);
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
