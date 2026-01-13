import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Downloaded videos table - stores video file + metadata for offline playback
class DownloadedVideos extends Table {
  // === Video Identity ===
  TextColumn get videoId => text()();
  
  // === Video Metadata (for offline display) ===
  TextColumn get title => text()();
  TextColumn get channelName => text()();
  TextColumn get youtubeUrl => text()();
  TextColumn get description => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get uploadDate => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  
  // === Local Storage ===
  TextColumn get localPath => text()();
  IntColumn get fileSizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();
  
  // === Download Status (only used during download) ===
  TextColumn get status => text()(); // pending, downloading, paused, complete, failed
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get taskId => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {videoId};
}

/// Download settings table - user preferences
class DownloadSettings extends Table {
  IntColumn get id => integer()();
  BoolColumn get wifiOnly => boolean().withDefault(const Constant(true))();
  IntColumn get maxConcurrent => integer().withDefault(const Constant(2))();
  IntColumn get storageLimitMb => integer().nullable()();
  BoolColumn get pauseOnLowBattery => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Main application database for offline features
@DriftDatabase(tables: [DownloadedVideos, DownloadSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Fresh start - delete old tables and recreate
        // This is acceptable for a major schema change
        if (from < 3) {
          await m.deleteTable('downloaded_videos');
          await m.deleteTable('cached_videos');
          await m.createTable(downloadedVideos);
        }
      },
      beforeOpen: (details) async {
        // Ensure settings exist
        await ensureDefaultSettings();
      },
    );
  }
  
  Future<void> ensureDefaultSettings() async {
    final existing = await (select(downloadSettings)..where((s) => s.id.equals(1))).getSingleOrNull();
    if (existing == null) {
      await into(downloadSettings).insert(DownloadSettingsCompanion(
        id: const Value(1),
      ));
    }
  }
  
  // ============== Downloaded Videos Operations ==============
  
  /// Get all completed downloads (for offline display)
  Future<List<DownloadedVideo>> getCompletedDownloads() {
    return (select(downloadedVideos)..where((d) => d.status.equals('complete'))).get();
  }
  
  /// Watch all completed downloads
  Stream<List<DownloadedVideo>> watchCompletedDownloads() {
    return (select(downloadedVideos)..where((d) => d.status.equals('complete'))).watch();
  }
  
  /// Get a specific download
  Future<DownloadedVideo?> getDownload(String videoId) {
    return (select(downloadedVideos)..where((d) => d.videoId.equals(videoId))).getSingleOrNull();
  }
  
  /// Watch a specific download
  Stream<DownloadedVideo?> watchDownload(String videoId) {
    return (select(downloadedVideos)..where((d) => d.videoId.equals(videoId))).watchSingleOrNull();
  }
  
  /// Check if video is downloaded and complete
  Future<bool> isDownloaded(String videoId) async {
    final video = await getDownload(videoId);
    return video != null && video.status == 'complete';
  }
  
  /// Insert or update a download
  Future<void> upsertDownload(DownloadedVideosCompanion download) {
    return into(downloadedVideos).insertOnConflictUpdate(download);
  }
  
  /// Update download progress
  Future<void> updateProgress(String videoId, double progress) {
    return (update(downloadedVideos)..where((d) => d.videoId.equals(videoId)))
        .write(DownloadedVideosCompanion(progress: Value(progress)));
  }
  
  /// Update download status
  Future<void> updateStatus(String videoId, String status, {String? errorMessage}) {
    return (update(downloadedVideos)..where((d) => d.videoId.equals(videoId)))
        .write(DownloadedVideosCompanion(
          status: Value(status),
          errorMessage: Value(errorMessage),
        ));
  }
  
  /// Update local file path (fixes path mismatch from background_downloader)
  Future<void> updateLocalPath(String videoId, String localPath) {
    return (update(downloadedVideos)..where((d) => d.videoId.equals(videoId)))
        .write(DownloadedVideosCompanion(localPath: Value(localPath)));
  }
  
  /// Mark download as complete
  Future<void> completeDownload(String videoId, int fileSizeBytes) {
    return (update(downloadedVideos)..where((d) => d.videoId.equals(videoId)))
        .write(DownloadedVideosCompanion(
          status: const Value('complete'),
          progress: const Value(1.0),
          fileSizeBytes: Value(fileSizeBytes),
          downloadedAt: Value(DateTime.now()),
        ));
  }
  
  /// Delete a download record
  Future<int> deleteDownload(String videoId) {
    return (delete(downloadedVideos)..where((d) => d.videoId.equals(videoId))).go();
  }
  
  /// Delete all download records
  Future<int> deleteAllDownloads() {
    return delete(downloadedVideos).go();
  }
  
  /// Get total storage used
  Future<int> getTotalStorageUsed() async {
    final downloads = await getCompletedDownloads();
    return downloads.fold<int>(0, (sum, d) => sum + d.fileSizeBytes);
  }
  
  // ============== Settings Operations ==============
  
  Future<DownloadSetting> getSettings() async {
    await ensureDefaultSettings();
    return (select(downloadSettings)..where((s) => s.id.equals(1))).getSingle();
  }
  
  Stream<DownloadSetting> watchSettings() {
    return (select(downloadSettings)..where((s) => s.id.equals(1))).watchSingle();
  }
  
  Future<void> setWifiOnly(bool value) {
    return (update(downloadSettings)..where((s) => s.id.equals(1)))
        .write(DownloadSettingsCompanion(wifiOnly: Value(value)));
  }
  
  Future<void> setMaxConcurrent(int value) {
    return (update(downloadSettings)..where((s) => s.id.equals(1)))
        .write(DownloadSettingsCompanion(maxConcurrent: Value(value.clamp(1, 5))));
  }
  
  Future<void> setStorageLimit(int? limitMb) {
    return (update(downloadSettings)..where((s) => s.id.equals(1)))
        .write(DownloadSettingsCompanion(storageLimitMb: Value(limitMb)));
  }
  
  Future<void> setPauseOnLowBattery(bool value) {
    return (update(downloadSettings)..where((s) => s.id.equals(1)))
        .write(DownloadSettingsCompanion(pauseOnLowBattery: Value(value)));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vidkeep_downloads.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
