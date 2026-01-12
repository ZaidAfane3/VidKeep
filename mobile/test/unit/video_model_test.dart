import 'package:flutter_test/flutter_test.dart';
import 'package:vidkeep_mobile/data/models/video.dart';

void main() {
  group('Video model', () {
    late Video completedVideo;
    late Video downloadingVideo;
    late Video queuedVideo;
    late Video failedVideo;

    setUp(() {
      completedVideo = Video(
        videoId: 'test-1',
        youtubeUrl: 'https://youtube.com/watch?v=test',
        title: 'Test Video',
        channelName: 'Test Channel',
        status: VideoStatus.complete,
        isFavorite: false,
        retryCount: 0,
        createdAt: DateTime.now(),
      );

      downloadingVideo = completedVideo.copyWith(
        status: VideoStatus.downloading,
        downloadProgress: 50,
      );

      queuedVideo = completedVideo.copyWith(
        status: VideoStatus.queued,
      );

      failedVideo = completedVideo.copyWith(
        status: VideoStatus.failed,
        errorMessage: 'Test error',
      );
    });

    test('isPlayable returns true only for complete status', () {
      expect(completedVideo.isPlayable, true);
      expect(downloadingVideo.isPlayable, false);
      expect(queuedVideo.isPlayable, false);
      expect(failedVideo.isPlayable, false);
    });

    test('isLoading returns true for downloading/resuming/queued', () {
      expect(completedVideo.isLoading, false);
      expect(downloadingVideo.isLoading, true);
      expect(queuedVideo.isLoading, true);
      expect(failedVideo.isLoading, false);

      final resumingVideo = completedVideo.copyWith(status: VideoStatus.resuming);
      expect(resumingVideo.isLoading, true);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = completedVideo.copyWith(
        isFavorite: true,
        title: 'Updated Title',
      );

      expect(updated.isFavorite, true);
      expect(updated.title, 'Updated Title');
      expect(updated.videoId, completedVideo.videoId);
      expect(updated.channelName, completedVideo.channelName);
    });

    test('copyWith preserves original values when not specified', () {
      final updated = completedVideo.copyWith(isFavorite: true);

      expect(updated.videoId, completedVideo.videoId);
      expect(updated.youtubeUrl, completedVideo.youtubeUrl);
      expect(updated.title, completedVideo.title);
      expect(updated.channelName, completedVideo.channelName);
      expect(updated.status, completedVideo.status);
    });
  });
}
