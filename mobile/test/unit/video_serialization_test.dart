import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidkeep_mobile/data/models/video.dart';

void main() {
  group('Video JSON Serialization', () {
    test('fromJson parses complete video correctly', () {
      final json = {
        'video_id': 'test-123',
        'title': 'Test Video',
        'channel_name': 'Test Channel',
        'channel_id': 'channel-456',
        'duration_seconds': 3600,
        'upload_date': '2025-01-01',
        'description': 'A test video description',
        'is_favorite': true,
        'status': 'complete',
        'file_size_bytes': 100000000,
        'created_at': '2025-01-12T10:00:00Z',
        'error_message': null,
        'youtube_url': 'https://youtube.com/watch?v=test123',
        'download_progress': null,
        'retry_count': 0,
        'resumed_bytes': null,
      };

      final video = Video.fromJson(json);

      expect(video.videoId, 'test-123');
      expect(video.title, 'Test Video');
      expect(video.channelName, 'Test Channel');
      expect(video.channelId, 'channel-456');
      expect(video.durationSeconds, 3600);
      expect(video.uploadDate, '2025-01-01');
      expect(video.description, 'A test video description');
      expect(video.isFavorite, true);
      expect(video.status, VideoStatus.complete);
      expect(video.fileSizeBytes, 100000000);
      expect(video.youtubeUrl, 'https://youtube.com/watch?v=test123');
      expect(video.retryCount, 0);
    });

    test('fromJson handles downloading status with progress', () {
      final json = {
        'video_id': 'test-456',
        'title': 'Downloading Video',
        'channel_name': 'Channel',
        'status': 'downloading',
        'download_progress': 75,
        'is_favorite': false,
        'youtube_url': 'https://youtube.com/watch?v=test456',
        'created_at': '2025-01-12T10:00:00Z',
        'retry_count': 0,
      };

      final video = Video.fromJson(json);

      expect(video.status, VideoStatus.downloading);
      expect(video.downloadProgress, 75);
      expect(video.isLoading, true);
      expect(video.isPlayable, false);
    });

    test('fromJson handles failed status with error', () {
      final json = {
        'video_id': 'test-789',
        'title': 'Failed Video',
        'channel_name': 'Channel',
        'status': 'failed',
        'error_message': 'Download failed: Network error',
        'is_favorite': false,
        'youtube_url': 'https://youtube.com/watch?v=test789',
        'created_at': '2025-01-12T10:00:00Z',
        'retry_count': 3,
      };

      final video = Video.fromJson(json);

      expect(video.status, VideoStatus.failed);
      expect(video.errorMessage, 'Download failed: Network error');
      expect(video.retryCount, 3);
    });

    test('fromJson handles resuming status with resumed bytes', () {
      final json = {
        'video_id': 'test-resume',
        'title': 'Resuming Video',
        'channel_name': 'Channel',
        'status': 'resuming',
        'download_progress': 50,
        'resumed_bytes': 50000000,
        'is_favorite': false,
        'youtube_url': 'https://youtube.com/watch?v=resume',
        'created_at': '2025-01-12T10:00:00Z',
        'retry_count': 1,
      };

      final video = Video.fromJson(json);

      expect(video.status, VideoStatus.resuming);
      expect(video.resumedBytes, 50000000);
      expect(video.isLoading, true);
    });

    test('toJson produces correct output', () {
      final video = Video(
        videoId: 'test-123',
        title: 'Test Video',
        channelName: 'Test Channel',
        status: VideoStatus.complete,
        isFavorite: true,
        youtubeUrl: 'https://youtube.com/watch?v=test123',
        createdAt: DateTime.parse('2025-01-12T10:00:00Z'),
        retryCount: 0,
        durationSeconds: 3600,
        fileSizeBytes: 100000000,
      );

      final json = video.toJson();

      expect(json['video_id'], 'test-123');
      expect(json['title'], 'Test Video');
      expect(json['channel_name'], 'Test Channel');
      expect(json['status'], 'complete');
      expect(json['is_favorite'], true);
      expect(json['youtube_url'], 'https://youtube.com/watch?v=test123');
      expect(json['duration_seconds'], 3600);
      expect(json['file_size_bytes'], 100000000);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final originalJson = {
        'video_id': 'roundtrip-test',
        'title': 'Roundtrip Test',
        'channel_name': 'Test Channel',
        'channel_id': 'ch-123',
        'duration_seconds': 1800,
        'upload_date': '2025-06-15',
        'description': 'Test description',
        'is_favorite': true,
        'status': 'complete',
        'file_size_bytes': 50000000,
        'created_at': '2025-01-12T10:00:00.000Z',
        'error_message': null,
        'youtube_url': 'https://youtube.com/watch?v=roundtrip',
        'download_progress': null,
        'retry_count': 0,
        'resumed_bytes': null,
      };

      final video = Video.fromJson(originalJson);
      final outputJson = video.toJson();

      expect(outputJson['video_id'], originalJson['video_id']);
      expect(outputJson['title'], originalJson['title']);
      expect(outputJson['channel_name'], originalJson['channel_name']);
      expect(outputJson['status'], originalJson['status']);
      expect(outputJson['is_favorite'], originalJson['is_favorite']);
    });

    test('fromJson handles all VideoStatus values', () {
      final statuses = ['queued', 'downloading', 'resuming', 'complete', 'failed', 'cancelled'];
      final expectedEnums = [
        VideoStatus.queued,
        VideoStatus.downloading,
        VideoStatus.resuming,
        VideoStatus.complete,
        VideoStatus.failed,
        VideoStatus.cancelled,
      ];

      for (var i = 0; i < statuses.length; i++) {
        final json = {
          'video_id': 'test-$i',
          'title': 'Test',
          'channel_name': 'Channel',
          'status': statuses[i],
          'is_favorite': false,
          'youtube_url': 'https://youtube.com/watch?v=test$i',
          'created_at': '2025-01-12T10:00:00Z',
          'retry_count': 0,
        };

        final video = Video.fromJson(json);
        expect(video.status, expectedEnums[i], reason: 'Status ${statuses[i]} should parse correctly');
      }
    });
  });
}
