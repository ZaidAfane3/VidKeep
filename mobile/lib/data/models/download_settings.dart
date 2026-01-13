/// Download settings model for user preferences
class DownloadSettingsModel {
  /// Only download on WiFi (default: true)
  final bool wifiOnly;
  
  /// Max concurrent downloads (default: 2, range 1-5)
  final int maxConcurrent;
  
  /// Storage limit in MB (null = unlimited)
  final int? storageLimitMB;
  
  /// Pause downloads on low battery (default: true)
  final bool pauseOnLowBattery;

  const DownloadSettingsModel({
    this.wifiOnly = true,
    this.maxConcurrent = 2,
    this.storageLimitMB,
    this.pauseOnLowBattery = true,
  });

  /// Create a copy with updated fields
  DownloadSettingsModel copyWith({
    bool? wifiOnly,
    int? maxConcurrent,
    int? storageLimitMB,
    bool? pauseOnLowBattery,
  }) {
    return DownloadSettingsModel(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      storageLimitMB: storageLimitMB ?? this.storageLimitMB,
      pauseOnLowBattery: pauseOnLowBattery ?? this.pauseOnLowBattery,
    );
  }

  /// Default settings
  static const DownloadSettingsModel defaults = DownloadSettingsModel();

  /// Check if storage limit is set
  bool get hasStorageLimit => storageLimitMB != null;

  /// Get storage limit in bytes
  int? get storageLimitBytes => storageLimitMB != null ? storageLimitMB! * 1024 * 1024 : null;

  /// Format storage limit for display
  String get formattedStorageLimit {
    if (storageLimitMB == null) return 'Unlimited';
    if (storageLimitMB! >= 1024) {
      return '${(storageLimitMB! / 1024).toStringAsFixed(1)} GB';
    }
    return '$storageLimitMB MB';
  }

  /// Predefined storage limit options in MB
  static const List<int?> storageLimitOptions = [
    null,  // Unlimited
    1024,  // 1 GB
    2048,  // 2 GB
    5120,  // 5 GB
    10240, // 10 GB
    20480, // 20 GB
  ];

  /// Get label for storage limit option
  static String getLimitLabel(int? limitMB) {
    if (limitMB == null) return 'Unlimited';
    if (limitMB >= 1024) {
      return '${(limitMB / 1024).toStringAsFixed(0)} GB';
    }
    return '$limitMB MB';
  }
}
