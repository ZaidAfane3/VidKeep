// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DownloadedVideosTable extends DownloadedVideos
    with TableInfo<$DownloadedVideosTable, DownloadedVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelNameMeta = const VerificationMeta(
    'channelName',
  );
  @override
  late final GeneratedColumn<String> channelName = GeneratedColumn<String>(
    'channel_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _youtubeUrlMeta = const VerificationMeta(
    'youtubeUrl',
  );
  @override
  late final GeneratedColumn<String> youtubeUrl = GeneratedColumn<String>(
    'youtube_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadDateMeta = const VerificationMeta(
    'uploadDate',
  );
  @override
  late final GeneratedColumn<String> uploadDate = GeneratedColumn<String>(
    'upload_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    title,
    channelName,
    youtubeUrl,
    description,
    durationSeconds,
    uploadDate,
    thumbnailUrl,
    localPath,
    fileSizeBytes,
    downloadedAt,
    status,
    progress,
    errorMessage,
    taskId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedVideo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('channel_name')) {
      context.handle(
        _channelNameMeta,
        channelName.isAcceptableOrUnknown(
          data['channel_name']!,
          _channelNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelNameMeta);
    }
    if (data.containsKey('youtube_url')) {
      context.handle(
        _youtubeUrlMeta,
        youtubeUrl.isAcceptableOrUnknown(data['youtube_url']!, _youtubeUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_youtubeUrlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('upload_date')) {
      context.handle(
        _uploadDateMeta,
        uploadDate.isAcceptableOrUnknown(data['upload_date']!, _uploadDateMeta),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  DownloadedVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedVideo(
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      channelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_name'],
      )!,
      youtubeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube_url'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      uploadDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_date'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
    );
  }

  @override
  $DownloadedVideosTable createAlias(String alias) {
    return $DownloadedVideosTable(attachedDatabase, alias);
  }
}

class DownloadedVideo extends DataClass implements Insertable<DownloadedVideo> {
  final String videoId;
  final String title;
  final String channelName;
  final String youtubeUrl;
  final String? description;
  final int? durationSeconds;
  final String? uploadDate;
  final String? thumbnailUrl;
  final String localPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String status;
  final double progress;
  final String? errorMessage;
  final String? taskId;
  const DownloadedVideo({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.youtubeUrl,
    this.description,
    this.durationSeconds,
    this.uploadDate,
    this.thumbnailUrl,
    required this.localPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.status,
    required this.progress,
    this.errorMessage,
    this.taskId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    map['channel_name'] = Variable<String>(channelName);
    map['youtube_url'] = Variable<String>(youtubeUrl);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || uploadDate != null) {
      map['upload_date'] = Variable<String>(uploadDate);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['local_path'] = Variable<String>(localPath);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    return map;
  }

  DownloadedVideosCompanion toCompanion(bool nullToAbsent) {
    return DownloadedVideosCompanion(
      videoId: Value(videoId),
      title: Value(title),
      channelName: Value(channelName),
      youtubeUrl: Value(youtubeUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      uploadDate: uploadDate == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadDate),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      localPath: Value(localPath),
      fileSizeBytes: Value(fileSizeBytes),
      downloadedAt: Value(downloadedAt),
      status: Value(status),
      progress: Value(progress),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
    );
  }

  factory DownloadedVideo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedVideo(
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      channelName: serializer.fromJson<String>(json['channelName']),
      youtubeUrl: serializer.fromJson<String>(json['youtubeUrl']),
      description: serializer.fromJson<String?>(json['description']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      uploadDate: serializer.fromJson<String?>(json['uploadDate']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      taskId: serializer.fromJson<String?>(json['taskId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'channelName': serializer.toJson<String>(channelName),
      'youtubeUrl': serializer.toJson<String>(youtubeUrl),
      'description': serializer.toJson<String?>(description),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'uploadDate': serializer.toJson<String?>(uploadDate),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'localPath': serializer.toJson<String>(localPath),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'taskId': serializer.toJson<String?>(taskId),
    };
  }

  DownloadedVideo copyWith({
    String? videoId,
    String? title,
    String? channelName,
    String? youtubeUrl,
    Value<String?> description = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<String?> uploadDate = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    String? localPath,
    int? fileSizeBytes,
    DateTime? downloadedAt,
    String? status,
    double? progress,
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
  }) => DownloadedVideo(
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    channelName: channelName ?? this.channelName,
    youtubeUrl: youtubeUrl ?? this.youtubeUrl,
    description: description.present ? description.value : this.description,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    uploadDate: uploadDate.present ? uploadDate.value : this.uploadDate,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    localPath: localPath ?? this.localPath,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    taskId: taskId.present ? taskId.value : this.taskId,
  );
  DownloadedVideo copyWithCompanion(DownloadedVideosCompanion data) {
    return DownloadedVideo(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      channelName: data.channelName.present
          ? data.channelName.value
          : this.channelName,
      youtubeUrl: data.youtubeUrl.present
          ? data.youtubeUrl.value
          : this.youtubeUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      uploadDate: data.uploadDate.present
          ? data.uploadDate.value
          : this.uploadDate,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedVideo(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('channelName: $channelName, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('description: $description, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('uploadDate: $uploadDate, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('taskId: $taskId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    videoId,
    title,
    channelName,
    youtubeUrl,
    description,
    durationSeconds,
    uploadDate,
    thumbnailUrl,
    localPath,
    fileSizeBytes,
    downloadedAt,
    status,
    progress,
    errorMessage,
    taskId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedVideo &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.channelName == this.channelName &&
          other.youtubeUrl == this.youtubeUrl &&
          other.description == this.description &&
          other.durationSeconds == this.durationSeconds &&
          other.uploadDate == this.uploadDate &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.localPath == this.localPath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.errorMessage == this.errorMessage &&
          other.taskId == this.taskId);
}

class DownloadedVideosCompanion extends UpdateCompanion<DownloadedVideo> {
  final Value<String> videoId;
  final Value<String> title;
  final Value<String> channelName;
  final Value<String> youtubeUrl;
  final Value<String?> description;
  final Value<int?> durationSeconds;
  final Value<String?> uploadDate;
  final Value<String?> thumbnailUrl;
  final Value<String> localPath;
  final Value<int> fileSizeBytes;
  final Value<DateTime> downloadedAt;
  final Value<String> status;
  final Value<double> progress;
  final Value<String?> errorMessage;
  final Value<String?> taskId;
  final Value<int> rowid;
  const DownloadedVideosCompanion({
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.channelName = const Value.absent(),
    this.youtubeUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.uploadDate = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.taskId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedVideosCompanion.insert({
    required String videoId,
    required String title,
    required String channelName,
    required String youtubeUrl,
    this.description = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.uploadDate = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    required String localPath,
    required int fileSizeBytes,
    required DateTime downloadedAt,
    required String status,
    this.progress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.taskId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       title = Value(title),
       channelName = Value(channelName),
       youtubeUrl = Value(youtubeUrl),
       localPath = Value(localPath),
       fileSizeBytes = Value(fileSizeBytes),
       downloadedAt = Value(downloadedAt),
       status = Value(status);
  static Insertable<DownloadedVideo> custom({
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? channelName,
    Expression<String>? youtubeUrl,
    Expression<String>? description,
    Expression<int>? durationSeconds,
    Expression<String>? uploadDate,
    Expression<String>? thumbnailUrl,
    Expression<String>? localPath,
    Expression<int>? fileSizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<String>? errorMessage,
    Expression<String>? taskId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (channelName != null) 'channel_name': channelName,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (description != null) 'description': description,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (uploadDate != null) 'upload_date': uploadDate,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (localPath != null) 'local_path': localPath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (errorMessage != null) 'error_message': errorMessage,
      if (taskId != null) 'task_id': taskId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedVideosCompanion copyWith({
    Value<String>? videoId,
    Value<String>? title,
    Value<String>? channelName,
    Value<String>? youtubeUrl,
    Value<String?>? description,
    Value<int?>? durationSeconds,
    Value<String?>? uploadDate,
    Value<String?>? thumbnailUrl,
    Value<String>? localPath,
    Value<int>? fileSizeBytes,
    Value<DateTime>? downloadedAt,
    Value<String>? status,
    Value<double>? progress,
    Value<String?>? errorMessage,
    Value<String?>? taskId,
    Value<int>? rowid,
  }) {
    return DownloadedVideosCompanion(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      uploadDate: uploadDate ?? this.uploadDate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      taskId: taskId ?? this.taskId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (channelName.present) {
      map['channel_name'] = Variable<String>(channelName.value);
    }
    if (youtubeUrl.present) {
      map['youtube_url'] = Variable<String>(youtubeUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (uploadDate.present) {
      map['upload_date'] = Variable<String>(uploadDate.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedVideosCompanion(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('channelName: $channelName, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('description: $description, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('uploadDate: $uploadDate, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('taskId: $taskId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadSettingsTable extends DownloadSettings
    with TableInfo<$DownloadSettingsTable, DownloadSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wifiOnlyMeta = const VerificationMeta(
    'wifiOnly',
  );
  @override
  late final GeneratedColumn<bool> wifiOnly = GeneratedColumn<bool>(
    'wifi_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wifi_only" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _maxConcurrentMeta = const VerificationMeta(
    'maxConcurrent',
  );
  @override
  late final GeneratedColumn<int> maxConcurrent = GeneratedColumn<int>(
    'max_concurrent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _storageLimitMbMeta = const VerificationMeta(
    'storageLimitMb',
  );
  @override
  late final GeneratedColumn<int> storageLimitMb = GeneratedColumn<int>(
    'storage_limit_mb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pauseOnLowBatteryMeta = const VerificationMeta(
    'pauseOnLowBattery',
  );
  @override
  late final GeneratedColumn<bool> pauseOnLowBattery = GeneratedColumn<bool>(
    'pause_on_low_battery',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pause_on_low_battery" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wifiOnly,
    maxConcurrent,
    storageLimitMb,
    pauseOnLowBattery,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wifi_only')) {
      context.handle(
        _wifiOnlyMeta,
        wifiOnly.isAcceptableOrUnknown(data['wifi_only']!, _wifiOnlyMeta),
      );
    }
    if (data.containsKey('max_concurrent')) {
      context.handle(
        _maxConcurrentMeta,
        maxConcurrent.isAcceptableOrUnknown(
          data['max_concurrent']!,
          _maxConcurrentMeta,
        ),
      );
    }
    if (data.containsKey('storage_limit_mb')) {
      context.handle(
        _storageLimitMbMeta,
        storageLimitMb.isAcceptableOrUnknown(
          data['storage_limit_mb']!,
          _storageLimitMbMeta,
        ),
      );
    }
    if (data.containsKey('pause_on_low_battery')) {
      context.handle(
        _pauseOnLowBatteryMeta,
        pauseOnLowBattery.isAcceptableOrUnknown(
          data['pause_on_low_battery']!,
          _pauseOnLowBatteryMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wifiOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wifi_only'],
      )!,
      maxConcurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_concurrent'],
      )!,
      storageLimitMb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}storage_limit_mb'],
      ),
      pauseOnLowBattery: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pause_on_low_battery'],
      )!,
    );
  }

  @override
  $DownloadSettingsTable createAlias(String alias) {
    return $DownloadSettingsTable(attachedDatabase, alias);
  }
}

class DownloadSetting extends DataClass implements Insertable<DownloadSetting> {
  final int id;
  final bool wifiOnly;
  final int maxConcurrent;
  final int? storageLimitMb;
  final bool pauseOnLowBattery;
  const DownloadSetting({
    required this.id,
    required this.wifiOnly,
    required this.maxConcurrent,
    this.storageLimitMb,
    required this.pauseOnLowBattery,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['wifi_only'] = Variable<bool>(wifiOnly);
    map['max_concurrent'] = Variable<int>(maxConcurrent);
    if (!nullToAbsent || storageLimitMb != null) {
      map['storage_limit_mb'] = Variable<int>(storageLimitMb);
    }
    map['pause_on_low_battery'] = Variable<bool>(pauseOnLowBattery);
    return map;
  }

  DownloadSettingsCompanion toCompanion(bool nullToAbsent) {
    return DownloadSettingsCompanion(
      id: Value(id),
      wifiOnly: Value(wifiOnly),
      maxConcurrent: Value(maxConcurrent),
      storageLimitMb: storageLimitMb == null && nullToAbsent
          ? const Value.absent()
          : Value(storageLimitMb),
      pauseOnLowBattery: Value(pauseOnLowBattery),
    );
  }

  factory DownloadSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadSetting(
      id: serializer.fromJson<int>(json['id']),
      wifiOnly: serializer.fromJson<bool>(json['wifiOnly']),
      maxConcurrent: serializer.fromJson<int>(json['maxConcurrent']),
      storageLimitMb: serializer.fromJson<int?>(json['storageLimitMb']),
      pauseOnLowBattery: serializer.fromJson<bool>(json['pauseOnLowBattery']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wifiOnly': serializer.toJson<bool>(wifiOnly),
      'maxConcurrent': serializer.toJson<int>(maxConcurrent),
      'storageLimitMb': serializer.toJson<int?>(storageLimitMb),
      'pauseOnLowBattery': serializer.toJson<bool>(pauseOnLowBattery),
    };
  }

  DownloadSetting copyWith({
    int? id,
    bool? wifiOnly,
    int? maxConcurrent,
    Value<int?> storageLimitMb = const Value.absent(),
    bool? pauseOnLowBattery,
  }) => DownloadSetting(
    id: id ?? this.id,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    maxConcurrent: maxConcurrent ?? this.maxConcurrent,
    storageLimitMb: storageLimitMb.present
        ? storageLimitMb.value
        : this.storageLimitMb,
    pauseOnLowBattery: pauseOnLowBattery ?? this.pauseOnLowBattery,
  );
  DownloadSetting copyWithCompanion(DownloadSettingsCompanion data) {
    return DownloadSetting(
      id: data.id.present ? data.id.value : this.id,
      wifiOnly: data.wifiOnly.present ? data.wifiOnly.value : this.wifiOnly,
      maxConcurrent: data.maxConcurrent.present
          ? data.maxConcurrent.value
          : this.maxConcurrent,
      storageLimitMb: data.storageLimitMb.present
          ? data.storageLimitMb.value
          : this.storageLimitMb,
      pauseOnLowBattery: data.pauseOnLowBattery.present
          ? data.pauseOnLowBattery.value
          : this.pauseOnLowBattery,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadSetting(')
          ..write('id: $id, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('maxConcurrent: $maxConcurrent, ')
          ..write('storageLimitMb: $storageLimitMb, ')
          ..write('pauseOnLowBattery: $pauseOnLowBattery')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wifiOnly,
    maxConcurrent,
    storageLimitMb,
    pauseOnLowBattery,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadSetting &&
          other.id == this.id &&
          other.wifiOnly == this.wifiOnly &&
          other.maxConcurrent == this.maxConcurrent &&
          other.storageLimitMb == this.storageLimitMb &&
          other.pauseOnLowBattery == this.pauseOnLowBattery);
}

class DownloadSettingsCompanion extends UpdateCompanion<DownloadSetting> {
  final Value<int> id;
  final Value<bool> wifiOnly;
  final Value<int> maxConcurrent;
  final Value<int?> storageLimitMb;
  final Value<bool> pauseOnLowBattery;
  const DownloadSettingsCompanion({
    this.id = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.maxConcurrent = const Value.absent(),
    this.storageLimitMb = const Value.absent(),
    this.pauseOnLowBattery = const Value.absent(),
  });
  DownloadSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.maxConcurrent = const Value.absent(),
    this.storageLimitMb = const Value.absent(),
    this.pauseOnLowBattery = const Value.absent(),
  });
  static Insertable<DownloadSetting> custom({
    Expression<int>? id,
    Expression<bool>? wifiOnly,
    Expression<int>? maxConcurrent,
    Expression<int>? storageLimitMb,
    Expression<bool>? pauseOnLowBattery,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wifiOnly != null) 'wifi_only': wifiOnly,
      if (maxConcurrent != null) 'max_concurrent': maxConcurrent,
      if (storageLimitMb != null) 'storage_limit_mb': storageLimitMb,
      if (pauseOnLowBattery != null) 'pause_on_low_battery': pauseOnLowBattery,
    });
  }

  DownloadSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? wifiOnly,
    Value<int>? maxConcurrent,
    Value<int?>? storageLimitMb,
    Value<bool>? pauseOnLowBattery,
  }) {
    return DownloadSettingsCompanion(
      id: id ?? this.id,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      storageLimitMb: storageLimitMb ?? this.storageLimitMb,
      pauseOnLowBattery: pauseOnLowBattery ?? this.pauseOnLowBattery,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wifiOnly.present) {
      map['wifi_only'] = Variable<bool>(wifiOnly.value);
    }
    if (maxConcurrent.present) {
      map['max_concurrent'] = Variable<int>(maxConcurrent.value);
    }
    if (storageLimitMb.present) {
      map['storage_limit_mb'] = Variable<int>(storageLimitMb.value);
    }
    if (pauseOnLowBattery.present) {
      map['pause_on_low_battery'] = Variable<bool>(pauseOnLowBattery.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadSettingsCompanion(')
          ..write('id: $id, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('maxConcurrent: $maxConcurrent, ')
          ..write('storageLimitMb: $storageLimitMb, ')
          ..write('pauseOnLowBattery: $pauseOnLowBattery')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DownloadedVideosTable downloadedVideos = $DownloadedVideosTable(
    this,
  );
  late final $DownloadSettingsTable downloadSettings = $DownloadSettingsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    downloadedVideos,
    downloadSettings,
  ];
}

typedef $$DownloadedVideosTableCreateCompanionBuilder =
    DownloadedVideosCompanion Function({
      required String videoId,
      required String title,
      required String channelName,
      required String youtubeUrl,
      Value<String?> description,
      Value<int?> durationSeconds,
      Value<String?> uploadDate,
      Value<String?> thumbnailUrl,
      required String localPath,
      required int fileSizeBytes,
      required DateTime downloadedAt,
      required String status,
      Value<double> progress,
      Value<String?> errorMessage,
      Value<String?> taskId,
      Value<int> rowid,
    });
typedef $$DownloadedVideosTableUpdateCompanionBuilder =
    DownloadedVideosCompanion Function({
      Value<String> videoId,
      Value<String> title,
      Value<String> channelName,
      Value<String> youtubeUrl,
      Value<String?> description,
      Value<int?> durationSeconds,
      Value<String?> uploadDate,
      Value<String?> thumbnailUrl,
      Value<String> localPath,
      Value<int> fileSizeBytes,
      Value<DateTime> downloadedAt,
      Value<String> status,
      Value<double> progress,
      Value<String?> errorMessage,
      Value<String?> taskId,
      Value<int> rowid,
    });

class $$DownloadedVideosTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedVideosTable> {
  $$DownloadedVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelName => $composableBuilder(
    column: $table.channelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadDate => $composableBuilder(
    column: $table.uploadDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedVideosTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedVideosTable> {
  $$DownloadedVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelName => $composableBuilder(
    column: $table.channelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadDate => $composableBuilder(
    column: $table.uploadDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedVideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedVideosTable> {
  $$DownloadedVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get channelName => $composableBuilder(
    column: $table.channelName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadDate => $composableBuilder(
    column: $table.uploadDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);
}

class $$DownloadedVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadedVideosTable,
          DownloadedVideo,
          $$DownloadedVideosTableFilterComposer,
          $$DownloadedVideosTableOrderingComposer,
          $$DownloadedVideosTableAnnotationComposer,
          $$DownloadedVideosTableCreateCompanionBuilder,
          $$DownloadedVideosTableUpdateCompanionBuilder,
          (
            DownloadedVideo,
            BaseReferences<
              _$AppDatabase,
              $DownloadedVideosTable,
              DownloadedVideo
            >,
          ),
          DownloadedVideo,
          PrefetchHooks Function()
        > {
  $$DownloadedVideosTableTableManager(
    _$AppDatabase db,
    $DownloadedVideosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> channelName = const Value.absent(),
                Value<String> youtubeUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> uploadDate = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedVideosCompanion(
                videoId: videoId,
                title: title,
                channelName: channelName,
                youtubeUrl: youtubeUrl,
                description: description,
                durationSeconds: durationSeconds,
                uploadDate: uploadDate,
                thumbnailUrl: thumbnailUrl,
                localPath: localPath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                status: status,
                progress: progress,
                errorMessage: errorMessage,
                taskId: taskId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required String title,
                required String channelName,
                required String youtubeUrl,
                Value<String?> description = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> uploadDate = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                required String localPath,
                required int fileSizeBytes,
                required DateTime downloadedAt,
                required String status,
                Value<double> progress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedVideosCompanion.insert(
                videoId: videoId,
                title: title,
                channelName: channelName,
                youtubeUrl: youtubeUrl,
                description: description,
                durationSeconds: durationSeconds,
                uploadDate: uploadDate,
                thumbnailUrl: thumbnailUrl,
                localPath: localPath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                status: status,
                progress: progress,
                errorMessage: errorMessage,
                taskId: taskId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedVideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadedVideosTable,
      DownloadedVideo,
      $$DownloadedVideosTableFilterComposer,
      $$DownloadedVideosTableOrderingComposer,
      $$DownloadedVideosTableAnnotationComposer,
      $$DownloadedVideosTableCreateCompanionBuilder,
      $$DownloadedVideosTableUpdateCompanionBuilder,
      (
        DownloadedVideo,
        BaseReferences<_$AppDatabase, $DownloadedVideosTable, DownloadedVideo>,
      ),
      DownloadedVideo,
      PrefetchHooks Function()
    >;
typedef $$DownloadSettingsTableCreateCompanionBuilder =
    DownloadSettingsCompanion Function({
      Value<int> id,
      Value<bool> wifiOnly,
      Value<int> maxConcurrent,
      Value<int?> storageLimitMb,
      Value<bool> pauseOnLowBattery,
    });
typedef $$DownloadSettingsTableUpdateCompanionBuilder =
    DownloadSettingsCompanion Function({
      Value<int> id,
      Value<bool> wifiOnly,
      Value<int> maxConcurrent,
      Value<int?> storageLimitMb,
      Value<bool> pauseOnLowBattery,
    });

class $$DownloadSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadSettingsTable> {
  $$DownloadSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wifiOnly => $composableBuilder(
    column: $table.wifiOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxConcurrent => $composableBuilder(
    column: $table.maxConcurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storageLimitMb => $composableBuilder(
    column: $table.storageLimitMb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pauseOnLowBattery => $composableBuilder(
    column: $table.pauseOnLowBattery,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadSettingsTable> {
  $$DownloadSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wifiOnly => $composableBuilder(
    column: $table.wifiOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxConcurrent => $composableBuilder(
    column: $table.maxConcurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storageLimitMb => $composableBuilder(
    column: $table.storageLimitMb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pauseOnLowBattery => $composableBuilder(
    column: $table.pauseOnLowBattery,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadSettingsTable> {
  $$DownloadSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get wifiOnly =>
      $composableBuilder(column: $table.wifiOnly, builder: (column) => column);

  GeneratedColumn<int> get maxConcurrent => $composableBuilder(
    column: $table.maxConcurrent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get storageLimitMb => $composableBuilder(
    column: $table.storageLimitMb,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pauseOnLowBattery => $composableBuilder(
    column: $table.pauseOnLowBattery,
    builder: (column) => column,
  );
}

class $$DownloadSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadSettingsTable,
          DownloadSetting,
          $$DownloadSettingsTableFilterComposer,
          $$DownloadSettingsTableOrderingComposer,
          $$DownloadSettingsTableAnnotationComposer,
          $$DownloadSettingsTableCreateCompanionBuilder,
          $$DownloadSettingsTableUpdateCompanionBuilder,
          (
            DownloadSetting,
            BaseReferences<
              _$AppDatabase,
              $DownloadSettingsTable,
              DownloadSetting
            >,
          ),
          DownloadSetting,
          PrefetchHooks Function()
        > {
  $$DownloadSettingsTableTableManager(
    _$AppDatabase db,
    $DownloadSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> wifiOnly = const Value.absent(),
                Value<int> maxConcurrent = const Value.absent(),
                Value<int?> storageLimitMb = const Value.absent(),
                Value<bool> pauseOnLowBattery = const Value.absent(),
              }) => DownloadSettingsCompanion(
                id: id,
                wifiOnly: wifiOnly,
                maxConcurrent: maxConcurrent,
                storageLimitMb: storageLimitMb,
                pauseOnLowBattery: pauseOnLowBattery,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> wifiOnly = const Value.absent(),
                Value<int> maxConcurrent = const Value.absent(),
                Value<int?> storageLimitMb = const Value.absent(),
                Value<bool> pauseOnLowBattery = const Value.absent(),
              }) => DownloadSettingsCompanion.insert(
                id: id,
                wifiOnly: wifiOnly,
                maxConcurrent: maxConcurrent,
                storageLimitMb: storageLimitMb,
                pauseOnLowBattery: pauseOnLowBattery,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadSettingsTable,
      DownloadSetting,
      $$DownloadSettingsTableFilterComposer,
      $$DownloadSettingsTableOrderingComposer,
      $$DownloadSettingsTableAnnotationComposer,
      $$DownloadSettingsTableCreateCompanionBuilder,
      $$DownloadSettingsTableUpdateCompanionBuilder,
      (
        DownloadSetting,
        BaseReferences<_$AppDatabase, $DownloadSettingsTable, DownloadSetting>,
      ),
      DownloadSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DownloadedVideosTableTableManager get downloadedVideos =>
      $$DownloadedVideosTableTableManager(_db, _db.downloadedVideos);
  $$DownloadSettingsTableTableManager get downloadSettings =>
      $$DownloadSettingsTableTableManager(_db, _db.downloadSettings);
}
