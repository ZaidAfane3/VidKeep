/// API endpoint constants
class ApiConstants {
  /// Video endpoints
  static const String videos = '/api/videos';
  static const String ingest = '/api/videos/ingest';
  static String video(String id) => '/api/videos/$id';
  static String cancel(String id) => '/api/videos/$id/cancel';
  
  /// Stream and thumbnail endpoints
  static String stream(String id) => '/api/stream/$id';
  static String thumbnail(String id) => '/api/thumbnail/$id';
  
  /// Other endpoints
  static const String channels = '/api/channels';
  static const String queueStatus = '/api/queue/status';
  static const String health = '/health';
  
  /// WebSocket endpoint
  static const String wsProgress = '/ws/progress';
}
