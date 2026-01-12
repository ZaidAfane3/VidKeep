import 'package:flutter_test/flutter_test.dart';
import 'package:vidkeep_mobile/core/utils/formatters.dart';

void main() {
  group('Formatters.formatDuration', () {
    test('returns "--:--" for null duration', () {
      expect(Formatters.formatDuration(null), '--:--');
    });

    test('returns "--:--" for zero duration', () {
      expect(Formatters.formatDuration(0), '--:--');
    });

    test('formats seconds correctly', () {
      expect(Formatters.formatDuration(45), '00:45');
    });

    test('formats minutes correctly', () {
      expect(Formatters.formatDuration(90), '01:30');
      expect(Formatters.formatDuration(600), '10:00');
    });

    test('formats hours correctly', () {
      expect(Formatters.formatDuration(3600), '01:00:00');
      expect(Formatters.formatDuration(3661), '01:01:01');
      expect(Formatters.formatDuration(7200), '02:00:00');
    });

    test('pads seconds with leading zero', () {
      expect(Formatters.formatDuration(65), '01:05');
      expect(Formatters.formatDuration(3605), '01:00:05');
    });
  });

  group('Formatters.formatFileSize', () {
    test('returns "--" for null size', () {
      expect(Formatters.formatFileSize(null), '--');
    });

    test('returns "--" for zero size', () {
      expect(Formatters.formatFileSize(0), '--');
    });

    test('formats bytes correctly', () {
      expect(Formatters.formatFileSize(500), '500 B');
    });

    test('formats kilobytes correctly', () {
      expect(Formatters.formatFileSize(1024), '1.0 KB');
      expect(Formatters.formatFileSize(1536), '1.5 KB');
    });

    test('formats megabytes correctly', () {
      expect(Formatters.formatFileSize(1024 * 1024), '1.0 MB');
      expect(Formatters.formatFileSize(25 * 1024 * 1024), '25.0 MB');
    });

    test('formats gigabytes correctly', () {
      expect(Formatters.formatFileSize(1024 * 1024 * 1024), '1.0 GB');
      expect(Formatters.formatFileSize(2 * 1024 * 1024 * 1024), '2.0 GB');
    });
  });

  group('Formatters.formatRelativeDate', () {
    test('returns "Just now" for recent dates', () {
      final now = DateTime.now();
      expect(Formatters.formatRelativeDate(now), 'Just now');
    });

    test('returns minutes ago', () {
      final minutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(Formatters.formatRelativeDate(minutesAgo), '5m ago');
    });

    test('returns hours ago', () {
      final hoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      expect(Formatters.formatRelativeDate(hoursAgo), '3h ago');
    });

    test('returns days ago', () {
      final daysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(Formatters.formatRelativeDate(daysAgo), '2d ago');
    });

    test('returns months ago', () {
      final monthsAgo = DateTime.now().subtract(const Duration(days: 60));
      expect(Formatters.formatRelativeDate(monthsAgo), '2mo ago');
    });
  });

  group('Formatters.formatViewCount', () {
    test('returns empty string for null views', () {
      expect(Formatters.formatViewCount(null), '');
    });

    test('returns empty string for zero views', () {
      expect(Formatters.formatViewCount(0), '');
    });

    test('formats small numbers as-is', () {
      expect(Formatters.formatViewCount(500), '500');
      expect(Formatters.formatViewCount(999), '999');
    });

    test('formats thousands with K suffix', () {
      expect(Formatters.formatViewCount(1000), '1.0K');
      expect(Formatters.formatViewCount(5500), '5.5K');
      expect(Formatters.formatViewCount(999999), '1000.0K');
    });

    test('formats millions with M suffix', () {
      expect(Formatters.formatViewCount(1000000), '1.0M');
      expect(Formatters.formatViewCount(2500000), '2.5M');
    });
  });
}
