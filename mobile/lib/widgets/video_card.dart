import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video.dart';

/// Video card widget for grid display
class VideoCard extends StatelessWidget {
  final Video video;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  const VideoCard({
    super.key,
    required this.video,
    this.thumbnailUrl,
    this.onTap,
    this.onFavorite,
    this.onDelete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                video.title,
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(color: AppColors.borderColor, height: 1),
            // Favorite option
            ListTile(
              leading: Icon(
                video.isFavorite ? Icons.favorite : Icons.favorite_outline,
                color: AppColors.neonGreen,
              ),
              title: Text(
                video.isFavorite ? 'REMOVE FAVORITE' : 'ADD TO FAVORITES',
                style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                onFavorite?.call();
              },
            ),
            // Cancel option (for downloading videos)
            if (video.isLoading)
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.statusFailed),
                title: Text(
                  'CANCEL DOWNLOAD',
                  style: GoogleFonts.shareTechMono(color: AppColors.statusFailed, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onCancel?.call();
                },
              ),
            // Delete option (for completed/failed videos)
            if (!video.isLoading)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.statusFailed),
                title: Text(
                  'DELETE VIDEO',
                  style: GoogleFonts.shareTechMono(color: AppColors.statusFailed, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image or placeholder
          if (thumbnailUrl != null && video.isPlayable)
            CachedNetworkImage(
              imageUrl: thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),
          
          // Status overlay
          if (!video.isPlayable) _buildStatusOverlay(),
          
          // Progress bar
          if (video.isLoading && video.downloadProgress != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildProgressBar(),
            ),
          
          // Duration badge
          if (video.durationSeconds != null && video.isPlayable)
            Positioned(
              right: 4,
              bottom: 4,
              child: _buildDurationBadge(),
            ),
          
          // Favorite indicator
          if (video.isFavorite)
            Positioned(
              top: 4,
              right: 4,
              child: _buildFavoriteBadge(),
            ),
        ],
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
          size: 40,
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
        statusText = '${video.downloadProgress ?? 0}%';
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
            Icon(statusIcon, color: statusColor, size: 28),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: GoogleFonts.shareTechMono(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      color: AppColors.darkGreen,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (video.downloadProgress ?? 0) / 100,
        child: Container(color: AppColors.neonGreen),
      ),
    );
  }

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.neonGreen, width: 0.5),
      ),
      child: Text(
        Formatters.formatDuration(video.durationSeconds),
        style: GoogleFonts.shareTechMono(
          color: AppColors.neonGreen,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildFavoriteBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      color: Colors.black.withValues(alpha: 0.6),
      child: const Icon(
        Icons.favorite,
        color: AppColors.neonGreen,
        size: 16,
      ),
    );
  }

  Widget _buildInfo() {
    return SizedBox(
      height: 60, // Fixed height for consistent cards
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                video.title,
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              video.channelName.toUpperCase(),
              style: GoogleFonts.shareTechMono(
                color: AppColors.neonGreen,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

