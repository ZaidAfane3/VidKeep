/// Local download status enum for tracking download progress
enum LocalDownloadStatus {
  /// Queued for download
  pending,
  
  /// Currently downloading
  downloading,
  
  /// Paused (low battery, user action, or network)
  paused,
  
  /// Successfully downloaded
  complete,
  
  /// Download failed
  failed,
}

extension LocalDownloadStatusExtension on LocalDownloadStatus {
  /// Convert status to string for database storage
  String toDbString() => name;
  
  /// Create status from database string
  static LocalDownloadStatus fromDbString(String value) {
    return LocalDownloadStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocalDownloadStatus.pending,
    );
  }
  
  /// Check if status indicates active downloading
  bool get isActive => this == LocalDownloadStatus.downloading || this == LocalDownloadStatus.pending;
  
  /// Check if status is a terminal state (complete or failed)
  bool get isTerminal => this == LocalDownloadStatus.complete || this == LocalDownloadStatus.failed;
}

/// Represents a video downloaded for offline playback
class DownloadedVideoModel {
  final String videoId;
  final String localFilePath;
  final DateTime downloadedAt;
  final int fileSizeBytes;
  final LocalDownloadStatus status;
  final double progress;  // 0.0 - 1.0
  final String? errorMessage;
  final String? taskId;  // background_downloader task ID

  const DownloadedVideoModel({
    required this.videoId,
    required this.localFilePath,
    required this.downloadedAt,
    required this.fileSizeBytes,
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
    this.taskId,
  });

  /// Create a copy with updated fields
  DownloadedVideoModel copyWith({
    String? videoId,
    String? localFilePath,
    DateTime? downloadedAt,
    int? fileSizeBytes,
    LocalDownloadStatus? status,
    double? progress,
    String? errorMessage,
    String? taskId,
  }) {
    return DownloadedVideoModel(
      videoId: videoId ?? this.videoId,
      localFilePath: localFilePath ?? this.localFilePath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      taskId: taskId ?? this.taskId,
    );
  }

  /// Check if download is complete and playable
  bool get isPlayable => status == LocalDownloadStatus.complete;
  
  /// Format file size for display
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (fileSizeBytes < 1024 * 1024 * 1024) return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  /// Format progress for display (e.g., "75%")
  String get formattedProgress => '${(progress * 100).toInt()}%';
}
