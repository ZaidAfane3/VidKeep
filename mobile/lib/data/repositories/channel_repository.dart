import '../models/channel.dart';
import '../models/queue_status.dart';
import '../datasources/api_client.dart';

/// Repository for channel and queue operations
class ChannelRepository {
  final VidKeepApiClient _apiClient;

  ChannelRepository(this._apiClient);

  /// Get all channels with video counts
  Future<List<Channel>> getChannels() {
    return _apiClient.getChannels();
  }

  /// Get current queue status
  Future<QueueStatus> getQueueStatus() {
    return _apiClient.getQueueStatus();
  }
}
