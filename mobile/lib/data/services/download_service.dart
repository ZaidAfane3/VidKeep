import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/database.dart';
import '../models/downloaded_video.dart';
import '../models/download_settings.dart';

/// Service for managing video downloads for offline playback
class DownloadService {
  final AppDatabase _db;
  
  // Stream controllers for progress updates
  final _progressController = StreamController<DownloadProgressEvent>.broadcast();
  final _statusController = StreamController<DownloadStatusEvent>.broadcast();
  
  // Track active downloads
  final Map<String, DownloadTask> _activeTasks = {};
  
  // Subscriptions
  StreamSubscription<TaskUpdate>? _downloaderSubscription;
  
  DownloadService(this._db);

  /// Initialize the download service
  Future<void> initialize() async {
    // Configure the downloader
    await FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(seconds: 30)),
        (Config.checkAvailableSpace, Config.always),
        (Config.holdingQueue, (5, null, null)),
      ],
    );
    
    // Listen to download updates
    _downloaderSubscription = FileDownloader().updates.listen(_handleUpdate);
    
    // Ensure default settings exist
    await _db.ensureDefaultSettings();
    
    // Clean up stale records (files that no longer exist, e.g., after app reinstall)
    await _cleanupStaleRecords();
    
    // Resume any pending downloads
    await _resumePendingDownloads();
  }
  
  /// Remove download records where the file no longer exists
  Future<void> _cleanupStaleRecords() async {
    final downloads = await _db.getCompletedDownloads();
    for (final download in downloads) {
      final file = File(download.localPath);
      if (!await file.exists()) {
        debugPrint('[DownloadService] Removing stale record: ${download.videoId} (file not found)');
        await _db.deleteDownload(download.videoId);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _downloaderSubscription?.cancel();
    _progressController.close();
    _statusController.close();
  }

  /// Stream of progress updates
  Stream<DownloadProgressEvent> get progressStream => _progressController.stream;

  /// Stream of status updates
  Stream<DownloadStatusEvent> get statusStream => _statusController.stream;

  /// Get the download directory for videos
  /// Android: Public Download directory (visible to user)
  /// iOS: Application Documents directory
  Future<Directory> getDownloadDirectory() async {
    Directory downloadDir;
    if (Platform.isAndroid) {
      // Use standard public Download directory
      // /storage/emulated/0/Download/VidKeep
      downloadDir = Directory('/storage/emulated/0/Download/VidKeep');
    } else {
       final baseDir = await getApplicationDocumentsDirectory();
       downloadDir = Directory(p.join(baseDir.path, 'VidKeep'));
    }
    
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// Start downloading a video
  Future<bool> startDownload({
    required String videoId,
    required String downloadUrl,
    required String filename,
    // Video metadata for offline display
    required String title,
    required String channelName,
    required String youtubeUrl,
    String? description,
    int? durationSeconds,
    String? uploadDate,
    int? fileSizeBytes,
    String? thumbnailUrl,
  }) async {
    // Check if already downloading or downloaded
    final existing = await _db.getDownload(videoId);
    if (existing != null && 
        (existing.status == 'complete' || existing.status == 'downloading')) {
      return false;
    }

    // Check WiFi-only setting
    final settings = await _db.getSettings();
    if (settings.wifiOnly) {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasWifi = connectivityResult == ConnectivityResult.wifi;
      if (!hasWifi) {
        _statusController.add(DownloadStatusEvent(
          videoId: videoId,
          status: LocalDownloadStatus.failed,
          error: 'WiFi-only mode is enabled. Connect to WiFi to download.',
        ));
        return false;
      }
    }

    // Check storage limit
    if (settings.storageLimitMb != null) {
      final usedBytes = await _db.getTotalStorageUsed();
      final limitBytes = settings.storageLimitMb! * 1024 * 1024;
      if (usedBytes >= limitBytes) {
        _statusController.add(DownloadStatusEvent(
          videoId: videoId,
          status: LocalDownloadStatus.failed,
          error: 'Storage limit reached. Delete some videos or increase limit.',
        ));
        return false;
      }
    }

    final downloadDir = await getDownloadDirectory();
    final filePath = p.join(downloadDir.path, filename);
    
    debugPrint('[DownloadService] Starting download:');
    debugPrint('[DownloadService] URL: $downloadUrl');
    debugPrint('[DownloadService] Target directory: ${downloadDir.path}');
    debugPrint('[DownloadService] Filename: $filename');
    debugPrint('[DownloadService] Full path: $filePath');

    // Configure task based on platform
    final DownloadTask task;
    if (Platform.isAndroid) {
      // Android: Public storage requires BaseDirectory.root and absolute path
      task = DownloadTask(
        url: downloadUrl,
        filename: filename,
        directory: downloadDir.path, // Absolute path
        baseDirectory: BaseDirectory.root,
        updates: Updates.statusAndProgress,
        requiresWiFi: settings.wifiOnly,
        retries: 3,
        metaData: videoId,
      );
    } else {
      // iOS: ApplicationDocuments requires relative path
      task = DownloadTask(
        url: downloadUrl,
        filename: filename,
        directory: 'VidKeep', // Relative to Documents
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        requiresWiFi: settings.wifiOnly,
        retries: 3,
        metaData: videoId,
      );
    }

    // Save to database with all metadata in one table
    await _db.upsertDownload(DownloadedVideosCompanion(
      videoId: Value(videoId),
      title: Value(title),
      channelName: Value(channelName),
      youtubeUrl: Value(youtubeUrl),
      description: Value(description),
      durationSeconds: Value(durationSeconds),
      uploadDate: Value(uploadDate),
      thumbnailUrl: Value(thumbnailUrl),
      localPath: Value(filePath),
      fileSizeBytes: Value(fileSizeBytes ?? 0),
      downloadedAt: Value(DateTime.now()),
      status: const Value('pending'),
      progress: const Value(0.0),
      taskId: Value(task.taskId),
    ));

    // Store active task
    _activeTasks[videoId] = task;

    // Enqueue the download
    final enqueued = await FileDownloader().enqueue(task);
    
    if (enqueued) {
      await _db.updateStatus(videoId, 'downloading');
      _statusController.add(DownloadStatusEvent(
        videoId: videoId,
        status: LocalDownloadStatus.downloading,
      ));
    } else {
      await _db.updateStatus(videoId, 'failed', errorMessage: 'Failed to start download');
      _statusController.add(DownloadStatusEvent(
        videoId: videoId,
        status: LocalDownloadStatus.failed,
        error: 'Failed to start download',
      ));
    }

    return enqueued;
  }

  /// Pause a download
  Future<void> pauseDownload(String videoId) async {
    final task = _activeTasks[videoId];
    if (task != null) {
      await FileDownloader().pause(task);
      await _db.updateStatus(videoId, 'paused');
      _statusController.add(DownloadStatusEvent(
        videoId: videoId,
        status: LocalDownloadStatus.paused,
      ));
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String videoId) async {
    var task = _activeTasks[videoId];
    
    // If not in memory, try to find from FileDownloader's database
    if (task == null) {
      final records = await FileDownloader().database.allRecords();
      final existingRecord = records
          .where((r) => r.task.metaData == videoId && r.task is DownloadTask)
          .firstOrNull;
      
      if (existingRecord != null) {
        task = existingRecord.task as DownloadTask;
        _activeTasks[videoId] = task;
        debugPrint('[DownloadService] Recovered task for $videoId from FileDownloader database');
      }
    }
    
    if (task != null) {
      final success = await FileDownloader().resume(task);
      debugPrint('[DownloadService] Resume result for $videoId: $success');
      if (success) {
        await _db.updateStatus(videoId, 'downloading');
        _statusController.add(DownloadStatusEvent(
          videoId: videoId,
          status: LocalDownloadStatus.downloading,
        ));
      } else {
        // Resume failed - task may have been lost, need to re-download
        debugPrint('[DownloadService] Resume failed for $videoId, task may be lost');
        await _db.updateStatus(videoId, 'failed', 
          errorMessage: 'Resume failed. Please delete and re-download.');
        _statusController.add(DownloadStatusEvent(
          videoId: videoId,
          status: LocalDownloadStatus.failed,
          error: 'Resume failed. Please delete and re-download.',
        ));
      }
    } else {
      // No task found at all - mark as failed
      debugPrint('[DownloadService] No task found for $videoId to resume');
      await _db.updateStatus(videoId, 'failed', 
        errorMessage: 'Download task lost. Please delete and re-download.');
      _statusController.add(DownloadStatusEvent(
        videoId: videoId,
        status: LocalDownloadStatus.failed,
        error: 'Download task lost. Please delete and re-download.',
      ));
    }
  }

  /// Cancel a download
  Future<void> cancelDownload(String videoId) async {
    final task = _activeTasks[videoId];
    if (task != null) {
      await FileDownloader().cancelTaskWithId(task.taskId);
      _activeTasks.remove(videoId);
    }
    
    // Delete partial file
    final download = await _db.getDownload(videoId);
    if (download != null) {
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    await _db.deleteDownload(videoId);
    _statusController.add(DownloadStatusEvent(
      videoId: videoId,
      status: LocalDownloadStatus.failed,
      error: 'Download cancelled',
    ));
  }

  /// Delete a downloaded video
  Future<void> deleteDownload(String videoId) async {
    final download = await _db.getDownload(videoId);
    if (download != null) {
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    _activeTasks.remove(videoId);
    await _db.deleteDownload(videoId);
  }

  /// Check if a video is downloaded
  Future<bool> isDownloaded(String videoId) async {
    return _db.isDownloaded(videoId);
  }

  /// Get the local file path if downloaded
  Future<String?> getLocalPath(String videoId) async {
    debugPrint('[DownloadService] getLocalPath for: $videoId');
    final download = await _db.getDownload(videoId);
    debugPrint('[DownloadService] download record: ${download?.videoId}, status: ${download?.status}');
    if (download != null && download.status == 'complete') {
      debugPrint('[DownloadService] localPath: ${download.localPath}');
      final file = File(download.localPath);
      final exists = await file.exists();
      debugPrint('[DownloadService] file exists: $exists');
      if (exists) {
        return download.localPath;
      }
    }
    return null;
  }

  /// Get download status for a video
  Future<LocalDownloadStatus?> getDownloadStatus(String videoId) async {
    final download = await _db.getDownload(videoId);
    if (download == null) return null;
    return LocalDownloadStatusExtension.fromDbString(download.status);
  }

  /// Get current settings
  Future<DownloadSettingsModel> getSettings() async {
    final settings = await _db.getSettings();
    return DownloadSettingsModel(
      wifiOnly: settings.wifiOnly,
      maxConcurrent: settings.maxConcurrent,
      storageLimitMB: settings.storageLimitMb,
      pauseOnLowBattery: settings.pauseOnLowBattery,
    );
  }

  /// Update settings
  Future<void> updateSettings(DownloadSettingsModel settings) async {
    await _db.setWifiOnly(settings.wifiOnly);
    await _db.setMaxConcurrent(settings.maxConcurrent);
    await _db.setStorageLimit(settings.storageLimitMB);
    await _db.setPauseOnLowBattery(settings.pauseOnLowBattery);
  }

  /// Get total storage used
  Future<int> getStorageUsed() async {
    return _db.getTotalStorageUsed();
  }

  /// Delete all downloaded videos and clear database
  /// This is atomic - either all files are deleted and DB is cleared, or none
  Future<bool> deleteAllDownloads() async {
    try {
      // Get all downloads from database
      final downloads = await _db.getCompletedDownloads();
      
      if (downloads.isEmpty) {
        return true; // Nothing to delete
      }
      
      // Collect files to delete
      final filesToDelete = <File>[];
      for (final download in downloads) {
        final file = File(download.localPath);
        if (await file.exists()) {
          filesToDelete.add(file);
        }
      }
      
      // Delete all files first
      for (final file in filesToDelete) {
        try {
          await file.delete();
          debugPrint('[DownloadService] Deleted: ${file.path}');
        } catch (e) {
          debugPrint('[DownloadService] Failed to delete ${file.path}: $e');
          // Continue deleting other files even if one fails
        }
      }
      
      // Clear all records from database
      await _db.deleteAllDownloads();
      
      // Try to clean up the VidKeep directory if empty
      final downloadDir = await getDownloadDirectory();
      if (await downloadDir.exists()) {
        final remaining = await downloadDir.list().length;
        if (remaining == 0) {
          await downloadDir.delete();
          debugPrint('[DownloadService] Removed empty VidKeep directory');
        }
      }
      
      debugPrint('[DownloadService] All downloads cleared');
      return true;
    } catch (e) {
      debugPrint('[DownloadService] Error clearing all downloads: $e');
      return false;
    }
  }

  /// Handle download updates from background_downloader
  void _handleUpdate(TaskUpdate update) async {
    final videoId = update.task.metaData;
    if (videoId.isEmpty) return;

    if (update is TaskStatusUpdate) {
      switch (update.status) {
        case TaskStatus.running:
          await _db.updateStatus(videoId, 'downloading');
          _statusController.add(DownloadStatusEvent(
            videoId: videoId,
            status: LocalDownloadStatus.downloading,
          ));
          break;
          
        case TaskStatus.complete:
          // Construct the absolute path correctly
          // task.directory is relative (e.g. 'VidKeep'), but we want the full system path
          // We rely on getDownloadDirectory() which returns the absolute path to '.../VidKeep'
          final downloadDir = await getDownloadDirectory();
          var actualPath = p.join(downloadDir.path, update.task.filename);
          
          var file = File(actualPath);
          
          debugPrint('[DownloadService] Download complete for: $videoId');
          debugPrint('[DownloadService] Absolute path: $actualPath');
          
          var exists = await file.exists();
          debugPrint('[DownloadService] File exists at path: $exists');
          
          // If file not found there, try the original stored path from DB (fallback)
          if (!exists) {
             final stored = await _db.getDownload(videoId);
             if (stored != null) {
               debugPrint('[DownloadService] Trying stored path: ${stored.localPath}');
               final storedFile = File(stored.localPath);
               if (await storedFile.exists()) {
                 actualPath = stored.localPath;
                 file = storedFile;
                 exists = true;
               }
             }
          }
          
          final fileSize = exists ? await file.length() : 0;
          debugPrint('[DownloadService] File size: $fileSize bytes');
          
          // Update the localPath in database with the correct path
          await _db.updateLocalPath(videoId, actualPath);
          await _db.completeDownload(videoId, fileSize);
          _activeTasks.remove(videoId);
          _statusController.add(DownloadStatusEvent(
            videoId: videoId,
            status: LocalDownloadStatus.complete,
          ));
          break;
          
        case TaskStatus.failed:
          debugPrint('[DownloadService] Download FAILED for: $videoId');
          debugPrint('[DownloadService] Error: ${update.exception?.description}');
          debugPrint('[DownloadService] Exception type: ${update.exception?.runtimeType}');
          await _db.updateStatus(videoId, 'failed', 
            errorMessage: update.exception?.description ?? 'Download failed');
          _activeTasks.remove(videoId);
          _statusController.add(DownloadStatusEvent(
            videoId: videoId,
            status: LocalDownloadStatus.failed,
            error: update.exception?.description ?? 'Download failed',
          ));
          break;
          
        case TaskStatus.paused:
          await _db.updateStatus(videoId, 'paused');
          _statusController.add(DownloadStatusEvent(
            videoId: videoId,
            status: LocalDownloadStatus.paused,
          ));
          break;
          
        case TaskStatus.canceled:
          await _db.deleteDownload(videoId);
          _activeTasks.remove(videoId);
          break;
          
        default:
          break;
      }
    } else if (update is TaskProgressUpdate) {
      // Log progress at key milestones
      final percent = (update.progress * 100).toInt();
      if (percent % 25 == 0 || percent == 1) {
        debugPrint('[DownloadService] Progress for $videoId: $percent%');
      }
      await _db.updateProgress(videoId, update.progress);
      _progressController.add(DownloadProgressEvent(
        videoId: videoId,
        progress: update.progress,
        networkSpeed: update.networkSpeed,
        timeRemaining: update.timeRemaining,
      ));
    }
  }

  /// Resume any pending/paused downloads on app start
  Future<void> _resumePendingDownloads() async {
    final downloads = await _db.select(_db.downloadedVideos).get();
    
    for (final download in downloads) {
      if (download.status == 'downloading' || download.status == 'pending') {
        // Check if task is still in the queue
        final records = await FileDownloader().database.allRecords();
        final existingRecord = records
            .where((r) => r.task.metaData == download.videoId)
            .firstOrNull;
        
        if (existingRecord != null) {
          // Task exists, update our tracking
          _activeTasks[download.videoId] = existingRecord.task as DownloadTask;
        } else {
          // Task was lost, mark as paused so user can retry
          await _db.updateStatus(download.videoId, 'paused', 
            errorMessage: 'Download interrupted. Tap to retry.');
        }
      }
    }
  }

  /// Pause all downloads (for low battery mode)
  Future<void> pauseAllDownloads() async {
    for (final entry in _activeTasks.entries) {
      await pauseDownload(entry.key);
    }
  }

  /// Resume all paused downloads
  Future<void> resumeAllDownloads() async {
    final downloads = await _db.select(_db.downloadedVideos).get();
    for (final download in downloads) {
      if (download.status == 'paused' && download.taskId != null) {
        await resumeDownload(download.videoId);
      }
    }
  }
}

/// Event for download progress updates
class DownloadProgressEvent {
  final String videoId;
  final double progress; // 0.0 - 1.0
  final double networkSpeed; // bytes per second
  final Duration timeRemaining;

  DownloadProgressEvent({
    required this.videoId,
    required this.progress,
    this.networkSpeed = 0,
    this.timeRemaining = Duration.zero,
  });
}

/// Event for download status changes
class DownloadStatusEvent {
  final String videoId;
  final LocalDownloadStatus status;
  final String? error;

  DownloadStatusEvent({
    required this.videoId,
    required this.status,
    this.error,
  });
}
