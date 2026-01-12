import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../providers/video_providers.dart';
import '../../providers/providers.dart';
import 'video_card.dart';
import '../screens/player/video_player_screen.dart';
import '../screens/video_detail/video_detail_screen.dart';

/// Video grid widget with pull-to-refresh
class VideoGrid extends ConsumerStatefulWidget {
  const VideoGrid({super.key});

  @override
  ConsumerState<VideoGrid> createState() => _VideoGridState();
}

class _VideoGridState extends ConsumerState<VideoGrid> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load videos on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videosProvider.notifier).loadVideos();
    });
    
    // Periodic refresh every 10 seconds to catch external changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
    final serverUrl = ref.watch(serverUrlProvider);

    // Listen to WebSocket progress updates
    ref.listen(progressStreamProvider, (_, next) {
      next.whenData((progress) {
        ref.read(videosProvider.notifier).updateProgress(progress);
      });
    });

    if (serverUrl == null || serverUrl.isEmpty) {
      return _buildNoServerMessage();
    }

    if (videosState.isLoading && videosState.videos.isEmpty) {
      return _buildLoading();
    }

    if (videosState.error != null && videosState.videos.isEmpty) {
      return _buildError(videosState.error!);
    }

    if (videosState.videos.isEmpty) {
      return _buildEmpty();
    }

    return _buildGrid(videosState);
  }

  Widget _buildNoServerMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 60,
            color: AppColors.neonGreen.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'NO SERVER CONFIGURED',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Settings to add your server',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.neonGreen),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.statusFailed,
            ),
            const SizedBox(height: 16),
            Text(
              'CONNECTION ERROR',
              style: GoogleFonts.shareTechMono(
                color: AppColors.statusFailed,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.shareTechMono(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(videosProvider.notifier).loadVideos(),
              child: Text(
                'RETRY',
                style: GoogleFonts.shareTechMono(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 60,
            color: AppColors.neonGreen.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'NO VIDEOS',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a video using the + button',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(VideosState videosState) {
    final videoRepo = ref.watch(videoRepositoryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(videosProvider.notifier).refresh(),
      color: AppColors.neonGreen,
      backgroundColor: AppColors.cardBg,
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        padding: const EdgeInsets.all(8),
        itemCount: videosState.videos.length,
        itemBuilder: (context, index) {
          final video = videosState.videos[index];
          return VideoCard(
            video: video,
            thumbnailUrl: videoRepo?.getThumbnailUrl(video.videoId),
            onTap: () {
              if (video.isPlayable) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(video: video),
                  ),
                );
              }
            },
            onDetails: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoDetailScreen(video: video),
                ),
              );
            },
            onFavorite: () {
              ref.read(videosProvider.notifier).toggleFavorite(video);
            },
            onDelete: () {
              ref.read(videosProvider.notifier).deleteVideo(video.videoId);
            },
            onCancel: () {
              ref.read(videosProvider.notifier).cancelDownload(video.videoId);
            },
          );
        },
      ),
    );
  }
}
