import 'package:json_annotation/json_annotation.dart';

part 'queue_status.g.dart';

/// Queue status model for download queue indicator
@JsonSerializable()
class QueueStatus {
  final int pending;
  final int processing;
  final int total;
  
  @JsonKey(name: 'max_workers')
  final int maxWorkers;
  
  @JsonKey(name: 'active_workers')
  final int activeWorkers;

  QueueStatus({
    required this.pending,
    required this.processing,
    required this.total,
    required this.maxWorkers,
    required this.activeWorkers,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) => _$QueueStatusFromJson(json);
  
  Map<String, dynamic> toJson() => _$QueueStatusToJson(this);
  
  /// Check if queue has any pending or processing items
  bool get hasItems => pending > 0 || processing > 0;
}
