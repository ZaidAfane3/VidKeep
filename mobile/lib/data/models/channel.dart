import 'package:json_annotation/json_annotation.dart';

part 'channel.g.dart';

/// Channel model for channel filter dropdown
@JsonSerializable()
class Channel {
  @JsonKey(name: 'channel_name')
  final String channelName;
  
  @JsonKey(name: 'video_count')
  final int videoCount;

  Channel({
    required this.channelName,
    required this.videoCount,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ChannelToJson(this);
}
