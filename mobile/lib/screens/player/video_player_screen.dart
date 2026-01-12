import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video.dart';
import '../../providers/providers.dart';

/// Full-screen video player using chewie
class VideoPlayerScreen extends ConsumerStatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoRepo = ref.read(videoRepositoryProvider);
    if (videoRepo == null) {
      setState(() => _error = 'Server not configured');
      return;
    }

    final streamUrl = videoRepo.getStreamUrl(widget.video.videoId);

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.neonGreen,
          handleColor: AppColors.neonGreen,
          bufferedColor: AppColors.darkGreen,
          backgroundColor: AppColors.cardBg,
        ),
        placeholder: Container(
          color: AppColors.terminalBg,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.neonGreen),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: AppColors.statusFailed, size: 48),
                const SizedBox(height: 16),
                Text(
                  'PLAYBACK ERROR',
                  style: GoogleFonts.shareTechMono(color: AppColors.statusFailed),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = 'Failed to load video: $e');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Restore portrait orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.terminalBg,
      appBar: AppBar(
        backgroundColor: AppColors.terminalBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neonGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.video.title,
          style: GoogleFonts.shareTechMono(
            color: AppColors.neonGreen,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Video player
          Expanded(
            child: _buildPlayer(),
          ),
          // Video info
          _buildVideoInfo(),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.statusFailed, size: 60),
              const SizedBox(height: 16),
              Text(
                'ERROR',
                style: GoogleFonts.shareTechMono(color: AppColors.statusFailed),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.neonGreen),
            SizedBox(height: 16),
            Text(
              'LOADING VIDEO...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                widget.video.channelName.toUpperCase(),
                style: GoogleFonts.shareTechMono(
                  color: AppColors.neonGreen,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (widget.video.durationSeconds != null)
                Text(
                  Formatters.formatDuration(widget.video.durationSeconds),
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (widget.video.uploadDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Uploaded: ${widget.video.uploadDate}',
              style: GoogleFonts.shareTechMono(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
