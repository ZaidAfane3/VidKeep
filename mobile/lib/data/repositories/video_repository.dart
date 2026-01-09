import '../models/video.dart';
import '../datasources/api_client.dart';

/// Repository for video operations
class VideoRepository {
  final VidKeepApiClient _apiClient;

  VideoRepository(this._apiClient);

  /// Get all videos with optional filters
  Future<List<Video>> getVideos({
    String? channel,
    bool favoritesOnly = false,
    String? statusFilter,
  }) {
    return _apiClient.getVideos(
      channel: channel,
      favoritesOnly: favoritesOnly,
      statusFilter: statusFilter,
    );
  }

  /// Get single video by ID
  Future<Video> getVideo(String videoId) {
    return _apiClient.getVideo(videoId);
  }

  /// Submit URL for download
  Future<String> ingestVideo(String url) {
    return _apiClient.ingestVideo(url);
  }

  /// Toggle favorite status
  Future<Video> toggleFavorite(Video video) {
    return _apiClient.updateFavorite(video.videoId, !video.isFavorite);
  }

  /// Delete video
  Future<void> deleteVideo(String videoId) {
    return _apiClient.deleteVideo(videoId);
  }

  /// Cancel ongoing download
  Future<void> cancelDownload(String videoId) {
    return _apiClient.cancelDownload(videoId);
  }

  /// Get stream URL for video playback
  String getStreamUrl(String videoId) {
    return _apiClient.getStreamUrl(videoId);
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String videoId) {
    return _apiClient.getThumbnailUrl(videoId);
  }
}
