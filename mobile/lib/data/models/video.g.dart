// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
  videoId: json['video_id'] as String,
  title: json['title'] as String,
  channelName: json['channel_name'] as String,
  channelId: json['channel_id'] as String?,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  uploadDate: json['upload_date'] as String?,
  description: json['description'] as String?,
  isFavorite: json['is_favorite'] as bool? ?? false,
  status: $enumDecode(_$VideoStatusEnumMap, json['status']),
  fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  errorMessage: json['error_message'] as String?,
  youtubeUrl: json['youtube_url'] as String,
  downloadProgress: (json['download_progress'] as num?)?.toInt(),
  retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
  resumedBytes: (json['resumed_bytes'] as num?)?.toInt(),
);

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
  'video_id': instance.videoId,
  'title': instance.title,
  'channel_name': instance.channelName,
  'channel_id': instance.channelId,
  'duration_seconds': instance.durationSeconds,
  'upload_date': instance.uploadDate,
  'description': instance.description,
  'is_favorite': instance.isFavorite,
  'status': _$VideoStatusEnumMap[instance.status]!,
  'file_size_bytes': instance.fileSizeBytes,
  'created_at': instance.createdAt.toIso8601String(),
  'error_message': instance.errorMessage,
  'youtube_url': instance.youtubeUrl,
  'download_progress': instance.downloadProgress,
  'retry_count': instance.retryCount,
  'resumed_bytes': instance.resumedBytes,
};

const _$VideoStatusEnumMap = {
  VideoStatus.queued: 'queued',
  VideoStatus.downloading: 'downloading',
  VideoStatus.resuming: 'resuming',
  VideoStatus.complete: 'complete',
  VideoStatus.failed: 'failed',
  VideoStatus.cancelled: 'cancelled',
};
