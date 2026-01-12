import 'package:vidkeep_mobile/data/models/video.dart';

/// Sample video data for testing
class MockData {
  static Video get completedVideo => Video(
    videoId: 'test-video-1',
    youtubeUrl: 'https://youtube.com/watch?v=test1',
    title: 'Test Video Complete',
    channelName: 'Test Channel',
    status: VideoStatus.complete,
    isFavorite: false,
    retryCount: 0,
    createdAt: DateTime.now(),
    durationSeconds: 3600,
    fileSizeBytes: 100 * 1024 * 1024,
  );

  static Video get favoriteVideo => completedVideo.copyWith(
    videoId: 'test-video-2',
    isFavorite: true,
  );

  static Video get downloadingVideo => Video(
    videoId: 'test-video-3',
    youtubeUrl: 'https://youtube.com/watch?v=test3',
    title: 'Test Video Downloading',
    channelName: 'Test Channel',
    status: VideoStatus.downloading,
    downloadProgress: 50,
    isFavorite: false,
    retryCount: 0,
    createdAt: DateTime.now(),
  );

  static Video get failedVideo => Video(
    videoId: 'test-video-4',
    youtubeUrl: 'https://youtube.com/watch?v=test4',
    title: 'Test Video Failed',
    channelName: 'Test Channel',
    status: VideoStatus.failed,
    errorMessage: 'Download failed: Network error',
    isFavorite: false,
    retryCount: 2,
    createdAt: DateTime.now(),
  );

  static Video get queuedVideo => Video(
    videoId: 'test-video-5',
    youtubeUrl: 'https://youtube.com/watch?v=test5',
    title: 'Test Video Queued',
    channelName: 'Test Channel',
    status: VideoStatus.queued,
    isFavorite: false,
    retryCount: 0,
    createdAt: DateTime.now(),
  );

  static List<Video> get sampleVideos => [
    completedVideo,
    favoriteVideo,
    downloadingVideo,
    failedVideo,
    queuedVideo,
  ];
}
