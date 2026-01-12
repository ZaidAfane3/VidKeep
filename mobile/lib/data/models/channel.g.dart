// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Channel _$ChannelFromJson(Map<String, dynamic> json) => Channel(
  channelName: json['channel_name'] as String,
  videoCount: (json['video_count'] as num).toInt(),
);

Map<String, dynamic> _$ChannelToJson(Channel instance) => <String, dynamic>{
  'channel_name': instance.channelName,
  'video_count': instance.videoCount,
};
