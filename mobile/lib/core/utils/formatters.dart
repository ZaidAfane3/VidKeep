/// Utility formatters for display
class Formatters {
  /// Format duration in seconds to MM:SS or HH:MM:SS
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  /// Format file size in bytes to human readable
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '--';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
  
  /// Format date string to relative time
  static String formatRelativeDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 365) {
      return '${diff.inDays ~/ 365}y ago';
    } else if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
  
  /// Format view count to compact form
  static String formatViewCount(int? views) {
    if (views == null || views <= 0) return '';
    
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
}
