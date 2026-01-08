// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueueStatus _$QueueStatusFromJson(Map<String, dynamic> json) => QueueStatus(
  pending: (json['pending'] as num).toInt(),
  processing: (json['processing'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  maxWorkers: (json['max_workers'] as num).toInt(),
  activeWorkers: (json['active_workers'] as num).toInt(),
);

Map<String, dynamic> _$QueueStatusToJson(QueueStatus instance) =>
    <String, dynamic>{
      'pending': instance.pending,
      'processing': instance.processing,
      'total': instance.total,
      'max_workers': instance.maxWorkers,
      'active_workers': instance.activeWorkers,
    };
