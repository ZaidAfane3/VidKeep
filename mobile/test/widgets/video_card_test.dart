import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidkeep_mobile/data/models/video.dart';
import 'package:vidkeep_mobile/widgets/video_card.dart';
import 'package:vidkeep_mobile/providers/video_providers.dart';

void main() {
  late Video completedVideo;
  late Video favoriteVideo;
  late Video downloadingVideo;
  late Video failedVideo;
  late Video queuedVideo;

  setUp(() {
    completedVideo = Video(
      videoId: 'test-1',
      youtubeUrl: 'https://youtube.com/watch?v=test',
      title: 'Test Video Title',
      channelName: 'Test Channel',
      status: VideoStatus.complete,
      isFavorite: false,
      retryCount: 0,
      createdAt: DateTime.now(),
      durationSeconds: 120,
      fileSizeBytes: 10 * 1024 * 1024,
    );

    favoriteVideo = completedVideo.copyWith(isFavorite: true);
    
    downloadingVideo = Video(
      videoId: 'test-2',
      youtubeUrl: 'https://youtube.com/watch?v=test2',
      title: 'Downloading Video',
      channelName: 'Test Channel',
      status: VideoStatus.downloading,
      downloadProgress: 50,
      isFavorite: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );

    failedVideo = Video(
      videoId: 'test-3',
      youtubeUrl: 'https://youtube.com/watch?v=test3',
      title: 'Failed Video',
      channelName: 'Test Channel',
      status: VideoStatus.failed,
      errorMessage: 'Download failed',
      isFavorite: false,
      retryCount: 2,
      createdAt: DateTime.now(),
    );

    queuedVideo = Video(
      videoId: 'test-4',
      youtubeUrl: 'https://youtube.com/watch?v=test4',
      title: 'Queued Video',
      channelName: 'Test Channel',
      status: VideoStatus.queued,
      isFavorite: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
  });

  Widget buildTestWidget(Video video, {VoidCallback? onTap, VoidCallback? onFavorite}) {
    return ProviderScope(
      overrides: [
        videosProvider.overrideWith((ref) => VideosNotifier(ref)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: VideoCard(
            video: video,
            onTap: onTap,
            onFavorite: onFavorite,
          ),
        ),
      ),
    );
  }

  group('VideoCard - Basic Display', () {
    testWidgets('displays video title', (tester) async {
      await tester.pumpWidget(buildTestWidget(completedVideo));
      await tester.pumpAndSettle();

      expect(find.text('Test Video Title'), findsOneWidget);
    });

    testWidgets('displays channel name in uppercase', (tester) async {
      await tester.pumpWidget(buildTestWidget(completedVideo));
      await tester.pumpAndSettle();

      expect(find.text('TEST CHANNEL'), findsOneWidget);
    });

    testWidgets('displays duration badge for playable video', (tester) async {
      await tester.pumpWidget(buildTestWidget(completedVideo));
      await tester.pumpAndSettle();

      expect(find.text('02:00'), findsOneWidget);
    });
  });

  group('VideoCard - User Interaction', () {
    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestWidget(
        completedVideo,
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(VideoCard));
      expect(tapped, true);
    });

    testWidgets('shows context menu on long press', (tester) async {
      await tester.pumpWidget(buildTestWidget(completedVideo));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(VideoCard));
      await tester.pumpAndSettle();

      expect(find.text('ADD TO FAVORITES'), findsOneWidget);
    });

    testWidgets('shows different text for favorited video', (tester) async {
      await tester.pumpWidget(buildTestWidget(favoriteVideo));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(VideoCard));
      await tester.pumpAndSettle();

      expect(find.text('REMOVE FAVORITE'), findsOneWidget);
    });
  });

  group('VideoCard - Context Menu Options', () {
    testWidgets('shows DELETE option for completed videos', (tester) async {
      await tester.pumpWidget(buildTestWidget(completedVideo));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(VideoCard));
      await tester.pumpAndSettle();

      expect(find.text('DELETE VIDEO'), findsOneWidget);
    });

    testWidgets('shows CANCEL option for downloading videos', (tester) async {
      await tester.pumpWidget(buildTestWidget(downloadingVideo));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(VideoCard));
      await tester.pumpAndSettle();

      expect(find.text('CANCEL DOWNLOAD'), findsOneWidget);
    });

    testWidgets('shows CANCEL option for queued videos', (tester) async {
      await tester.pumpWidget(buildTestWidget(queuedVideo));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(VideoCard));
      await tester.pumpAndSettle();

      expect(find.text('CANCEL DOWNLOAD'), findsOneWidget);
    });

    testWidgets('shows DELETE option for failed videos', (tester) async {
      await tester.pumpWidget(buildTestWidget(failedVideo));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(VideoCard));
      await tester.pumpAndSettle();

      expect(find.text('DELETE VIDEO'), findsOneWidget);
    });

    testWidgets('shows VIEW DETAILS option for all videos', (tester) async {
      await tester.pumpWidget(buildTestWidget(downloadingVideo));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(VideoCard));
      await tester.pumpAndSettle();

      expect(find.text('VIEW DETAILS'), findsOneWidget);
    });
  });
}
