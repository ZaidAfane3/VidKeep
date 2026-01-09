import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/config/app_config.dart';

/// Download progress data from WebSocket
class DownloadProgress {
  final String videoId;
  final int percent;
  final int? downloadedBytes;
  final int? totalBytes;

  DownloadProgress({
    required this.videoId,
    required this.percent,
    this.downloadedBytes,
    this.totalBytes,
  });

  factory DownloadProgress.fromJson(Map<String, dynamic> json) {
    return DownloadProgress(
      videoId: json['video_id'],
      percent: json['percent'] ?? 0,
      downloadedBytes: json['downloaded_bytes'],
      totalBytes: json['total_bytes'],
    );
  }
}

/// WebSocket client for real-time download progress updates
class WebSocketClient {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _wsUrl;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  
  final _progressController = StreamController<DownloadProgress>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  /// Stream of download progress updates
  Stream<DownloadProgress> get progressStream => _progressController.stream;
  
  /// Stream of connection status changes
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// Current connection status
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  void connect(String wsUrl) {
    _wsUrl = wsUrl;
    _shouldReconnect = true;
    _doConnect();
  }

  void _doConnect() {
    if (_wsUrl == null) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl!));
      _isConnected = true;
      _connectionController.add(true);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Start keepalive ping every 30 seconds
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(
        Duration(seconds: AppConfig.wsPingIntervalSec),
        (_) => _sendPing(),
      );
    } catch (e) {
      debugPrint('[WS] Connection error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    if (message == 'pong') return;

    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'progress') {
        _progressController.add(DownloadProgress.fromJson(data));
      } else if (data['type'] == 'status') {
        // Status update - video state changed
        _progressController.add(DownloadProgress(
          videoId: data['video_id'],
          percent: data['percent'] ?? 0,
        ));
      }
    } catch (e) {
      debugPrint('[WS] Error parsing message: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _handleDisconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: AppConfig.wsReconnectDelaySec),
      _doConnect,
    );
  }

  void _sendPing() {
    try {
      _channel?.sink.add('ping');
    } catch (e) {
      debugPrint('[WS] Ping error: $e');
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _shouldReconnect = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _progressController.close();
    _connectionController.close();
  }
}
