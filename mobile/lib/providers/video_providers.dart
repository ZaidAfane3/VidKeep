import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/video.dart';
import '../data/models/channel.dart';
import '../data/models/queue_status.dart';
import '../data/datasources/websocket_client.dart';
import 'providers.dart';
import 'download_providers.dart';

/// Videos list state
class VideosState {
  final List<Video> videos;
  final bool isLoading;
  final String? error;
  final String? channelFilter;
  final bool favoritesOnly;
  final bool isOfflineMode;

  const VideosState({
    this.videos = const [],
    this.isLoading = false,
    this.error,
    this.channelFilter,
    this.favoritesOnly = false,
    this.isOfflineMode = false,
  });

  VideosState copyWith({
    List<Video>? videos,
    bool? isLoading,
    String? error,
    String? channelFilter,
    bool clearChannelFilter = false,
    bool? favoritesOnly,
    bool? isOfflineMode,
  }) {
    return VideosState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      channelFilter: clearChannelFilter ? null : (channelFilter ?? this.channelFilter),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Videos state notifier
class VideosNotifier extends StateNotifier<VideosState> {
  final Ref _ref;

  VideosNotifier(this._ref) : super(const VideosState());

  /// Load videos from API
  Future<void> loadVideos() async {
    final repo = _ref.read(videoRepositoryProvider);
    if (repo == null) {
      // No server configured - try loading offline videos
      await _loadOfflineVideos();
      return;
    }

    state = state.copyWith(isLoading: true, error: null, isOfflineMode: false);

    try {
      final apiVideos = await repo.getVideos(
        channel: state.channelFilter,
        favoritesOnly: state.favoritesOnly,
      );
      
      // Preserve WebSocket progress for videos that are downloading
      // API doesn't have real-time progress, only WebSocket does
      final currentProgress = <String, int>{};
      for (final v in state.videos) {
        if (v.downloadProgress != null && v.downloadProgress! > 0) {
          currentProgress[v.videoId] = v.downloadProgress!;
        }
      }
      
      // Merge progress into API results
      final mergedVideos = apiVideos.map((v) {
        final savedProgress = currentProgress[v.videoId];
        if (savedProgress != null && savedProgress > (v.downloadProgress ?? 0)) {
          return v.copyWith(downloadProgress: savedProgress);
        }
        return v;
      }).toList();
      
      state = state.copyWith(videos: mergedVideos, isLoading: false, isOfflineMode: false);
    } catch (e) {
      // Server unreachable - fall back to offline videos
      await _loadOfflineVideos();
    }
  }
  
  /// Load videos from local database (offline mode)
  Future<void> _loadOfflineVideos() async {
    final offlineVideosAsync = _ref.read(offlineVideosProvider);
    
    offlineVideosAsync.when(
      data: (offlineVideos) {
        if (offlineVideos.isNotEmpty) {
          state = state.copyWith(
            videos: offlineVideos,
            isLoading: false,
            isOfflineMode: true,
            error: null,
          );
        } else {
          state = state.copyWith(
            error: 'Server offline. No downloaded videos available.',
            isLoading: false,
            isOfflineMode: true,
          );
        }
      },
      loading: () => state = state.copyWith(isLoading: true),
      error: (e, _) => state = state.copyWith(
        error: 'Server offline. Could not load local videos.',
        isLoading: false,
        isOfflineMode: true,
      ),
    );
  }

  /// Refresh videos (pull-to-refresh)
  /// Also resets WebSocket retry counter to allow reconnection attempts
  Future<void> refresh() {
    // Reset WebSocket retry counter on refresh
    final wsClient = _ref.read(webSocketClientProvider);
    wsClient.resetRetries();
    
    return loadVideos();
  }

  /// Set channel filter
  void setChannelFilter(String? channel) {
    if (channel == null) {
      state = state.copyWith(clearChannelFilter: true);
    } else {
      state = state.copyWith(channelFilter: channel);
    }
    loadVideos();
  }

  /// Toggle favorites filter
  void toggleFavoritesOnly() {
    state = state.copyWith(favoritesOnly: !state.favoritesOnly);
    loadVideos();
  }

  /// Toggle favorite status for a video
  Future<void> toggleFavorite(Video video) async {
    final repo = _ref.read(videoRepositoryProvider);
    if (repo == null) return;

    try {
      final updated = await repo.toggleFavorite(video);
      state = state.copyWith(
        videos: state.videos.map((v) => v.videoId == updated.videoId ? updated : v).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a video
  Future<void> deleteVideo(String videoId) async {
    final repo = _ref.read(videoRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.deleteVideo(videoId);
      state = state.copyWith(
        videos: state.videos.where((v) => v.videoId != videoId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Cancel a download
  Future<void> cancelDownload(String videoId) async {
    final repo = _ref.read(videoRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.cancelDownload(videoId);
      await loadVideos(); // Refresh to get updated status
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update video progress from WebSocket
  void updateProgress(DownloadProgress progress) {
    state = state.copyWith(
      videos: state.videos.map((v) {
        if (v.videoId == progress.videoId) {
          return v.copyWith(
            downloadProgress: progress.percent,
            status: progress.percent >= 100 ? VideoStatus.complete : VideoStatus.downloading,
          );
        }
        return v;
      }).toList(),
    );
  }
}

/// Videos provider
final videosProvider = StateNotifierProvider<VideosNotifier, VideosState>((ref) {
  return VideosNotifier(ref);
});

/// Channels provider
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final repo = ref.watch(channelRepositoryProvider);
  if (repo == null) return [];
  return repo.getChannels();
});

/// Queue status provider
final queueStatusProvider = FutureProvider<QueueStatus?>((ref) async {
  final repo = ref.watch(channelRepositoryProvider);
  if (repo == null) return null;
  return repo.getQueueStatus();
});

/// WebSocket progress stream provider
final progressStreamProvider = StreamProvider<DownloadProgress>((ref) {
  final wsClient = ref.watch(webSocketClientProvider);
  return wsClient.progressStream;
});
