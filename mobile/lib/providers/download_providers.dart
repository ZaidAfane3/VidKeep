import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';
import '../data/models/downloaded_video.dart';
import '../data/models/download_settings.dart';
import '../data/models/video.dart';
import '../data/services/download_service.dart';
import '../data/services/battery_service.dart';

/// Database provider - singleton instance
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Download service provider
final downloadServiceProvider = Provider<DownloadService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = DownloadService(db);
  
  // Initialize on first access
  service.initialize();
  
  ref.onDispose(() => service.dispose());
  return service;
});

/// Battery service provider - monitors battery and pauses downloads on low battery
final batteryServiceProvider = Provider<BatteryService>((ref) {
  final downloadService = ref.watch(downloadServiceProvider);
  final batteryService = BatteryService(downloadService);
  
  // Watch settings to update pause on low battery preference
  ref.listen<AsyncValue<DownloadSettingsModel>>(downloadSettingsProvider, (prev, next) {
    next.whenData((settings) {
      batteryService.setPauseOnLowBattery(settings.pauseOnLowBattery);
    });
  });
  
  // Start monitoring with initial setting
  final settingsAsync = ref.read(downloadSettingsProvider);
  settingsAsync.whenData((settings) {
    batteryService.startMonitoring(pauseOnLowBattery: settings.pauseOnLowBattery);
  });
  
  ref.onDispose(() => batteryService.dispose());
  return batteryService;
});

/// Download settings provider (reactive)
final downloadSettingsProvider = StreamProvider<DownloadSettingsModel>((ref) {
  final db = ref.watch(appDatabaseProvider);
  
  return db.watchSettings().map((setting) {
    return DownloadSettingsModel(
      wifiOnly: setting.wifiOnly,
      maxConcurrent: setting.maxConcurrent,
      storageLimitMB: setting.storageLimitMb,
      pauseOnLowBattery: setting.pauseOnLowBattery,
    );
  });
});

/// All downloaded videos provider (for tracking downloads)
final downloadedVideosProvider = StreamProvider<List<DownloadedVideoModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  
  return db.watchCompletedDownloads().map((downloads) {
    return downloads.map((d) => DownloadedVideoModel(
      videoId: d.videoId,
      localFilePath: d.localPath,
      downloadedAt: d.downloadedAt,
      fileSizeBytes: d.fileSizeBytes,
      status: LocalDownloadStatusExtension.fromDbString(d.status),
      progress: d.progress,
      errorMessage: d.errorMessage,
      taskId: d.taskId,
    )).toList();
  });
});

/// Offline videos provider - converts downloaded videos to Video models for display
/// Used when server is unreachable and we need to show downloaded videos
final offlineVideosProvider = StreamProvider<List<Video>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  
  return db.watchCompletedDownloads().map((downloads) {
    return downloads.map((d) => Video(
      videoId: d.videoId,
      title: d.title,
      channelName: d.channelName,
      youtubeUrl: d.youtubeUrl,
      description: d.description,
      durationSeconds: d.durationSeconds,
      uploadDate: d.uploadDate,
      fileSizeBytes: d.fileSizeBytes,
      status: VideoStatus.complete,
      isFavorite: false, // Cannot know from local, will be false
      createdAt: d.downloadedAt,
    )).toList();
  });
});

/// Check if specific video is downloaded (complete)
final isVideoDownloadedProvider = FutureProvider.family<bool, String>((ref, videoId) async {
  final db = ref.watch(appDatabaseProvider);
  return db.isDownloaded(videoId);
});

/// Watch download status for specific video
final videoDownloadStatusProvider = StreamProvider.family<DownloadedVideoModel?, String>((ref, videoId) {
  final db = ref.watch(appDatabaseProvider);
  
  return db.watchDownload(videoId).map((d) {
    if (d == null) return null;
    return DownloadedVideoModel(
      videoId: d.videoId,
      localFilePath: d.localPath,
      downloadedAt: d.downloadedAt,
      fileSizeBytes: d.fileSizeBytes,
      status: LocalDownloadStatusExtension.fromDbString(d.status),
      progress: d.progress,
      errorMessage: d.errorMessage,
      taskId: d.taskId,
    );
  });
});

/// Download progress stream for specific video
final downloadProgressProvider = StreamProvider.family<double, String>((ref, videoId) {
  final service = ref.watch(downloadServiceProvider);
  
  return service.progressStream
      .where((event) => event.videoId == videoId)
      .map((event) => event.progress);
});

/// Total storage used by downloads (in bytes)
final downloadStorageUsedProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(downloadServiceProvider);
  return service.getStorageUsed();
});

/// Notifier for managing download settings
class DownloadSettingsNotifier extends AsyncNotifier<DownloadSettingsModel> {
  @override
  Future<DownloadSettingsModel> build() async {
    final service = ref.watch(downloadServiceProvider);
    return service.getSettings();
  }

  Future<void> setWifiOnly(bool value) async {
    final db = ref.read(appDatabaseProvider);
    await db.setWifiOnly(value);
    ref.invalidateSelf();
  }

  Future<void> setMaxConcurrent(int value) async {
    final db = ref.read(appDatabaseProvider);
    await db.setMaxConcurrent(value);
    ref.invalidateSelf();
  }

  Future<void> setStorageLimit(int? limitMb) async {
    final db = ref.read(appDatabaseProvider);
    await db.setStorageLimit(limitMb);
    ref.invalidateSelf();
  }

  Future<void> setPauseOnLowBattery(bool value) async {
    final db = ref.read(appDatabaseProvider);
    await db.setPauseOnLowBattery(value);
    ref.invalidateSelf();
  }
}

final downloadSettingsNotifierProvider = 
    AsyncNotifierProvider<DownloadSettingsNotifier, DownloadSettingsModel>(
        DownloadSettingsNotifier.new);

/// Provider for download actions
class DownloadActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Start downloading a video with metadata for offline display
  Future<bool> startDownload({
    required String videoId,
    required String downloadUrl,
    required String filename,
    // Required video metadata for offline display
    required String title,
    required String channelName,
    required String youtubeUrl,
    String? description,
    int? durationSeconds,
    String? uploadDate,
    int? fileSizeBytes,
    String? thumbnailUrl,
  }) async {
    final service = ref.read(downloadServiceProvider);
    return service.startDownload(
      videoId: videoId,
      downloadUrl: downloadUrl,
      filename: filename,
      title: title,
      channelName: channelName,
      youtubeUrl: youtubeUrl,
      description: description,
      durationSeconds: durationSeconds,
      uploadDate: uploadDate,
      fileSizeBytes: fileSizeBytes,
      thumbnailUrl: thumbnailUrl,
    );
  }

  /// Pause a download
  Future<void> pauseDownload(String videoId) async {
    final service = ref.read(downloadServiceProvider);
    await service.pauseDownload(videoId);
  }

  /// Resume a download
  Future<void> resumeDownload(String videoId) async {
    final service = ref.read(downloadServiceProvider);
    await service.resumeDownload(videoId);
  }

  /// Cancel a download
  Future<void> cancelDownload(String videoId) async {
    final service = ref.read(downloadServiceProvider);
    await service.cancelDownload(videoId);
  }

  /// Delete a downloaded video
  Future<void> deleteDownload(String videoId) async {
    final service = ref.read(downloadServiceProvider);
    await service.deleteDownload(videoId);
  }

  /// Get local file path for a video
  Future<String?> getLocalPath(String videoId) async {
    final service = ref.read(downloadServiceProvider);
    return service.getLocalPath(videoId);
  }
  
  /// Delete all downloaded videos and clear database
  Future<bool> deleteAllDownloads() async {
    final service = ref.read(downloadServiceProvider);
    return service.deleteAllDownloads();
  }
}

final downloadActionsProvider = 
    NotifierProvider<DownloadActionsNotifier, void>(DownloadActionsNotifier.new);
