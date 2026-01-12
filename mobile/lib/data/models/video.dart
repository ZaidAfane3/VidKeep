import 'package:json_annotation/json_annotation.dart';

part 'video.g.dart';

/// Video status enum matching backend
enum VideoStatus {
  @JsonValue('queued')
  queued,
  @JsonValue('downloading')
  downloading,
  @JsonValue('resuming')
  resuming,
  @JsonValue('complete')
  complete,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

/// Video model matching backend API response
@JsonSerializable()
class Video {
  @JsonKey(name: 'video_id')
  final String videoId;
  
  final String title;
  
  @JsonKey(name: 'channel_name')
  final String channelName;
  
  @JsonKey(name: 'channel_id')
  final String? channelId;
  
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  
  @JsonKey(name: 'upload_date')
  final String? uploadDate;
  
  final String? description;
  
  @JsonKey(name: 'is_favorite')
  final bool isFavorite;
  
  final VideoStatus status;
  
  @JsonKey(name: 'file_size_bytes')
  final int? fileSizeBytes;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  
  @JsonKey(name: 'youtube_url')
  final String youtubeUrl;
  
  @JsonKey(name: 'download_progress')
  final int? downloadProgress;
  
  @JsonKey(name: 'retry_count')
  final int retryCount;
  
  @JsonKey(name: 'resumed_bytes')
  final int? resumedBytes;

  Video({
    required this.videoId,
    required this.title,
    required this.channelName,
    this.channelId,
    this.durationSeconds,
    this.uploadDate,
    this.description,
    this.isFavorite = false,
    required this.status,
    this.fileSizeBytes,
    required this.createdAt,
    this.errorMessage,
    required this.youtubeUrl,
    this.downloadProgress,
    this.retryCount = 0,
    this.resumedBytes,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  
  Map<String, dynamic> toJson() => _$VideoToJson(this);
  
  /// Create a copy with updated fields
  Video copyWith({
    String? videoId,
    String? title,
    String? channelName,
    String? channelId,
    int? durationSeconds,
    String? uploadDate,
    String? description,
    bool? isFavorite,
    VideoStatus? status,
    int? fileSizeBytes,
    DateTime? createdAt,
    String? errorMessage,
    String? youtubeUrl,
    int? downloadProgress,
    int? retryCount,
    int? resumedBytes,
  }) {
    return Video(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      channelId: channelId ?? this.channelId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      uploadDate: uploadDate ?? this.uploadDate,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      retryCount: retryCount ?? this.retryCount,
      resumedBytes: resumedBytes ?? this.resumedBytes,
    );
  }
  
  /// Check if video is in a loading state
  bool get isLoading => 
      status == VideoStatus.queued || 
      status == VideoStatus.downloading || 
      status == VideoStatus.resuming;
      
  /// Check if video is playable
  bool get isPlayable => status == VideoStatus.complete;
}
