import 'package:dio/dio.dart';
import '../models/video.dart';
import '../models/channel.dart';
import '../models/queue_status.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';

/// API client for VidKeep backend
class VidKeepApiClient {
  final Dio _dio;
  final String baseUrl;

  VidKeepApiClient({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: AppConfig.httpConnectTimeoutSec),
          receiveTimeout: Duration(seconds: AppConfig.httpReceiveTimeoutSec),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(ApiConstants.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// GET /api/videos - List all videos with optional filters
  Future<List<Video>> getVideos({
    String? channel,
    bool favoritesOnly = false,
    String? statusFilter,
  }) async {
    final response = await _dio.get(
      ApiConstants.videos,
      queryParameters: {
        if (channel != null && channel.isNotEmpty) 'channel': channel,
        if (favoritesOnly) 'favorites_only': 'true',
        if (statusFilter != null) 'status_filter': statusFilter,
      },
    );
    
    final videos = response.data['videos'] as List;
    return videos.map((json) => Video.fromJson(json)).toList();
  }

  /// GET /api/videos/{id} - Get single video details
  Future<Video> getVideo(String videoId) async {
    final response = await _dio.get(ApiConstants.video(videoId));
    return Video.fromJson(response.data);
  }

  /// POST /api/videos/ingest - Queue video for download
  Future<String> ingestVideo(String url) async {
    final response = await _dio.post(
      ApiConstants.ingest,
      data: {'url': url},
    );
    return response.data['video_id'];
  }

  /// PATCH /api/videos/{id} - Update video (favorite status)
  Future<Video> updateFavorite(String videoId, bool isFavorite) async {
    final response = await _dio.patch(
      ApiConstants.video(videoId),
      data: {'is_favorite': isFavorite},
    );
    return Video.fromJson(response.data);
  }

  /// DELETE /api/videos/{id} - Delete video
  Future<void> deleteVideo(String videoId) async {
    await _dio.delete(ApiConstants.video(videoId));
  }

  /// POST /api/videos/{id}/cancel - Cancel download
  Future<void> cancelDownload(String videoId) async {
    await _dio.post(ApiConstants.cancel(videoId));
  }

  /// GET /api/channels - List all channels
  Future<List<Channel>> getChannels() async {
    final response = await _dio.get(ApiConstants.channels);
    final channels = response.data['channels'] as List;
    return channels.map((json) => Channel.fromJson(json)).toList();
  }

  /// GET /api/queue/status - Get download queue status
  Future<QueueStatus> getQueueStatus() async {
    final response = await _dio.get(ApiConstants.queueStatus);
    return QueueStatus.fromJson(response.data);
  }

  /// Get full stream URL for video playback
  String getStreamUrl(String videoId) => '$baseUrl${ApiConstants.stream(videoId)}';

  /// Get full thumbnail URL
  String getThumbnailUrl(String videoId) => '$baseUrl${ApiConstants.thumbnail(videoId)}';

  /// Get WebSocket URL for progress updates
  String getWebSocketUrl() {
    final wsScheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    return '$wsScheme://$host${ApiConstants.wsProgress}';
  }
}
